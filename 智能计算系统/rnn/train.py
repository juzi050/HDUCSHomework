#!/usr/bin/env python

import argparse

import torch
import torch.nn as nn
from tqdm import tqdm

from helpers import *
from generate import generate


def main():
    argparser = argparse.ArgumentParser()
    argparser.add_argument('--filename', type=str, default='data/train.txt')
    argparser.add_argument('--epoch', type=int, default=1000)
    argparser.add_argument('--print_every', type=int, default=100)
    argparser.add_argument('--learning_rate', type=float, default=0.01)
    argparser.add_argument('--chunk_len', type=int, default=100)
    argparser.add_argument('--batch_size', type=int, default=100)
    argparser.add_argument('--shuffle', action='store_true')
    argparser.add_argument('--model_file', type=str, default='model.py')
    argparser.add_argument('--cuda', action='store_true')
    args = argparser.parse_args()

    file, file_len = read_file(args.filename)
    device = torch.device("cuda" if args.cuda and torch.cuda.is_available() else "cpu")
    if args.cuda and device.type != "cuda":
        print("CUDA requested but not available, using CPU.")

    def random_training_set(chunk_len, batch_size):
        inp = torch.LongTensor(batch_size, chunk_len)
        target = torch.LongTensor(batch_size, chunk_len)
        for bi in range(batch_size):
            start_index = random.randint(0, file_len - chunk_len)
            end_index = start_index + chunk_len + 1
            chunk = file[start_index:end_index]
            inp[bi] = char_tensor(chunk[:-1])
            target[bi] = char_tensor(chunk[1:])
        inp = inp.to(device)
        target = target.to(device)
        return inp, target

    CharRNN = load_char_rnn_class(args.model_file)
    decoder = CharRNN(
        input_size=n_characters,
        output_size=n_characters,
    )
    decoder_optimizer = torch.optim.Adam(decoder.parameters(), lr=args.learning_rate)
    criterion = nn.CrossEntropyLoss()
    decoder.to(device)

    def train_step(inp, target):
        hidden = move_hidden(decoder.init_hidden(args.batch_size), device)
        
        decoder.zero_grad()

        output, hidden = decoder(inp, hidden) 

        loss = criterion(output, target.view(-1))  

        loss.backward()
        decoder_optimizer.step()

        preds = output.argmax(dim=1)
        correct = (preds == target.view(-1)).sum().item()

        return loss.item(), correct

    def save():
        save_filename = 'model.pt'
        torch.save(decoder.state_dict(), save_filename)
        print('Saved as %s' % save_filename)

    start_time = time.time()
    try:
        print("Training for %d epochs..." % args.epoch)
        for epoch in tqdm(range(1, args.epoch + 1)):
            loss, correct = train_step(*random_training_set(args.chunk_len, args.batch_size))

            if epoch % args.print_every == 0:
                acc = correct / (args.batch_size * args.chunk_len) * 100.0
                print('[%s (%d %d%%) %.4f]' % (time_since(start_time), epoch, epoch / args.epoch * 100, loss))
                print("Accuracy:", acc, "%")
                print(generate(decoder, 'Wh', 100, cuda=args.cuda), '\n')

        print("Saving...")
        save()

    except KeyboardInterrupt:
        print("Saving before quit...")
        save()


if __name__ == "__main__":
    main()
