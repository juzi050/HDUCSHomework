## 项目简介

这是一个**字符级序列预测 / 文本生成**教学项目，数据集选自预处理过后的TinyStories数据集。  
模型每一步输入一个字符，学习预测**下一个字符**，从而完成语言建模与文本生成。

学生需要在 `model.py` 中实现自己的 RNN 模型（如 RNN/LSTM/GRU），
训练与评估由已给出的脚本完成。
评估集对学生不可见。

## 文件结构

- `shakespeare.txt`：原始完整语料。
- `train.txt`：训练集（约 90% 字符，已由脚本切分生成）。
- `model.py`：**学生需要实现的模型文件**（必须导出 `CharRNN` 类并满足接口约定）。
- `train.py`：只负责训练，保存模型权重为 `.pt` 文件。
- `eval.py`：只负责评估，读取训练好的 `.pt` 模型，对一个或多个评估文本文件计算指标。
- `generate.py`：使用训练好的模型进行文本生成。
- `helpers.py`：数据与工具函数（字符表、张量转换、评估用批次生成等）。

## 依赖与环境

- Python 3.8+
- PyTorch
- 其他依赖见 `requirements.txt`

安装依赖示例（建议使用虚拟环境）：

```bash
pip install -r requirements.txt
```

## 数据准备

仓库中提供了一个训练集：`data/train_t.txt`

你也可以根据需要，把自己的文本数据按类似方式切分成训练集和评估集。

## 学生需要实现的接口（`model.py`）

学生需在 `model.py` 中实现字符级 RNN 模型。训练、评估、生成脚本会**动态加载**该文件，因此必须满足以下**命名与接口约定**。

### 1. 命名规定

| 项目    | 约定                                             |
| ----- | ---------------------------------------------- |
| 文件名   | `model.py`（可通过 `--model_file` 指定）              |
| 类名    | `CharRNN`（必须导出）                                |
| 构造函数  | `__init__(self, input_size, output_size, ...)` |
| 前向方法  | `forward(self, input, hidden)`                 |
| 初始隐状态 | `init_hidden(self, batch_size)`                |

### 2. 构造函数签名

```python
def __init__(self, input_size, output_size, hidden_size=128, model="gru", n_layers=2, **kwargs):
```

- `input_size`：字符表大小（`helpers.n_characters`）
- `output_size`：输出类别数（通常等于 `input_size`）
- 其余参数需有默认值，脚本仅传入 `input_size` 和 `output_size`。

### 3. 张量维度约定

#### 3.1 `forward(self, input, hidden) -> (output, hidden)`

| 参数/返回值   | 维度                                                                      | 类型                  | 说明                                  |
| -------- | ----------------------------------------------------------------------- | ------------------- | ----------------------------------- |
| `input`  | `(B,)` 或 `(B, L)`                                                       | `torch.LongTensor`  | 字符索引。单步为 `(B,)`，整段序列为 `(B, L)`      |
| `hidden` | RNN/GRU: `(n_layers, B, H)`<br>LSTM: `((n_layers,B,H), (n_layers,B,H))` | `torch.Tensor`      | 上一时刻隐状态                             |
| `output` | `(B*L, output_size)`                                                    | `torch.FloatTensor` | 对每个位置的 logits，用于 `CrossEntropyLoss` |
| `hidden` | 同上                                                                      | 同上                  | 当前时刻隐状态                             |

> `B` = batch_size，`L` = seq_len，`H` = hidden_size。单步输入 `(B,)` 时输出为 `(B, output_size)`。

#### 3.2 `init_hidden(self, batch_size) -> hidden`

| 返回值     | 维度                                                 | 说明   |
| ------- | -------------------------------------------------- | ---- |
| RNN/GRU | `(n_layers, batch_size, hidden_size)`              | 全零张量 |
| LSTM    | `(h0, c0)`，各 `(n_layers, batch_size, hidden_size)` | 全零张量 |

隐状态需与模型参数在同一 device 上（`next(self.parameters()).device`）。

### 4. 接口兼容说明

- 输入为 `(B,)` 时，内部应等价于 `(B, 1)` 处理，避免 PyTorch 将 2D 输入误判为 unbatched。
- 输出需为 `(B*L, output_size)`，与 `target.view(-1)` 对齐用于 `CrossEntropyLoss`。

## 训练

通常我们在训练时直接运行（使用默认数据集和默认模型文件）：

```bash
python train.py
```

常用参数：

```text
--n_epochs         训练轮数                      默认 1000
--print_every      日志打印间隔（按 epoch）      默认 100
--learning_rate    学习率                        默认 0.01
--chunk_len        每个样本的序列长度           默认 100
--batch_size       批大小                        默认 100
--model_file       模型定义文件路径              默认 model.py
--cuda             是否使用 CUDA（有 GPU 时可加上）
```

训练脚本会在当前目录下保存一个 `.pt` 模型文件（例如 `train.txt` 会对应 `train.pt`，或根据你传入的文件名来生成）。

## 评估

评估脚本会读取训练好的模型，对一个或多个评估文本文件进行评估。  

```bash
python eval.py --model_path model.pt --eval_file data/eval.txt --model_file model.py
```

常用参数：

```text
--eval_files       一个或多个评估文本文件路径
--chunk_len        每个样本的序列长度           默认 100
--batch_size       批大小                        默认 100
--model_file       模型定义文件路径              默认 model.py
--cuda             是否使用 CUDA
```

评估脚本会输出如下指标：

- `loss`：平均交叉熵损失，越低越好。
- `ppl`：Perplexity（困惑度） = exp(loss)，越低越好。
- `acc`：字符级准确率（每一步预测是否等于真实下一个字符），越高越好。

## 文本生成

使用训练好的 `.pt` 模型进行文本生成，例如：

```bash
python generate.py model.pt --model_file model.py --prime_str "Where"
```

常用参数：

```text
--prime_str    生成时的起始字符串
--predict_len  要生成的字符长度
--temperature  采样温度（越大越随机）
--model_file   模型定义文件路径
--cuda         是否使用 CUDA
```

## 建议的实验方向

- 尝试不同的 RNN 结构：`"rnn"` / `"gru"` / `"lstm"`。
- 调整 `hidden_size`、`n_layers`，观察对困惑度与生成效果的影响。
- 调整 `chunk_len` 与 `batch_size`，比较收敛速度与性能。
- 在生成阶段调整 `temperature`，体验“更加随机”与“更加保守”的文本风格差异。

通过完成 `model.py` 并使用本项目提供的训练、评估和生成脚本，你可以系统地理解**字符级语言模型**与**序列预测任务**的完整流程。

## 提交要求（必看！！）

1. 提交一个以**学号**命名的压缩包，例如：20240001.zip
2. 压缩包内必须包含：
   - model.py（不要改名）
   - 一个训练好的模型权重文件 .pt
3. 权重文件命名必须符合以下之一：
   - *_rnn.pt
   - *_lstm.pt
   - *_gru.pt
4. 不要提交 train.py、eval.py、helpers.py、data、.git、__pycache__ 等无关文件
5. model.py 中必须定义 CharRNN 类，并能与提交的 .pt 文件匹配，否则无法自动批改
