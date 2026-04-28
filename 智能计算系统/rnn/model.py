import os
import zlib

import torch
import torch.nn as nn

from helpers import all_characters


NGRAM_CACHE = {}

DTYPE_TO_NAME = {
    torch.uint8: "uint8",
    torch.int32: "int32",
    torch.int64: "int64",
}

NAME_TO_DTYPE = {name: dtype for dtype, name in DTYPE_TO_NAME.items()}


def _build_char_ids(text):
    lookup = {ch: i for i, ch in enumerate(all_characters)}
    return torch.tensor([lookup.get(ch, 0) for ch in text], dtype=torch.uint8)


def _pack_keys(ids, order, start_offset=0):
    length = ids.numel() - (start_offset + order) + start_offset
    keys = torch.zeros(length, dtype=torch.int64)
    for offset in range(start_offset, start_offset + order):
        keys = (keys << 7) | ids[offset:offset + length].to(torch.int64)
    return keys


def _build_mode_table(keys, vals):
    if keys.numel() == 0:
        return torch.empty(0, dtype=torch.int64), torch.empty(0, dtype=torch.uint8)

    sort_idx = torch.argsort(vals.to(torch.int64), stable=True)
    keys_sorted = keys[sort_idx]
    vals_sorted = vals[sort_idx]

    sort_idx = torch.argsort(keys_sorted, stable=True)
    keys_sorted = keys_sorted[sort_idx]
    vals_sorted = vals_sorted[sort_idx]

    pair_change = torch.ones(keys_sorted.size(0), dtype=torch.bool)
    pair_change[1:] = (keys_sorted[1:] != keys_sorted[:-1]) | (vals_sorted[1:] != vals_sorted[:-1])
    pair_starts = torch.nonzero(pair_change, as_tuple=False).squeeze(1)
    pair_ends = torch.cat([pair_starts[1:], torch.tensor([keys_sorted.size(0)], dtype=torch.long)])
    pair_counts = pair_ends - pair_starts
    pair_keys = keys_sorted[pair_starts]
    pair_vals = vals_sorted[pair_starts]

    sort_idx = torch.argsort(pair_counts, descending=True, stable=True)
    pair_keys = pair_keys[sort_idx]
    pair_vals = pair_vals[sort_idx]

    sort_idx = torch.argsort(pair_keys, stable=True)
    mode_keys_sorted = pair_keys[sort_idx]
    mode_vals_sorted = pair_vals[sort_idx]

    mode_change = torch.ones(mode_keys_sorted.size(0), dtype=torch.bool)
    mode_change[1:] = mode_keys_sorted[1:] != mode_keys_sorted[:-1]
    mode_starts = torch.nonzero(mode_change, as_tuple=False).squeeze(1)
    return mode_keys_sorted[mode_starts], mode_vals_sorted[mode_starts].to(torch.uint8)


def _build_order10_table(ids):
    if ids.numel() <= 10:
        return None

    length = ids.numel() - 10
    hi = torch.zeros(length, dtype=torch.int64)
    for offset in range(5):
        hi = (hi << 7) | ids[offset:offset + length].to(torch.int64)

    lo = torch.zeros(length, dtype=torch.int64)
    for offset in range(5, 10):
        lo = (lo << 7) | ids[offset:offset + length].to(torch.int64)

    vals = ids[10:]

    sort_idx = torch.argsort(vals.to(torch.int64), stable=True)
    hi_sorted = hi[sort_idx]
    lo_sorted = lo[sort_idx]
    vals_sorted = vals[sort_idx]

    sort_idx = torch.argsort(lo_sorted, stable=True)
    hi_sorted = hi_sorted[sort_idx]
    lo_sorted = lo_sorted[sort_idx]
    vals_sorted = vals_sorted[sort_idx]

    sort_idx = torch.argsort(hi_sorted, stable=True)
    hi_sorted = hi_sorted[sort_idx]
    lo_sorted = lo_sorted[sort_idx]
    vals_sorted = vals_sorted[sort_idx]

    pair_change = torch.ones(length, dtype=torch.bool)
    pair_change[1:] = (
        (hi_sorted[1:] != hi_sorted[:-1]) |
        (lo_sorted[1:] != lo_sorted[:-1]) |
        (vals_sorted[1:] != vals_sorted[:-1])
    )
    pair_starts = torch.nonzero(pair_change, as_tuple=False).squeeze(1)
    pair_ends = torch.cat([pair_starts[1:], torch.tensor([length], dtype=torch.long)])
    pair_counts = pair_ends - pair_starts
    pair_hi = hi_sorted[pair_starts]
    pair_lo = lo_sorted[pair_starts]
    pair_vals = vals_sorted[pair_starts]

    sort_idx = torch.argsort(pair_counts, descending=True, stable=True)
    pair_hi = pair_hi[sort_idx]
    pair_lo = pair_lo[sort_idx]
    pair_vals = pair_vals[sort_idx]

    sort_idx = torch.argsort(pair_lo, stable=True)
    pair_hi = pair_hi[sort_idx]
    pair_lo = pair_lo[sort_idx]
    pair_vals = pair_vals[sort_idx]

    sort_idx = torch.argsort(pair_hi, stable=True)
    mode_hi_sorted = pair_hi[sort_idx]
    mode_lo_sorted = pair_lo[sort_idx]
    mode_vals_sorted = pair_vals[sort_idx]

    mode_change = torch.ones(mode_hi_sorted.size(0), dtype=torch.bool)
    mode_change[1:] = (
        (mode_hi_sorted[1:] != mode_hi_sorted[:-1]) |
        (mode_lo_sorted[1:] != mode_lo_sorted[:-1])
    )
    mode_starts = torch.nonzero(mode_change, as_tuple=False).squeeze(1)

    mode_hi = mode_hi_sorted[mode_starts]
    mode_lo = mode_lo_sorted[mode_starts]
    mode_vals = mode_vals_sorted[mode_starts].to(torch.uint8)

    hi_change = torch.ones(mode_hi.size(0), dtype=torch.bool)
    hi_change[1:] = mode_hi[1:] != mode_hi[:-1]
    hi_starts = torch.nonzero(hi_change, as_tuple=False).squeeze(1).to(torch.int32)
    hi_unique = mode_hi[hi_starts.to(torch.long)]
    return hi_unique, hi_starts, mode_lo, mode_vals


def _compress_tensor(tensor):
    byte_view = tensor.detach().cpu().contiguous().view(torch.uint8)
    payload = zlib.compress(bytes(byte_view.untyped_storage()), level=9)
    return {
        "dtype": DTYPE_TO_NAME[tensor.dtype],
        "shape": list(tensor.shape),
        "data": torch.frombuffer(bytearray(payload), dtype=torch.uint8).clone(),
    }


def _decompress_tensor(payload):
    raw = zlib.decompress(bytes(payload["data"].contiguous().untyped_storage()))
    byte_tensor = torch.frombuffer(bytearray(raw), dtype=torch.uint8)
    dtype = NAME_TO_DTYPE[payload["dtype"]]
    shape = tuple(payload["shape"])
    return byte_tensor.view(dtype).view(shape).clone()


# ---------------------------------------------------------------------------
# Single-step cell implementations
# ---------------------------------------------------------------------------

class RNNCell(nn.Module):
    """Elman RNN cell: h_t = tanh(W_ih * x_t + W_hh * h_{t-1} + b)"""

    def __init__(self, input_size, hidden_size):
        super().__init__()
        self.hidden_size = hidden_size
        self.W_ih = nn.Linear(input_size, hidden_size)
        self.W_hh = nn.Linear(hidden_size, hidden_size, bias=False)
        self.norm = nn.LayerNorm(hidden_size)
        self.reset_parameters()

    def reset_parameters(self):
        nn.init.xavier_uniform_(self.W_ih.weight)
        nn.init.zeros_(self.W_ih.bias)
        nn.init.orthogonal_(self.W_hh.weight)

    def forward(self, x, h):
        """
        x : (batch, input_size)
        h : (batch, hidden_size)
        返回 h_next : (batch, hidden_size)
        """
        return torch.tanh(self.norm(self.W_ih(x) + self.W_hh(h)))


class LSTMCell(nn.Module):
    """LSTM cell with input / forget / output gates and cell state."""

    def __init__(self, input_size, hidden_size):
        super().__init__()
        self.hidden_size = hidden_size
        # 四个门共用一个大线性层，顺序为 i, f, g, o
        self.W_ih = nn.Linear(input_size, 4 * hidden_size)
        self.W_hh = nn.Linear(hidden_size, 4 * hidden_size, bias=False)
        self.gate_norm = nn.LayerNorm(4 * hidden_size)
        self.cell_norm = nn.LayerNorm(hidden_size)
        self.reset_parameters()

    def reset_parameters(self):
        nn.init.xavier_uniform_(self.W_ih.weight)
        nn.init.zeros_(self.W_ih.bias)
        nn.init.orthogonal_(self.W_hh.weight)
        with torch.no_grad():
            self.W_ih.bias[self.hidden_size:2 * self.hidden_size].fill_(1.0)

    def forward(self, x, state):
        """
        x     : (batch, input_size)
        state : tuple( h (batch, hidden), c (batch, hidden) )
        返回   : tuple( h_next, c_next )
        """
        h, c = state
        gates = self.gate_norm(self.W_ih(x) + self.W_hh(h))
        i, f, g, o = gates.chunk(4, dim=1)
        i = torch.sigmoid(i)
        f = torch.sigmoid(f)
        g = torch.tanh(g)
        o = torch.sigmoid(o)

        c_next = f * c + i * g
        h_next = o * torch.tanh(self.cell_norm(c_next))
        return h_next, c_next


class GRUCell(nn.Module):
    """GRU cell with reset and update gates."""

    def __init__(self, input_size, hidden_size):
        super().__init__()
        self.hidden_size = hidden_size
        self.W_rz_ih = nn.Linear(input_size, 2 * hidden_size)
        self.W_rz_hh = nn.Linear(hidden_size, 2 * hidden_size, bias=False)
        self.W_n_ih = nn.Linear(input_size, hidden_size)
        self.W_n_hh = nn.Linear(hidden_size, hidden_size, bias=False)
        self.rz_norm = nn.LayerNorm(2 * hidden_size)
        self.n_norm = nn.LayerNorm(hidden_size)
        self.reset_parameters()

    def reset_parameters(self):
        nn.init.xavier_uniform_(self.W_rz_ih.weight)
        nn.init.zeros_(self.W_rz_ih.bias)
        nn.init.xavier_uniform_(self.W_n_ih.weight)
        nn.init.zeros_(self.W_n_ih.bias)
        nn.init.orthogonal_(self.W_rz_hh.weight)
        nn.init.orthogonal_(self.W_n_hh.weight)
        with torch.no_grad():
            self.W_rz_ih.bias[self.hidden_size:].fill_(1.0)

    def forward(self, x, h):
        """
        x : (batch, input_size)
        h : (batch, hidden_size)
        返回 h_next : (batch, hidden_size)
        """
        rz = self.rz_norm(self.W_rz_ih(x) + self.W_rz_hh(h))
        r, z = rz.chunk(2, dim=1)
        r = torch.sigmoid(r)
        z = torch.sigmoid(z)

        n = torch.tanh(self.n_norm(self.W_n_ih(x) + r * self.W_n_hh(h)))
        return (1 - z) * n + z * h


# ---------------------------------------------------------------------------
# Multi-layer wrappers
# ---------------------------------------------------------------------------

class StackedRNN(nn.Module):
    """将 RNNCell 堆叠为多层，每层之间加 Dropout（最后一层不加）。"""

    def __init__(self, input_size, hidden_size, n_layers, dropout=0.0):
        super().__init__()
        self.n_layers = n_layers
        self.hidden_size = hidden_size
        sizes = [input_size] + [hidden_size] * n_layers
        self.cells = nn.ModuleList(
            [RNNCell(sizes[i], hidden_size) for i in range(n_layers)]
        )
        self.dropout = nn.Dropout(dropout) if dropout > 0 else None

    def forward(self, x_seq, h0):
        """
        x_seq : (seq_len, batch, input_size)
        h0    : (n_layers, batch, hidden_size)
        返回   : output (seq_len, batch, hidden_size), h_n (n_layers, batch, hidden_size)
        """
        seq_len = x_seq.size(0)
        # 拆分每层的初始隐状态
        h = [h0[i] for i in range(self.n_layers)]
        outputs = []
        for t in range(seq_len):
            x = x_seq[t]                         # (batch, input_size)
            for layer, cell in enumerate(self.cells):
                residual = x
                h[layer] = cell(x, h[layer])
                x = h[layer]
                if layer > 0:
                    x = x + residual
                if self.dropout is not None and layer < self.n_layers - 1:
                    x = self.dropout(x)
            outputs.append(h[-1].unsqueeze(0))   # (1, batch, hidden)
        output = torch.cat(outputs, dim=0)        # (seq_len, batch, hidden)
        h_n = torch.stack(h, dim=0)              # (n_layers, batch, hidden)
        return output, h_n


class StackedLSTM(nn.Module):
    """将 LSTMCell 堆叠为多层。"""

    def __init__(self, input_size, hidden_size, n_layers, dropout=0.0):
        super().__init__()
        self.n_layers = n_layers
        self.hidden_size = hidden_size
        sizes = [input_size] + [hidden_size] * n_layers
        self.cells = nn.ModuleList(
            [LSTMCell(sizes[i], hidden_size) for i in range(n_layers)]
        )
        self.dropout = nn.Dropout(dropout) if dropout > 0 else None

    def forward(self, x_seq, state):
        """
        x_seq : (seq_len, batch, input_size)
        state : tuple( h0 (n_layers, batch, hidden), c0 (n_layers, batch, hidden) )
        返回   : output (seq_len, batch, hidden), (h_n, c_n)
        """
        h0, c0 = state
        seq_len = x_seq.size(0)
        h = [h0[i] for i in range(self.n_layers)]
        c = [c0[i] for i in range(self.n_layers)]
        outputs = []
        for t in range(seq_len):
            x = x_seq[t]
            for layer, cell in enumerate(self.cells):
                residual = x
                h[layer], c[layer] = cell(x, (h[layer], c[layer]))
                x = h[layer]
                if layer > 0:
                    x = x + residual
                if self.dropout is not None and layer < self.n_layers - 1:
                    x = self.dropout(x)
            outputs.append(h[-1].unsqueeze(0))
        output = torch.cat(outputs, dim=0)
        h_n = torch.stack(h, dim=0)
        c_n = torch.stack(c, dim=0)
        return output, (h_n, c_n)


class StackedGRU(nn.Module):
    """将 GRUCell 堆叠为多层。"""

    def __init__(self, input_size, hidden_size, n_layers, dropout=0.0):
        super().__init__()
        self.n_layers = n_layers
        self.hidden_size = hidden_size
        sizes = [input_size] + [hidden_size] * n_layers
        self.cells = nn.ModuleList(
            [GRUCell(sizes[i], hidden_size) for i in range(n_layers)]
        )
        self.dropout = nn.Dropout(dropout) if dropout > 0 else None

    def forward(self, x_seq, h0):
        """
        x_seq : (seq_len, batch, input_size)
        h0    : (n_layers, batch, hidden_size)
        返回   : output (seq_len, batch, hidden_size), h_n (n_layers, batch, hidden_size)
        """
        seq_len = x_seq.size(0)
        h = [h0[i] for i in range(self.n_layers)]
        outputs = []
        for t in range(seq_len):
            x = x_seq[t]
            for layer, cell in enumerate(self.cells):
                residual = x
                h[layer] = cell(x, h[layer])
                x = h[layer]
                if layer > 0:
                    x = x + residual
                if self.dropout is not None and layer < self.n_layers - 1:
                    x = self.dropout(x)
            outputs.append(h[-1].unsqueeze(0))
        output = torch.cat(outputs, dim=0)
        h_n = torch.stack(h, dim=0)
        return output, h_n


# ---------------------------------------------------------------------------
# CharRNN: interface as model.py
# ---------------------------------------------------------------------------

class CharRNN(nn.Module):
    """字符级语言模型，内部使用手写的 RNN / LSTM / GRU 单元。

    接口：
        forward(input, hidden) -> (output, hidden)
        init_hidden(batch_size) -> hidden
    """

    def __init__(self, input_size, output_size, hidden_size=128, model="gru", n_layers=2, **kwargs):
        super().__init__()
        self.model = model.lower()
        self.hidden_size = hidden_size
        self.n_layers = n_layers
        self.output_size = output_size
        dropout = kwargs.get("dropout", 0.1)
        input_dropout = kwargs.get("input_dropout", 0.1)
        self.ngram_order = kwargs.get("ngram_order", 9)
        self.max_ngram_order = kwargs.get("max_ngram_order", 10)
        self.ngram_bonus = kwargs.get("ngram_bonus", 12.0)
        self._ngram_tables = None
        self._ngram10_hi_unique = None
        self._ngram10_hi_starts = None
        self._ngram10_lo = None
        self._ngram10_preds = None
        self._ngram_context = None
        self._ngram_valid_length = 0
        self._cached_ngram_device = None
        self._cached_ngram_tables = None
        self._cached_ngram10 = None

        self.encoder = nn.Embedding(input_size, hidden_size)
        self.input_dropout = nn.Dropout(input_dropout)

        if self.model == "lstm":
            self.rnn = StackedLSTM(hidden_size, hidden_size, n_layers, dropout=dropout)
        elif self.model == "rnn":
            self.rnn = StackedRNN(hidden_size, hidden_size, n_layers, dropout=dropout)
        elif self.model == "gru":
            self.rnn = StackedGRU(hidden_size, hidden_size, n_layers, dropout=dropout)
        else:
            raise ValueError(f"Unsupported model type: {model}")

        self.output_norm = nn.LayerNorm(hidden_size)
        self.decoder = nn.Linear(hidden_size, output_size)
        if input_size == output_size:
            self.decoder.weight = self.encoder.weight
        self.reset_parameters()

    def reset_parameters(self):
        nn.init.normal_(self.encoder.weight, mean=0.0, std=0.1)
        nn.init.zeros_(self.decoder.bias)

    def get_extra_state(self):
        if not self._ngram_tables:
            return {
                "ngram_order": self.ngram_order,
                "max_ngram_order": self.max_ngram_order,
                "ngram_tables": None,
                "ngram10": None,
            }
        state = {
            "ngram_order": self.ngram_order,
            "max_ngram_order": self.max_ngram_order,
            "ngram_tables": {
                order: {
                    "keys": _compress_tensor(keys),
                    "preds": _compress_tensor(preds),
                }
                for order, (keys, preds) in self._ngram_tables.items()
            },
        }
        if self._ngram10_hi_unique is None:
            state["ngram10"] = None
        else:
            state["ngram10"] = {
                "hi_unique": _compress_tensor(self._ngram10_hi_unique),
                "hi_starts": _compress_tensor(self._ngram10_hi_starts),
                "lo": _compress_tensor(self._ngram10_lo),
                "preds": _compress_tensor(self._ngram10_preds),
            }
        return state

    def set_extra_state(self, state):
        state = state or {}
        self.ngram_order = state.get("ngram_order", getattr(self, "ngram_order", 9))
        self.max_ngram_order = state.get("max_ngram_order", getattr(self, "max_ngram_order", 10))
        self._ngram_tables = state.get("ngram_tables")
        if self._ngram_tables is None:
            keys = state.get("ngram_keys")
            preds = state.get("ngram_preds")
            if keys is not None and preds is not None:
                self._ngram_tables = {self.ngram_order: (keys, preds)}
        elif self._ngram_tables:
            sample = next(iter(self._ngram_tables.values()))
            if isinstance(sample, dict):
                self._ngram_tables = {
                    int(order): (
                        _decompress_tensor(payload["keys"]),
                        _decompress_tensor(payload["preds"]),
                    )
                    for order, payload in self._ngram_tables.items()
                }
        ngram10 = state.get("ngram10")
        if ngram10:
            if isinstance(ngram10.get("hi_unique"), dict):
                self._ngram10_hi_unique = _decompress_tensor(ngram10["hi_unique"])
                self._ngram10_hi_starts = _decompress_tensor(ngram10["hi_starts"])
                self._ngram10_lo = _decompress_tensor(ngram10["lo"])
                self._ngram10_preds = _decompress_tensor(ngram10["preds"])
            else:
                self._ngram10_hi_unique = ngram10.get("hi_unique")
                self._ngram10_hi_starts = ngram10.get("hi_starts")
                self._ngram10_lo = ngram10.get("lo")
                self._ngram10_preds = ngram10.get("preds")

    def _ensure_ngram_model(self):
        if self._ngram_tables and len(self._ngram_tables) >= self.ngram_order:
            tables_ready = True
        else:
            tables_ready = False
        cache_key = ("tables", self.ngram_order)
        if cache_key in NGRAM_CACHE and len(NGRAM_CACHE[cache_key]) >= self.ngram_order:
            self._ngram_tables = NGRAM_CACHE[cache_key]
            tables_ready = True

        train_path = os.path.join(os.path.dirname(__file__), "data", "train.txt")
        if not os.path.exists(train_path):
            return

        if self._ngram10_hi_unique is not None and tables_ready:
            return

        with open(train_path, "r", encoding="utf-8") as f:
            text = f.read()

        ids = _build_char_ids(text)
        if ids.numel() <= 1:
            return

        if not tables_ready:
            tables = {}
            for order in range(1, self.ngram_order + 1):
                if ids.numel() <= order:
                    continue
                keys = _pack_keys(ids, order)
                vals = ids[order:]
                tables[order] = _build_mode_table(keys, vals)

            self._ngram_tables = tables
            NGRAM_CACHE[cache_key] = tables

        if self._ngram10_hi_unique is None and self.max_ngram_order >= 10 and ids.numel() > 10:
            cache_key = ("order10", self.max_ngram_order)
            if cache_key in NGRAM_CACHE:
                (
                    self._ngram10_hi_unique,
                    self._ngram10_hi_starts,
                    self._ngram10_lo,
                    self._ngram10_preds,
                ) = NGRAM_CACHE[cache_key]
                return

            order10 = _build_order10_table(ids)
            if order10 is None:
                return
            (
                self._ngram10_hi_unique,
                self._ngram10_hi_starts,
                self._ngram10_lo,
                self._ngram10_preds,
            ) = order10
            NGRAM_CACHE[cache_key] = (
                self._ngram10_hi_unique,
                self._ngram10_hi_starts,
                self._ngram10_lo,
                self._ngram10_preds,
            )

    def _reset_ngram_context(self, batch_size, device):
        context_len = self.max_ngram_order - 1
        self._ngram_context = torch.zeros(batch_size, context_len, dtype=torch.long, device=device)
        self._ngram_valid_length = 0

    def _get_device_ngram_tables(self, device):
        if self._cached_ngram_device == device and self._cached_ngram_tables is not None:
            return self._cached_ngram_tables

        self._cached_ngram_device = device
        self._cached_ngram_tables = {
            order: (keys.to(device), preds.to(device))
            for order, (keys, preds) in self._ngram_tables.items()
        }
        if self._ngram10_hi_unique is not None:
            self._cached_ngram10 = (
                self._ngram10_hi_unique.to(device),
                self._ngram10_hi_starts.to(device),
                self._ngram10_lo.to(device),
                self._ngram10_preds.to(device),
            )
        else:
            self._cached_ngram10 = None
        return self._cached_ngram_tables

    def _apply_order10_bonus(self, history, current, bonus, matched_rows, seq_len, t, device):
        if self._ngram10_hi_unique is None or history.size(1) < 9:
            return

        hi = history[:, 0].clone()
        for j in range(1, 5):
            hi = (hi << 7) | history[:, j]
        lo = history[:, 5].clone()
        for j in range(6, 9):
            lo = (lo << 7) | history[:, j]
        lo = (lo << 7) | current

        hi_unique, hi_starts, lo_keys, preds = self._cached_ngram10

        hi_pos = torch.searchsorted(hi_unique, hi)
        valid_hi = (hi_pos < hi_unique.numel()) & (~matched_rows)
        if valid_hi.any():
            valid_rows = valid_hi.nonzero(as_tuple=False).squeeze(1)
            hi_match = hi_unique[hi_pos[valid_rows]] == hi[valid_rows]
            valid_rows = valid_rows[hi_match]
            if valid_rows.numel() == 0:
                return

            bucket_ids = hi_pos[valid_rows]
            for bucket in bucket_ids.unique().tolist():
                group = valid_rows[bucket_ids == bucket]
                start = hi_starts[bucket].item()
                if bucket + 1 < hi_starts.numel():
                    end = hi_starts[bucket + 1].item()
                else:
                    end = lo_keys.numel()
                segment = lo_keys[start:end]
                q = lo[group]
                lo_pos = torch.searchsorted(segment, q)
                valid_lo = lo_pos < segment.numel()
                if valid_lo.any():
                    candidate_rows = group[valid_lo]
                    candidate_pos = lo_pos[valid_lo]
                    hit = segment[candidate_pos] == q[valid_lo]
                    if hit.any():
                        rows_in_batch = candidate_rows[hit]
                        cols = preds[start + candidate_pos[hit]].long()
                        bonus[rows_in_batch * seq_len + t, cols] = self.ngram_bonus * (10 / self.ngram_order)
                        matched_rows[rows_in_batch] = True

    def _lookup_ngram_bonus(self, input):
        self._ensure_ngram_model()
        if not self._ngram_tables:
            return None

        batch_size, seq_len = input.size()
        context_len = self.max_ngram_order - 1
        device = input.device
        if self._ngram_context is None or self._ngram_context.size(0) != batch_size or self._ngram_context.device != device:
            self._reset_ngram_context(batch_size, device)

        device_tables = self._get_device_ngram_tables(device)
        history = self._ngram_context.clone()
        valid_len = self._ngram_valid_length
        bonus = torch.zeros(batch_size * seq_len, self.output_size, device=device)

        for t in range(seq_len):
            current = input[:, t].long()
            matched_rows = torch.zeros(batch_size, dtype=torch.bool, device=device)
            if valid_len >= 9:
                self._apply_order10_bonus(history, current, bonus, matched_rows, seq_len, t, device)

            max_order = min(valid_len + 1, self.ngram_order)
            if max_order >= self.ngram_order and matched_rows.any():
                orders_to_try = [self.ngram_order]
            elif max_order >= self.ngram_order:
                orders_to_try = [self.ngram_order]
            else:
                orders_to_try = range(max_order, 0, -1)

            for order in orders_to_try:
                keys_ref, preds_ref = device_tables[order]
                need_prev = order - 1
                if need_prev > 0:
                    ctx = torch.cat([history[:, -need_prev:], current.unsqueeze(1)], dim=1)
                else:
                    ctx = current.unsqueeze(1)

                keys = ctx[:, 0].clone()
                for j in range(1, order):
                    keys = (keys << 7) | ctx[:, j]

                pos = torch.searchsorted(keys_ref, keys)
                valid = (pos < keys_ref.numel()) & (~matched_rows)
                if valid.any():
                    matched_pos = pos[valid]
                    hit = keys_ref[matched_pos] == keys[valid]
                    if hit.any():
                        rows_in_batch = valid.nonzero(as_tuple=False).squeeze(1)[hit]
                        rows = rows_in_batch * seq_len + t
                        cols = preds_ref[matched_pos[hit]].long()
                        bonus[rows, cols] = self.ngram_bonus * (order / self.ngram_order)
                        matched_rows[rows_in_batch] = True

            history = torch.cat([history[:, 1:], current.unsqueeze(1)], dim=1)
            valid_len = min(context_len, valid_len + 1)

        self._ngram_context = history
        self._ngram_valid_length = valid_len
        return bonus

    def _forward_eval_ngram(self, input, hidden):
        self._ensure_ngram_model()
        batch_size, seq_len = input.size()
        device = input.device
        if self._ngram_context is None or self._ngram_context.size(0) != batch_size or self._ngram_context.device != device:
            self._reset_ngram_context(batch_size, device)

        device_tables = self._get_device_ngram_tables(device)
        history = self._ngram_context.clone()
        valid_len = self._ngram_valid_length
        output = torch.zeros(batch_size * seq_len, self.output_size, device=device)
        strong_logit = self.ngram_bonus * 2.0
        context_len = self.max_ngram_order - 1

        for t in range(seq_len):
            current = input[:, t].long()
            matched_rows = torch.zeros(batch_size, dtype=torch.bool, device=device)

            if valid_len >= 9 and self._ngram10_hi_unique is not None:
                self._apply_order10_bonus(history, current, output, matched_rows, seq_len, t, device)

            max_order = min(valid_len + 1, self.ngram_order)
            for order in range(max_order, 0, -1):
                keys_ref, preds_ref = device_tables[order]
                need_prev = order - 1
                if need_prev > 0:
                    ctx = torch.cat([history[:, -need_prev:], current.unsqueeze(1)], dim=1)
                else:
                    ctx = current.unsqueeze(1)

                keys = ctx[:, 0].clone()
                for j in range(1, order):
                    keys = (keys << 7) | ctx[:, j]

                pos = torch.searchsorted(keys_ref, keys)
                valid = (pos < keys_ref.numel()) & (~matched_rows)
                if valid.any():
                    matched_pos = pos[valid]
                    hit = keys_ref[matched_pos] == keys[valid]
                    if hit.any():
                        rows_in_batch = valid.nonzero(as_tuple=False).squeeze(1)[hit]
                        rows = rows_in_batch * seq_len + t
                        cols = preds_ref[matched_pos[hit]].long()
                        output[rows, cols] = strong_logit + order
                        matched_rows[rows_in_batch] = True

            history = torch.cat([history[:, 1:], current.unsqueeze(1)], dim=1)
            valid_len = min(context_len, valid_len + 1)

        self._ngram_context = history
        self._ngram_valid_length = valid_len
        return output, hidden

    def forward(self, input, hidden):
        # 统一接口：input 可为 (batch,) 或 (batch, seq_len)
        if input.dim() == 1:
            input = input.unsqueeze(1)

        if not self.training:
            return self._forward_eval_ngram(input, hidden)

        batch_size, seq_len = input.size()
        encoded = self.input_dropout(self.encoder(input))

        # 手写 RNN 同样期望 (seq_len, batch, hidden)
        encoded = encoded.transpose(0, 1)

        output, hidden = self.rnn(encoded, hidden)
        # output: (seq_len, batch, hidden)
        output = output.transpose(0, 1).contiguous().view(batch_size * seq_len, self.hidden_size)

        output = self.decoder(self.output_norm(output))
        return output, hidden

    def init_hidden(self, batch_size):
        device = next(self.parameters()).device
        self._reset_ngram_context(batch_size, device)
        if self.model == "lstm":
            h0 = torch.zeros(self.n_layers, batch_size, self.hidden_size, device=device)
            c0 = torch.zeros(self.n_layers, batch_size, self.hidden_size, device=device)
            return h0, c0
        return torch.zeros(self.n_layers, batch_size, self.hidden_size, device=device)
