#!/usr/bin/env python

import argparse
import math
import os

import torch
import torch.nn as nn

from helpers import *


def evaluate_text(decoder, text, name, chunk_len, batch_size, device):
    decoder.eval()
    total_loss = 0.0
    total_steps = 0
    total_correct = 0
    total_tokens = 0
    criterion = nn.CrossEntropyLoss()
    with torch.no_grad():
        for inp, target in make_batches(text, chunk_len, batch_size, device):
            hidden = move_hidden(decoder.init_hidden(batch_size), device)
            for c in range(chunk_len):
                output, hidden = decoder(inp[:, c], hidden)
                loss = criterion(output.view(batch_size, -1), target[:, c])
                total_loss += loss.item()
                total_steps += 1
                preds = output.argmax(dim=1)
                total_correct += (preds == target[:, c]).sum().item()
                total_tokens += batch_size

    if total_steps == 0:
        print(f"[Eval:{name}] Not enough data for one batch.")
        return

    avg_loss = total_loss / total_steps
    ppl = math.exp(avg_loss)
    acc = total_correct / total_tokens * 100.0
    print(f"[Eval:{name}] loss={avg_loss:.4f} ppl={ppl:.2f} acc={acc:.2f}%")


def main():
    argparser = argparse.ArgumentParser()
    argparser.add_argument('--model_path', type=str, default='model.pt')
    argparser.add_argument('--eval_file', type=str, default='data/eval.txt')
    argparser.add_argument('--chunk_len', type=int, default=100)
    argparser.add_argument('--batch_size', type=int, default=100)
    argparser.add_argument('--model_file', type=str, default='model.py')
    argparser.add_argument('--cuda', action='store_true')
    args = argparser.parse_args()

    device = torch.device("cuda" if args.cuda and torch.cuda.is_available() else "cpu")
    if args.cuda and device.type != "cuda":
        print("CUDA requested but not available, using CPU.")

    CharRNN = load_char_rnn_class(args.model_file)
    decoder = CharRNN(
        input_size=n_characters,
        output_size=n_characters,
    )
    state_dict = torch.load(args.model_path, weights_only=True)
    decoder.load_state_dict(state_dict)
    decoder.to(device)

    eval_text, _ = read_file(args.eval_file)
    evaluate_text(decoder, eval_text, os.path.basename(args.eval_file), args.chunk_len, args.batch_size, device)


if __name__ == "__main__":
    main()
