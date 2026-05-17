#include <cmath>
#include <algorithm>
#include <functional>
#include <iostream>
#include <queue>
#include <utility>
#include <vector>

using namespace std;

struct HeapNode {
    int value;
    int segmentIndex;
    int elementIndex;

    bool operator>(const HeapNode& other) const {
        return value > other.value;
    }
};

void sqrtMergeSort(vector<int>& a, int left, int right) {
    int length = right - left;
    if (length <= 1) {
        return;
    }

    int k = static_cast<int>(ceil(sqrt(length)));
    int segmentSize = static_cast<int>(ceil(static_cast<double>(length) / k));

    vector<pair<int, int>> segments;
    for (int start = left; start < right; start += segmentSize) {
        int end = min(start + segmentSize, right);
        segments.push_back({start, end});
        sqrtMergeSort(a, start, end);
    }

    priority_queue<HeapNode, vector<HeapNode>, greater<HeapNode>> minHeap;
    for (int i = 0; i < static_cast<int>(segments.size()); ++i) {
        int start = segments[i].first;
        if (start < segments[i].second) {
            minHeap.push({a[start], i, start});
        }
    }

    vector<int> merged;
    merged.reserve(length);
    while (!minHeap.empty()) {
        HeapNode current = minHeap.top();
        minHeap.pop();
        merged.push_back(current.value);

        int nextIndex = current.elementIndex + 1;
        if (nextIndex < segments[current.segmentIndex].second) {
            minHeap.push({a[nextIndex], current.segmentIndex, nextIndex});
        }
    }

    for (int i = 0; i < length; ++i) {
        a[left + i] = merged[i];
    }
}

void printArray(const vector<int>& a) {
    for (int i = 0; i < static_cast<int>(a.size()); ++i) {
        if (i > 0) {
            cout << ' ';
        }
        cout << a[i];
    }
    cout << '\n';
}

int main() {
    int n;
    if (!(cin >> n)) {
        return 0;
    }

    vector<int> a(n);
    for (int i = 0; i < n; ++i) {
        cin >> a[i];
    }

    cout << "排序前: ";
    printArray(a);

    sqrtMergeSort(a, 0, n);

    cout << "排序后: ";
    printArray(a);

    return 0;
}
