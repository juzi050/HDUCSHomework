import sys
import numpy as np
import struct
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from layers_1 import FullyConnectedLayer, ReLULayer, SoftmaxLossLayer

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MNIST_DIR = os.path.join(BASE_DIR, "mnist_data")
TRAIN_DATA = "train-images-idx3-ubyte"
TRAIN_LABEL = "train-labels-idx1-ubyte"
TEST_DATA = "t10k-images-idx3-ubyte"
TEST_LABEL = "t10k-labels-idx1-ubyte"


def show_matrix(mat, name):
    #print(name + str(mat.shape) + ' mean %f, std %f' % (mat.mean(), mat.std()))
    pass


class MNIST_MLP(object):
    def __init__(
        self,
        batch_size=100,
        input_size=784,
        hidden1=512,
        hidden2=256,
        hidden3=128,
        out_classes=10,
        lr=0.08,
        lr_decay=0.92,
        momentum=0.9,
        weight_decay=1e-4,
        max_epoch=12,
        print_iter=100
    ):
        self.batch_size = batch_size
        self.input_size = input_size
        self.hidden1 = hidden1
        self.hidden2 = hidden2
        self.hidden3 = hidden3
        self.out_classes = out_classes
        self.lr = lr
        self.lr_decay = lr_decay
        self.momentum = momentum
        self.weight_decay = weight_decay
        self.max_epoch = max_epoch
        self.print_iter = print_iter
        self.hidden_dims = [self.hidden1, self.hidden2, self.hidden3]

    def load_mnist(self, file_dir, is_images=True):
        bin_file = open(file_dir, 'rb')
        bin_data = bin_file.read()
        bin_file.close()

        if is_images:
            fmt_header = '>iiii'
            magic, num_images, num_rows, num_cols = struct.unpack_from(fmt_header, bin_data, 0)
        else:
            fmt_header = '>ii'
            magic, num_images = struct.unpack_from(fmt_header, bin_data, 0)
            num_rows, num_cols = 1, 1
        data_size = num_images * num_rows * num_cols
        mat_data = struct.unpack_from('>' + str(data_size) + 'B', bin_data, struct.calcsize(fmt_header))
        mat_data = np.reshape(mat_data, [num_images, num_rows * num_cols])
        print('Load images from %s, number: %d, data shape: %s' % (file_dir, num_images, str(mat_data.shape)))
        return mat_data

    def load_data(self):
        print('Loading MNIST data from files...')
        train_images = self.load_mnist(os.path.join(MNIST_DIR, TRAIN_DATA), True).astype(np.float32) / 255.0
        train_labels = self.load_mnist(os.path.join(MNIST_DIR, TRAIN_LABEL), False).astype(np.int64)
        test_images = self.load_mnist(os.path.join(MNIST_DIR, TEST_DATA), True).astype(np.float32) / 255.0
        test_labels = self.load_mnist(os.path.join(MNIST_DIR, TEST_LABEL), False).astype(np.int64)

        self.data_mean = np.mean(train_images, axis=0, keepdims=True)
        self.data_std = np.std(train_images, axis=0, keepdims=True) + 1e-6
        self.train_images = (train_images - self.data_mean) / self.data_std
        self.test_images = (test_images - self.data_mean) / self.data_std
        self.train_labels = train_labels.reshape(-1)
        self.test_labels = test_labels.reshape(-1)
        self.train_data = np.concatenate([self.train_images, self.train_labels[:, None]], axis=1)
        self.test_data = np.concatenate([self.test_images, self.test_labels[:, None]], axis=1)

    def shuffle_data(self):
        print('Randomly shuffle MNIST data...')
        indices = np.random.permutation(self.train_images.shape[0])
        self.train_images = self.train_images[indices]
        self.train_labels = self.train_labels[indices]
        self.train_data = np.concatenate([self.train_images, self.train_labels[:, None]], axis=1)

    def build_model(self):
        print('Building multi-layer perception model...')
        dims = [self.input_size] + self.hidden_dims + [self.out_classes]
        self.fc_layers = []
        self.relu_layers = []
        for idx in range(len(dims) - 1):
            fc_layer = FullyConnectedLayer(dims[idx], dims[idx + 1])
            self.fc_layers.append(fc_layer)
            setattr(self, 'fc%d' % (idx + 1), fc_layer)
            if idx < len(dims) - 2:
                relu_layer = ReLULayer()
                self.relu_layers.append(relu_layer)
                setattr(self, 'relu%d' % (idx + 1), relu_layer)
        self.softmax = SoftmaxLossLayer()
        self.update_layer_list = self.fc_layers

    def init_model(self):
        print('Initializing parameters of each layer in MLP...')
        for layer in self.update_layer_list:
            layer.init_param(std=np.sqrt(2.0 / layer.num_input))

    def load_model(self, param_dir):
        print('Loading parameters from file ' + param_dir)
        params = np.load(param_dir, allow_pickle=True).item()
        for idx, layer in enumerate(self.fc_layers):
            layer.load_param(params['w%d' % (idx + 1)], params['b%d' % (idx + 1)])
        if 'mean' in params:
            self.data_mean = params['mean']
            self.data_std = params['std']

    def save_model(self, param_dir):
        print('Saving parameters to file ' + param_dir)
        params = {}
        for idx, layer in enumerate(self.fc_layers):
            params['w%d' % (idx + 1)], params['b%d' % (idx + 1)] = layer.save_param()
        params['mean'] = self.data_mean
        params['std'] = self.data_std
        np.save(param_dir, params)

    def forward(self, input):
        hidden = input
        for idx, fc_layer in enumerate(self.fc_layers):
            hidden = fc_layer.forward(hidden)
            if idx < len(self.relu_layers):
                hidden = self.relu_layers[idx].forward(hidden)
        prob = self.softmax.forward(hidden)
        return prob

    def backward(self):
        grad = self.softmax.backward()
        for idx in range(len(self.fc_layers) - 1, -1, -1):
            grad = self.fc_layers[idx].backward(grad)
            if idx > 0:
                grad = self.relu_layers[idx - 1].backward(grad)

    def update(self, lr):
        for layer in self.update_layer_list:
            layer.update_param(lr, momentum=self.momentum, weight_decay=self.weight_decay)

    def train(self):
        max_batch = self.train_images.shape[0] // self.batch_size
        print('Start training...')
        for idx_epoch in range(self.max_epoch):
            current_lr = self.lr * (self.lr_decay ** idx_epoch)
            self.shuffle_data()
            for idx_batch in range(max_batch):
                start = idx_batch * self.batch_size
                end = (idx_batch + 1) * self.batch_size
                batch_images = self.train_images[start:end]
                batch_labels = self.train_labels[start:end]
                prob = self.forward(batch_images)
                loss = self.softmax.get_loss(batch_labels)
                self.backward()
                self.update(current_lr)
                if idx_batch % self.print_iter == 0:
                    pred_labels = np.argmax(prob, axis=1)
                    batch_acc = np.mean(pred_labels == batch_labels)
                    print('Epoch %d, iter %d, lr %.5f, loss: %.6f, batch acc: %.4f' % (idx_epoch, idx_batch, current_lr, loss, batch_acc))

    def evaluate(self):
        pred_results = np.zeros([self.test_images.shape[0]])
        num_batch = self.test_images.shape[0] // self.batch_size
        for idx in range(num_batch):
            start = idx * self.batch_size
            end = (idx + 1) * self.batch_size
            batch_images = self.test_images[start:end]
            prob = self.forward(batch_images)
            pred_labels = np.argmax(prob, axis=1)
            pred_results[start:end] = pred_labels
        if self.test_images.shape[0] % self.batch_size > 0:
            start = num_batch * self.batch_size
            batch_images = self.test_images[start:]
            prob = self.forward(batch_images)
            pred_labels = np.argmax(prob, axis=1)
            pred_results[start:] = pred_labels
        accuracy = np.mean(pred_results == self.test_labels)
        print('Accuracy in test set: %f' % accuracy)
        return accuracy


def build_mnist_mlp(param_dir='mlp.npy'):
    np.random.seed(0)
    mlp = MNIST_MLP()
    mlp.load_data()
    mlp.build_model()
    mlp.init_model()
    mlp.train()
    mlp.save_model(param_dir)
    mlp.load_model(param_dir)
    return mlp


if __name__ == '__main__':
    mlp = build_mnist_mlp()
    mlp.evaluate()
