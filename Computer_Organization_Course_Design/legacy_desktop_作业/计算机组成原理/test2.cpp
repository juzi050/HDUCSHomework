#include <iostream>
#include <iomanip> // 用于控制输出精度

using namespace std;

int main() {
    double sum = 0.0;
    int count = 1000000; // 100万

    for (int i = 0; i < count; i++) {
        sum += 0.1;
    }

    cout << "累加 " << count << " 个 0.1 的结果: " 
         << setprecision(15) << sum << endl;
    return 0;
}