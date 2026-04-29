# coding:utf-8
import numpy as np
import struct
import os
import scipy.io
import time


class ContentLossLayer(object):
    def __init__(self):
        print('\tContent loss layer.')

    def forward(self, input_layer, content_layer):
        loss = 0.5 * np.sum(np.square(input_layer - content_layer))
        return loss

    def backward(self, input_layer, content_layer):
        bottom_diff = input_layer - content_layer
        return bottom_diff


class StyleLossLayer(object):
    def __init__(self):
        print('\tStyle loss layer.')

    def forward(self, input_layer, style_layer):
        style_layer_reshape = np.reshape(style_layer, [style_layer.shape[0], style_layer.shape[1], -1])
        self.gram_style = np.zeros([style_layer.shape[0], style_layer.shape[1], style_layer.shape[1]], dtype=style_layer.dtype)
        for idxn in range(style_layer.shape[0]):
            self.gram_style[idxn, :, :] = np.dot(style_layer_reshape[idxn], style_layer_reshape[idxn].T)

        self.input_layer_reshape = np.reshape(input_layer, [input_layer.shape[0], input_layer.shape[1], -1])
        self.gram_input = np.zeros([input_layer.shape[0], input_layer.shape[1], input_layer.shape[1]], dtype=input_layer.dtype)
        for idxn in range(input_layer.shape[0]):
            self.gram_input[idxn, :, :] = np.dot(self.input_layer_reshape[idxn], self.input_layer_reshape[idxn].T)

        M = input_layer.shape[2] * input_layer.shape[3]
        N = input_layer.shape[1]
        self.div = M * M * N * N
        style_diff = self.gram_input - self.gram_style
        loss = np.sum(np.square(style_diff)) / (4.0 * self.div)
        return loss

    def backward(self, input_layer, style_layer):
        bottom_diff = np.zeros([input_layer.shape[0], input_layer.shape[1], input_layer.shape[2]*input_layer.shape[3]], dtype=input_layer.dtype)
        for idxn in range(input_layer.shape[0]):
            bottom_diff[idxn, :, :] = np.dot(self.gram_input[idxn] - self.gram_style[idxn], self.input_layer_reshape[idxn]) / self.div
        bottom_diff = np.reshape(bottom_diff, input_layer.shape)
        return bottom_diff
