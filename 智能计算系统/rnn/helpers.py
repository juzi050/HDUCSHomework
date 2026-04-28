
import importlib.util
import os
import string
import random
import time
import math
import sys

import torch

# 字符表
all_characters = string.printable
n_characters = len(all_characters)

def read_file(filename):
    with open(filename, "r", encoding="utf-8") as f:
        text = f.read()
    return text, len(text)


def load_char_rnn_class(model_file):
    """动态加载 model.py，返回 CharRNN 类。"""
    model_path = os.path.join(os.path.dirname(__file__), model_file) if not os.path.isabs(model_file) else model_file
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model file not found: {model_path}")
    module_name = f"{os.path.splitext(os.path.basename(model_path))[0]}_module"
    spec = importlib.util.spec_from_file_location(module_name, model_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Failed to load module from: {model_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    if not hasattr(module, "CharRNN"):
        raise AttributeError(f"`CharRNN` not found in: {model_path}")
    return module.CharRNN


def move_hidden(hidden, device):
    """将 hidden 移动到指定 device。"""
    if isinstance(hidden, (tuple, list)):
        return tuple(h.to(device) for h in hidden)
    return hidden.to(device)


def char_tensor(string):
    tensor = torch.zeros(len(string)).long()
    for c in range(len(string)):
        try:
            tensor[c] = all_characters.index(string[c])
        except:
            continue
    return tensor

def time_since(since):
    s = time.time() - since
    m = math.floor(s / 60)
    s -= m * 60
    return '%dm %ds' % (m, s)

def make_batches(text, chunk_len, batch_size, device=None):
    n_chars = len(text) - 1
    n_chunks = n_chars // chunk_len
    n_batches = n_chunks // batch_size
    for b in range(n_batches):
        inp = torch.LongTensor(batch_size, chunk_len)
        target = torch.LongTensor(batch_size, chunk_len)
        for bi in range(batch_size):
            start = (b * batch_size + bi) * chunk_len
            chunk = text[start:start + chunk_len + 1]
            inp[bi] = char_tensor(chunk[:-1])
            target[bi] = char_tensor(chunk[1:])
        if device is not None:
            inp = inp.to(device)
            target = target.to(device)
        yield inp, target

