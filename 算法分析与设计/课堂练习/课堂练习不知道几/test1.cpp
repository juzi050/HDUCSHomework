#include <iostream>
using namespace std;

void siftDown(int arr[], int n, int i) {
    int largest = i;
    int left = 2 * i + 1;
    int right = 2 * i + 2;

    if (left < n && arr[left] > arr[largest])
        largest = left;
    if (right < n && arr[right] > arr[largest])
        largest = right;

    if (largest != i) {
        swap(arr[i], arr[largest]);
        siftDown(arr, n, largest);
    }
}

void buildMaxHeap(int arr[], int n, int i) {
    if (i >= n / 2)
        return;
    buildMaxHeap(arr, n, 2 * i + 1);
    buildMaxHeap(arr, n, 2 * i + 2);
    siftDown(arr, n, i);
}

int main() {
    int arr[] = {4, 1, 3, 2, 16, 9, 10};
    int n = sizeof(arr) / sizeof(arr[0]);
    buildMaxHeap(arr, n, 0);

    for (int i = 0; i < n; i++)
        cout << arr[i] << " ";
    return 0;
}