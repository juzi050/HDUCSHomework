import numpy as np


def show_matrix(mat, name):
    # print(name + str(mat.shape) + ' mean %f, std %f' % (mat.mean(), mat.std()))
    pass


def show_time(time, name):
    # print(name + str(time))
    pass


class FullyConnectedLayer(object):
    def __init__(self, num_input, num_output):
        self.num_input = num_input
        self.num_output = num_output
        self.input = None
        self.output = None
        self.weight = None
        self.bias = None
        self.d_weight = None
        self.d_bias = None
        print('\tFully connected layer with input %d, output %d.' % (self.num_input, self.num_output))

    def init_param(self, std=None):
        if std is None:
            std = np.sqrt(2.0 / self.num_input)
        self.weight = np.random.normal(
            loc=0.0,
            scale=std,
            size=(self.num_input, self.num_output),
        ).astype(np.float32)
        self.bias = np.zeros((1, self.num_output), dtype=np.float32)
        show_matrix(self.weight, 'fc weight ')
        show_matrix(self.bias, 'fc bias ')

    def forward(self, input):
        self.input = input
        self.output = np.dot(self.input, self.weight) + self.bias
        return self.output

    def backward(self, top_diff):
        self.d_weight = np.dot(self.input.T, top_diff)
        self.d_bias = np.sum(top_diff, axis=0, keepdims=True)
        bottom_diff = np.dot(top_diff, self.weight.T)
        return bottom_diff

    def get_gradient(self):
        return self.d_weight, self.d_bias

    def update_param(self, lr):
        self.weight -= lr * self.d_weight
        self.bias -= lr * self.d_bias

    def load_param(self, weight, bias):
        assert self.weight.shape == weight.shape
        assert self.bias.shape == bias.shape
        self.weight = weight.astype(np.float32)
        self.bias = bias.astype(np.float32)
        show_matrix(self.weight, 'fc weight ')
        show_matrix(self.bias, 'fc bias ')

    def save_param(self):
        show_matrix(self.weight, 'fc weight ')
        show_matrix(self.bias, 'fc bias ')
        return self.weight, self.bias


class ReLULayer(object):
    def __init__(self):
        self.input = None
        print('\tRelu layer.')

    def forward(self, input):
        self.input = input
        return np.maximum(self.input, 0.0)

    def backward(self, top_diff):
        return top_diff * (self.input > 0)


class SoftmaxLossLayer(object):
    def __init__(self):
        self.prob = None
        self.label = None
        self.batch_size = 0
        print('\tSoftmax loss layer.')

    def forward(self, input):
        input_max = np.max(input, axis=1, keepdims=True)
        input_exp = np.exp(input - input_max)
        exp_sum = np.sum(input_exp, axis=1, keepdims=True)
        self.prob = input_exp / exp_sum
        return self.prob

    def get_loss(self, label):
        self.label = np.asarray(label, dtype=np.int64).reshape(-1)
        self.batch_size = self.prob.shape[0]
        correct_prob = self.prob[np.arange(self.batch_size), self.label]
        loss = -np.mean(np.log(np.clip(correct_prob, 1e-12, 1.0)))
        return loss

    def backward(self):
        bottom_diff = self.prob.copy()
        bottom_diff[np.arange(self.batch_size), self.label] -= 1.0
        bottom_diff /= self.batch_size
        return bottom_diff
