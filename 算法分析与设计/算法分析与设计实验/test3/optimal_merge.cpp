#include <iostream>
#include <queue>
#include <vector>
using namespace std;

int main() {
    int k;
    cin >> k;

    // 最小堆存储各序列长度
    priority_queue<int, vector<int>, greater<int>> minHeap;
    for (int i = 0; i < k; ++i) {
        int len;
        cin >> len;
        minHeap.push(len);
    }

    int totalComparisons = 0;

    // 每次合并最短的两个序列
    while (minHeap.size() > 1) {
        int a = minHeap.top();
        minHeap.pop();
        int b = minHeap.top();
        minHeap.pop();

        int cost = a + b - 1;        // 合并比较次数
        totalComparisons += cost;

        minHeap.push(a + b);         // 合并后的新序列长度
    }

    cout << "最少总比较次数: " << totalComparisons << endl;
    return 0;
}
