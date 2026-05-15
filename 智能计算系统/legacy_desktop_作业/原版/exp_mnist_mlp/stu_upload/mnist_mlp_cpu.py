import os
import sys
import time

import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from layers_1 import FullyConnectedLayer, ReLULayer, SoftmaxLossLayer


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MNIST_DIR = os.path.join(BASE_DIR, "mnist_data")
TRAIN_DATA = "train-images-idx3-ubyte"
TRAIN_LABEL = "train-labels-idx1-ubyte"
TEST_DATA = "t10k-images-idx3-ubyte"
TEST_LABEL = "t10k-labels-idx1-ubyte"


def show_matrix(mat, name):
    # print(name + str(mat.shape) + ' mean %f, std %f' % (mat.mean(), mat.std()))
    pass


class MNIST_MLP(object):
    def __init__(
        self,
        batch_size=200,
        input_size=784,
        hidden1=128,
        hidden2=64,
        out_classes=10,
        lr=0.10,
        lr_decay=0.95,
        max_epoch=12,
        print_iter=50,
        seed=24051220,
    ):
        self.batch_size = batch_size
        self.input_size = input_size
        self.hidden1 = hidden1
        self.hidden2 = hidden2
        self.out_classes = out_classes
        self.lr = lr
        self.lr_decay = lr_decay
        self.max_epoch = max_epoch
        self.print_iter = print_iter
        self.seed = seed

        self.train_data = None
        self.test_data = None
        self.train_images = None
        self.train_labels = None
        self.test_images = None
        self.test_labels = None
        self.update_layer_list = []

    def load_mnist(self, file_dir, is_images=True):
        with open(file_dir, 'rb') as bin_file:
            bin_data = bin_file.read()

        if is_images:
            header = np.frombuffer(bin_data, dtype='>i4', count=4)
            _, num_images, num_rows, num_cols = header
            offset = 16
            mat_data = np.frombuffer(bin_data, dtype=np.uint8, offset=offset)
            mat_data = mat_data.reshape(num_images, num_rows * num_cols)
        else:
            header = np.frombuffer(bin_data, dtype='>i4', count=2)
            _, num_images = header
            offset = 8
            mat_data = np.frombuffer(bin_data, dtype=np.uint8, offset=offset)
            mat_data = mat_data.reshape(num_images, 1)

        print('Load images from %s, number: %d, data shape: %s' % (file_dir, num_images, str(mat_data.shape)))
        return mat_data

    def load_data(self):
        print('Loading MNIST data from files...')
        train_images = self.load_mnist(os.path.join(MNIST_DIR, TRAIN_DATA), True).astype(np.float32) / 255.0
        train_labels = self.load_mnist(os.path.join(MNIST_DIR, TRAIN_LABEL), False).astype(np.int64)
        test_images = self.load_mnist(os.path.join(MNIST_DIR, TEST_DATA), True).astype(np.float32) / 255.0
        test_labels = self.load_mnist(os.path.join(MNIST_DIR, TEST_LABEL), False).astype(np.int64)

        self.train_images = train_images
        self.train_labels = train_labels.reshape(-1)
        self.test_images = test_images
        self.test_labels = test_labels.reshape(-1)

        self.train_data = np.concatenate(
            [self.train_images, self.train_labels[:, None].astype(np.float32)],
            axis=1,
        )
        self.test_data = np.concatenate(
            [self.test_images, self.test_labels[:, None].astype(np.float32)],
            axis=1,
        )

    def shuffle_data(self):
        print('Randomly shuffle MNIST data...')
        indices = np.random.permutation(self.train_data.shape[0])
        self.train_data = self.train_data[indices]

    def build_model(self):
        print('Building multi-layer perception model...')
        self.fc1 = FullyConnectedLayer(self.input_size, self.hidden1)
        self.relu1 = ReLULayer()
        self.fc2 = FullyConnectedLayer(self.hidden1, self.hidden2)
        self.relu2 = ReLULayer()
        self.fc3 = FullyConnectedLayer(self.hidden2, self.out_classes)
        self.softmax = SoftmaxLossLayer()
        self.update_layer_list = [self.fc1, self.fc2, self.fc3]

    def init_model(self):
        print('Initializing parameters of each layer in MLP...')
        for layer in self.update_layer_list:
            layer.init_param()

    def load_model(self, param_dir):
        print('Loading parameters from file ' + param_dir)
        params = np.load(param_dir, allow_pickle=True).item()
        self.fc1.load_param(params['w1'], params['b1'])
        self.fc2.load_param(params['w2'], params['b2'])
        self.fc3.load_param(params['w3'], params['b3'])

    def save_model(self, param_dir):
        print('Saving parameters to file ' + param_dir)
        params = {}
        params['w1'], params['b1'] = self.fc1.save_param()
        params['w2'], params['b2'] = self.fc2.save_param()
        params['w3'], params['b3'] = self.fc3.save_param()
        np.save(param_dir, params, allow_pickle=True)

    def forward(self, input):
        h1 = self.fc1.forward(input)
        h1 = self.relu1.forward(h1)
        h2 = self.fc2.forward(h1)
        h2 = self.relu2.forward(h2)
        h3 = self.fc3.forward(h2)
        prob = self.softmax.forward(h3)
        return prob

    def backward(self):
        dloss = self.softmax.backward()
        dh2 = self.fc3.backward(dloss)
        dh2 = self.relu2.backward(dh2)
        dh1 = self.fc2.backward(dh2)
        dh1 = self.relu1.backward(dh1)
        self.fc1.backward(dh1)

    def update(self, lr):
        for layer in self.update_layer_list:
            layer.update_param(lr)

    def evaluate(self):
        pred_results = np.zeros((self.test_images.shape[0],), dtype=np.int64)
        num_batches = self.test_images.shape[0] // self.batch_size
        for idx in range(num_batches):
            batch_images = self.test_images[idx * self.batch_size:(idx + 1) * self.batch_size]
            prob = self.forward(batch_images)
            pred_results[idx * self.batch_size:(idx + 1) * self.batch_size] = np.argmax(prob, axis=1)
        accuracy = np.mean(pred_results == self.test_labels)
        print('Accuracy in test set: %f' % accuracy)
        return accuracy

    def train(self):
        max_batch = self.train_data.shape[0] // self.batch_size
        print('Start training...')
        for idx_epoch in range(self.max_epoch):
            epoch_start = time.time()
            self.shuffle_data()
            current_lr = self.lr * (self.lr_decay ** idx_epoch)
            epoch_loss = 0.0

            for idx_batch in range(max_batch):
                batch = self.train_data[idx_batch * self.batch_size:(idx_batch + 1) * self.batch_size]
                batch_images = batch[:, :-1].astype(np.float32)
                batch_labels = batch[:, -1].astype(np.int64)

                self.forward(batch_images)
                loss = self.softmax.get_loss(batch_labels)
                self.backward()
                self.update(current_lr)

                epoch_loss += loss
                if idx_batch % self.print_iter == 0:
                    print(
                        'Epoch %d, iter %d, lr %.5f, loss: %.6f'
                        % (idx_epoch + 1, idx_batch, current_lr, loss)
                    )

            avg_loss = epoch_loss / max_batch
            test_acc = self.evaluate()
            print(
                'Epoch %d finished in %.2fs, avg loss %.6f, test accuracy %.4f'
                % (idx_epoch + 1, time.time() - epoch_start, avg_loss, test_acc)
            )


def build_mnist_mlp(param_dir='mlp.npy'):
    np.random.seed(24051220)
    mlp = MNIST_MLP(
        batch_size=200,
        hidden1=128,
        hidden2=64,
        lr=0.10,
        lr_decay=0.95,
        max_epoch=12,
        print_iter=50,
        seed=24051220,
    )
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
