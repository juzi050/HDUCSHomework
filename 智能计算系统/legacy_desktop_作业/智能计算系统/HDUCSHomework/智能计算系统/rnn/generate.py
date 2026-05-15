#!/usr/bin/env python

import argparse

import torch

from helpers import *


def generate(decoder, prime_str='A', predict_len=100, temperature=0.8, cuda=False):
    device = torch.device("cuda" if cuda and torch.cuda.is_available() else "cpu")
    decoder.to(device)
    hidden = move_hidden(decoder.init_hidden(1), device)
    prime_input = char_tensor(prime_str).unsqueeze(0).to(device)

    predicted = prime_str

    for p in range(len(prime_str) - 1):
        _, hidden = decoder(prime_input[:, p].unsqueeze(1), hidden)
    inp = prime_input[:, -1].unsqueeze(1)

    for p in range(predict_len):
        output, hidden = decoder(inp, hidden)
        
        output_dist = output.data.view(-1).div(temperature).exp()
        top_i = torch.multinomial(output_dist, 1)[0]

        predicted_char = all_characters[top_i]
        predicted += predicted_char
        inp = char_tensor(predicted_char).to(device).unsqueeze(1)

    return predicted

if __name__ == '__main__':
    argparser = argparse.ArgumentParser()
    argparser.add_argument('model_path', type=str, default='model.pt', nargs='?')
    argparser.add_argument('-p', '--prime_str', type=str, default='A')
    argparser.add_argument('-l', '--predict_len', type=int, default=100)
    argparser.add_argument('-t', '--temperature', type=float, default=0.8)
    argparser.add_argument('--model_file', type=str, default='model.py')
    argparser.add_argument('--cuda', action='store_true')
    args = argparser.parse_args()

    CharRNN = load_char_rnn_class(args.model_file)
    decoder = CharRNN(input_size=n_characters, output_size=n_characters)
    decoder.load_state_dict(torch.load(args.model_path, weights_only=True))
    print(generate(decoder, prime_str=args.prime_str, predict_len=args.predict_len, temperature=args.temperature, cuda=args.cuda))

