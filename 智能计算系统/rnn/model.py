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
        # TODO: 定义输入→隐层和隐层→隐层的线性变换
        self.W_ih = None
        self.W_hh = None

    def forward(self, x, h):
        """
        x : (batch, input_size)
        h : (batch, hidden_size)
        返回 h_next : (batch, hidden_size)
        """
        # TODO: 实现 Elman RNN 更新公式
        raise NotImplementedError


class LSTMCell(nn.Module):
    """LSTM cell with input / forget / output gates and cell state."""

    def __init__(self, input_size, hidden_size):
        super().__init__()
        self.hidden_size = hidden_size
        # TODO: 四个门共用一个大线性层，输出维度为 4 * hidden_size
        # 顺序：input gate, forget gate, cell gate, output gate
        self.W_ih = None
        self.W_hh = None

    def forward(self, x, state):
        """
        x     : (batch, input_size)
        state : tuple( h (batch, hidden), c (batch, hidden) )
        返回   : tuple( h_next, c_next )
        """
        h, c = state
        # TODO: 计算四个门，更新 c 和 h
        raise NotImplementedError


class GRUCell(nn.Module):
    """GRU cell with reset and update gates."""

    def __init__(self, input_size, hidden_size):
        super().__init__()
        self.hidden_size = hidden_size
        # TODO: reset gate 和 update gate 共用一个线性层（2 * hidden_size）
        self.W_rz_ih = None
        self.W_rz_hh = None
        # TODO: 候选隐状态的线性层
        self.W_n_ih = None
        self.W_n_hh = None

    def forward(self, x, h):
        """
        x : (batch, input_size)
        h : (batch, hidden_size)
        返回 h_next : (batch, hidden_size)
        """
        # TODO: 计算 reset gate、update gate 和候选隐状态，更新 h
        raise NotImplementedError


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
                h[layer] = cell(x, h[layer])
                x = h[layer]
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
                h[layer], c[layer] = cell(x, (h[layer], c[layer]))
                x = h[layer]
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
                h[layer] = cell(x, h[layer])
                x = h[layer]
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

    def __init__(self, input_size, output_size, hidden_size=128, model="lstm", n_layers=2):
        super().__init__()
        self.model = model.lower()
        self.hidden_size = hidden_size
        self.n_layers = n_layers

        self.encoder = nn.Embedding(input_size, hidden_size)

        if self.model == "lstm":
            self.rnn = StackedLSTM(hidden_size, hidden_size, n_layers)
        elif self.model == "rnn":
            self.rnn = StackedRNN(hidden_size, hidden_size, n_layers)
        else:
            self.rnn = StackedGRU(hidden_size, hidden_size, n_layers)

        self.decoder = nn.Linear(hidden_size, output_size)

    def forward(self, input, hidden):
        # 统一接口：input 可为 (batch,) 或 (batch, seq_len)
        if input.dim() == 1:
            # TODO: 将一维 input 扩展为 (batch, 1)
            input = None

        batch_size, seq_len = input.size()
        # TODO: 通过 encoder 得到 encoded，形状应为 (batch, seq_len, hidden)
        encoded = None

        # 手写 RNN 同样期望 (seq_len, batch, hidden)
        # TODO: 调整 encoded 维度为 (seq_len, batch, hidden)
        encoded = None

        # TODO: 调用 self.rnn，得到 output 和 hidden
        output, hidden = None, None
        # output: (seq_len, batch, hidden)
        # TODO: 将 output 调整为 (batch, seq_len, hidden)，再 reshape 为 (batch*seq_len, hidden)
        output = None

        # TODO: 通过 decoder 得到最终输出
        output = None
        return output, hidden

    def init_hidden(self, batch_size):
        device = next(self.parameters()).device
        if self.model == "lstm":
            # TODO: 初始化 LSTM 的 h0 和 c0（形状: n_layers, batch_size, hidden_size）
            h0 = None
            c0 = None
            return h0, c0
        # TODO: 初始化 RNN/GRU 的 h0（形状: n_layers, batch_size, hidden_size）
        return None
