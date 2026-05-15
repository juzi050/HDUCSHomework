# coding:utf-8
import numpy as np
import struct
import os
import scipy.io
import time

from layers_1 import FullyConnectedLayer, ReLULayer, SoftmaxLossLayer
from layers_2 import ConvolutionalLayer, MaxPoolingLayer, FlattenLayer
from layers_3 import ContentLossLayer, StyleLossLayer


def show_matrix(mat, name):
    #print(name + str(mat.shape) + ' mean %f, std %f' % (mat.mean(), mat.std()))
    pass


def ensure_dir(dir_path):
    if dir_path and (not os.path.exists(dir_path)):
        os.makedirs(dir_path)


def resize_nearest(image, target_height, target_width):
    if image.shape[0] == target_height and image.shape[1] == target_width:
        return image.copy()
    row_index = np.linspace(0, image.shape[0] - 1, target_height).astype(np.int32)
    col_index = np.linspace(0, image.shape[1] - 1, target_width).astype(np.int32)
    return image[row_index][:, col_index]


def save_ppm(image, image_path):
    ensure_dir(os.path.dirname(image_path))
    image = np.clip(image, 0, 255).astype(np.uint8)
    height, width = image.shape[0], image.shape[1]
    with open(image_path, 'wb') as file_handler:
        file_handler.write(('P6\n%d %d\n255\n' % (width, height)).encode('ascii'))
        file_handler.write(image.tobytes())


class VGG19(object):
    def __init__(self, param_path):
        self.param_path = os.path.abspath(param_path)
        self.param_layer_name = [
            'conv1_1', 'relu1_1', 'conv1_2', 'relu1_2', 'pool1',
            'conv2_1', 'relu2_1', 'conv2_2', 'relu2_2', 'pool2',
            'conv3_1', 'relu3_1', 'conv3_2', 'relu3_2', 'conv3_3', 'relu3_3', 'conv3_4', 'relu3_4', 'pool3',
            'conv4_1', 'relu4_1', 'conv4_2', 'relu4_2', 'conv4_3', 'relu4_3', 'conv4_4', 'relu4_4', 'pool4',
            'conv5_1', 'relu5_1', 'conv5_2', 'relu5_2', 'conv5_3', 'relu5_3', 'conv5_4', 'relu5_4', 'pool5'
        ]

    def build_model(self):
        print('Building vgg-19 model...')
        conv_type = 1
        pool_type = 1

        self.layers = {}
        self.layers['conv1_1'] = ConvolutionalLayer(3, 3, 64, 1, 1, conv_type)
        self.layers['relu1_1'] = ReLULayer()
        self.layers['conv1_2'] = ConvolutionalLayer(3, 64, 64, 1, 1, conv_type)
        self.layers['relu1_2'] = ReLULayer()
        self.layers['pool1'] = MaxPoolingLayer(2, 2, pool_type)

        self.layers['conv2_1'] = ConvolutionalLayer(3, 64, 128, 1, 1, conv_type)
        self.layers['relu2_1'] = ReLULayer()
        self.layers['conv2_2'] = ConvolutionalLayer(3, 128, 128, 1, 1, conv_type)
        self.layers['relu2_2'] = ReLULayer()
        self.layers['pool2'] = MaxPoolingLayer(2, 2, pool_type)

        self.layers['conv3_1'] = ConvolutionalLayer(3, 128, 256, 1, 1, conv_type)
        self.layers['relu3_1'] = ReLULayer()
        self.layers['conv3_2'] = ConvolutionalLayer(3, 256, 256, 1, 1, conv_type)
        self.layers['relu3_2'] = ReLULayer()
        self.layers['conv3_3'] = ConvolutionalLayer(3, 256, 256, 1, 1, conv_type)
        self.layers['relu3_3'] = ReLULayer()
        self.layers['conv3_4'] = ConvolutionalLayer(3, 256, 256, 1, 1, conv_type)
        self.layers['relu3_4'] = ReLULayer()
        self.layers['pool3'] = MaxPoolingLayer(2, 2, pool_type)

        self.layers['conv4_1'] = ConvolutionalLayer(3, 256, 512, 1, 1, conv_type)
        self.layers['relu4_1'] = ReLULayer()
        self.layers['conv4_2'] = ConvolutionalLayer(3, 512, 512, 1, 1, conv_type)
        self.layers['relu4_2'] = ReLULayer()
        self.layers['conv4_3'] = ConvolutionalLayer(3, 512, 512, 1, 1, conv_type)
        self.layers['relu4_3'] = ReLULayer()
        self.layers['conv4_4'] = ConvolutionalLayer(3, 512, 512, 1, 1, conv_type)
        self.layers['relu4_4'] = ReLULayer()
        self.layers['pool4'] = MaxPoolingLayer(2, 2, pool_type)

        self.layers['conv5_1'] = ConvolutionalLayer(3, 512, 512, 1, 1, conv_type)
        self.layers['relu5_1'] = ReLULayer()
        self.layers['conv5_2'] = ConvolutionalLayer(3, 512, 512, 1, 1, conv_type)
        self.layers['relu5_2'] = ReLULayer()
        self.layers['conv5_3'] = ConvolutionalLayer(3, 512, 512, 1, 1, conv_type)
        self.layers['relu5_3'] = ReLULayer()
        self.layers['conv5_4'] = ConvolutionalLayer(3, 512, 512, 1, 1, conv_type)
        self.layers['relu5_4'] = ReLULayer()
        self.layers['pool5'] = MaxPoolingLayer(2, 2, pool_type)

        self.update_layer_list = []
        for layer_name in self.layers.keys():
            if 'conv' in layer_name:
                self.update_layer_list.append(layer_name)

    def init_model(self):
        print('Initializing parameters of each layer in vgg-19...')
        for layer_name in self.update_layer_list:
            self.layers[layer_name].init_param()

    def load_model(self):
        if not os.path.exists(self.param_path):
            raise IOError('未找到 VGG19 权重文件：%s' % self.param_path)
        print('Loading parameters from file ' + self.param_path)
        params = scipy.io.loadmat(self.param_path)
        self.image_mean = params['meta']['normalization'][0][0]['averageImage'][0][0]
        self.image_mean = np.mean(self.image_mean, axis=(0, 1)).astype(np.float32)
        print('Get image mean: ' + str(self.image_mean))
        for idx in range(37):
            if 'conv' in self.param_layer_name[idx]:
                weight, bias = params['layers'][0][idx]['weights'][0][0][0]
                weight = np.transpose(weight, [2, 0, 1, 3]).astype(np.float32)
                bias = bias.reshape(-1).astype(np.float32)
                self.layers[self.param_layer_name[idx]].load_param(weight, bias)

    def load_image(self, image_dir, image_height, image_width):
        image_dir = os.path.abspath(image_dir)
        if not os.path.exists(image_dir):
            raise IOError('未找到输入图像数组：%s' % image_dir)
        print('Loading and preprocessing image from ' + image_dir)
        image = np.load(image_dir)
        image_shape = image.shape
        image = resize_nearest(image, image_height, image_width).astype(np.float32)
        image -= self.image_mean
        image = np.reshape(image, [1] + list(image.shape))
        image = np.transpose(image, [0, 3, 1, 2])
        return image, image_shape

    def save_image(self, input_image, image_shape, image_dir):
        image = np.transpose(input_image, [0, 2, 3, 1])
        image = image[0] + self.image_mean
        image = np.clip(image, 0, 255).astype(np.uint8)
        image = resize_nearest(image, image_shape[0], image_shape[1])
        save_ppm(image, image_dir)

    def forward(self, input_image, layer_list):
        current = input_image
        layer_forward = {}
        for idx in range(len(self.param_layer_name)):
            current = self.layers[self.param_layer_name[idx]].forward(current)
            if self.param_layer_name[idx] in layer_list:
                layer_forward[self.param_layer_name[idx]] = current.copy()
        return layer_forward

    def backward(self, dloss, layer_name):
        layer_idx = list.index(self.param_layer_name, layer_name)
        for idx in range(layer_idx, -1, -1):
            dloss = self.layers[self.param_layer_name[idx]].backward(dloss)
            show_matrix(dloss, self.param_layer_name[idx] + ' dloss ')
        return dloss

    def backward_from_layer_map(self, layer_diff_map):
        current_diff = None
        for idx in range(len(self.param_layer_name) - 1, -1, -1):
            layer_name = self.param_layer_name[idx]
            if layer_name in layer_diff_map:
                if current_diff is None:
                    current_diff = layer_diff_map[layer_name]
                else:
                    current_diff = current_diff + layer_diff_map[layer_name]
            if current_diff is None:
                continue
            current_diff = self.layers[layer_name].backward(current_diff)
        return current_diff


def get_random_img(content_image, noise):
    noise_image = np.random.uniform(-20, 20, content_image.shape).astype(np.float32)
    random_img = noise_image * noise + content_image * (1 - noise)
    return random_img.astype(np.float32)


class AdamOptimizer(object):
    def __init__(self, lr, diff_shape):
        self.beta1 = 0.9
        self.beta2 = 0.999
        self.eps = 1e-8
        self.lr = lr
        self.mt = np.zeros(diff_shape, dtype=np.float32)
        self.vt = np.zeros(diff_shape, dtype=np.float32)
        self.step = 0

    def update(self, input, grad):
        self.step += 1
        self.mt = self.beta1 * self.mt + (1 - self.beta1) * grad
        self.vt = self.beta2 * self.vt + (1 - self.beta2) * np.square(grad)
        mt_hat = self.mt / (1 - self.beta1 ** self.step)
        vt_hat = self.vt / (1 - self.beta2 ** self.step)
        output = input - self.lr * mt_hat / (np.sqrt(vt_hat) + self.eps)
        return output


if __name__ == '__main__':
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    PROJECT_DIR = os.path.dirname(BASE_DIR)
    RESULT_DIR = os.path.join(PROJECT_DIR, 'result')
    OUTPUT_DIR = os.path.join(BASE_DIR, 'output')
    CONTENT_ARRAY_PATH = os.path.join(BASE_DIR, 'weinisi.npy')
    STYLE_ARRAY_PATH = os.path.join(BASE_DIR, 'style.npy')
    PARAM_PATH = os.environ.get('STYLE_TRANSFER_VGG_PATH', os.path.join(PROJECT_DIR, 'imagenet-vgg-verydeep-19.mat'))
    SAVE_EVERY = int(os.environ.get('STYLE_TRANSFER_SAVE_EVERY', '20'))

    CONTENT_LOSS_LAYERS = ['relu4_2']
    STYLE_LOSS_LAYERS = ['relu1_1', 'relu2_1', 'relu3_1', 'relu4_1', 'relu5_1']
    NOISE = float(os.environ.get('STYLE_TRANSFER_NOISE', '0.5'))
    ALPHA = float(os.environ.get('STYLE_TRANSFER_ALPHA', '1'))
    BETA = float(os.environ.get('STYLE_TRANSFER_BETA', '500'))
    TRAIN_STEP = int(os.environ.get('STYLE_TRANSFER_STEPS', '2001'))
    LEARNING_RATE = float(os.environ.get('STYLE_TRANSFER_LR', '1.0'))
    IMAGE_HEIGHT = int(os.environ.get('STYLE_TRANSFER_HEIGHT', '192'))
    IMAGE_WIDTH = int(os.environ.get('STYLE_TRANSFER_WIDTH', '320'))

    ensure_dir(RESULT_DIR)
    ensure_dir(OUTPUT_DIR)

    vgg = VGG19(PARAM_PATH)
    vgg.build_model()
    vgg.init_model()
    vgg.load_model()
    content_loss_layer = ContentLossLayer()
    style_loss_layer = StyleLossLayer()
    adam_optimizer = AdamOptimizer(LEARNING_RATE, [1, 3, IMAGE_HEIGHT, IMAGE_WIDTH])

    content_image, content_shape = vgg.load_image(CONTENT_ARRAY_PATH, IMAGE_HEIGHT, IMAGE_WIDTH)
    style_image, _ = vgg.load_image(STYLE_ARRAY_PATH, IMAGE_HEIGHT, IMAGE_WIDTH)
    content_layers = vgg.forward(content_image, CONTENT_LOSS_LAYERS)
    style_layers = vgg.forward(style_image, STYLE_LOSS_LAYERS)
    transfer_image = get_random_img(content_image, NOISE)

    best_loss = None
    best_step = -1
    best_output_path = os.path.join(RESULT_DIR, 'best_output.ppm')
    summary_path = os.path.join(RESULT_DIR, 'summary.txt')

    for step in range(TRAIN_STEP):
        transfer_layers = vgg.forward(transfer_image, CONTENT_LOSS_LAYERS + STYLE_LOSS_LAYERS)
        content_loss = []
        style_loss = []
        layer_diff_map = {}
        for layer in CONTENT_LOSS_LAYERS:
            current_loss = content_loss_layer.forward(transfer_layers[layer], content_layers[layer])
            content_loss.append(current_loss)
            dloss = content_loss_layer.backward(transfer_layers[layer], content_layers[layer])
            layer_diff_map[layer] = layer_diff_map.get(layer, 0) + ALPHA * dloss / len(CONTENT_LOSS_LAYERS)
        for layer in STYLE_LOSS_LAYERS:
            current_loss = style_loss_layer.forward(transfer_layers[layer], style_layers[layer])
            style_loss.append(current_loss)
            dloss = style_loss_layer.backward(transfer_layers[layer], style_layers[layer])
            layer_diff_map[layer] = layer_diff_map.get(layer, 0) + BETA * dloss / len(STYLE_LOSS_LAYERS)
        total_loss = ALPHA * np.mean(content_loss) + BETA * np.mean(style_loss)
        image_diff = vgg.backward_from_layer_map(layer_diff_map)
        transfer_image = adam_optimizer.update(transfer_image, image_diff.astype(np.float32))

        if (best_loss is None) or (total_loss < best_loss):
            best_loss = total_loss
            best_step = step
            vgg.save_image(transfer_image, content_shape, best_output_path)

        if SAVE_EVERY > 0 and step % SAVE_EVERY == 0:
            print('Step %d, loss = %f' % (step, total_loss), np.array(content_loss), np.array(style_loss))
            vgg.save_image(transfer_image, content_shape, os.path.join(OUTPUT_DIR, 'output_%04d.ppm' % step))

    with open(summary_path, 'w', encoding='utf-8') as file_handler:
        file_handler.write('best_step=%d\n' % best_step)
        file_handler.write('best_loss=%f\n' % best_loss)
        file_handler.write('train_step=%d\n' % TRAIN_STEP)
        file_handler.write('alpha=%s\n' % ALPHA)
        file_handler.write('beta=%s\n' % BETA)
        file_handler.write('learning_rate=%s\n' % LEARNING_RATE)
        file_handler.write('noise=%s\n' % NOISE)
        file_handler.write('image_height=%d\n' % IMAGE_HEIGHT)
        file_handler.write('image_width=%d\n' % IMAGE_WIDTH)
