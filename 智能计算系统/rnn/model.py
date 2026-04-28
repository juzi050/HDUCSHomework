import torch
import torch.nn as nn


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
        dropout = kwargs.get("dropout", 0.1)
        input_dropout = kwargs.get("input_dropout", 0.1)

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

    def forward(self, input, hidden):
        # 统一接口：input 可为 (batch,) 或 (batch, seq_len)
        if input.dim() == 1:
            input = input.unsqueeze(1)

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
        if self.model == "lstm":
            h0 = torch.zeros(self.n_layers, batch_size, self.hidden_size, device=device)
            c0 = torch.zeros(self.n_layers, batch_size, self.hidden_size, device=device)
            return h0, c0
        return torch.zeros(self.n_layers, batch_size, self.hidden_size, device=device)
