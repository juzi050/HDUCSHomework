#include <iostream>
#include <algorithm>
using namespace std;

int main() {
    int n;
    cin >> n;

    int dp[101] = {0};
    for (int i = 1; i <= n; ++i) {
        int row[101];
        for (int j = 1; j <= i; ++j) {
            cin >> row[j];
        }
        for (int j = i; j >= 1; --j) {
            if (j == 1) {
                dp[j] = dp[j] + row[j];
            } else if (j == i) {
                dp[j] = dp[j - 1] + row[j];
            } else {
                dp[j] = max(dp[j - 1], dp[j]) + row[j];
            }
        }
    }

    int ans = 0;
    for (int i = 1; i <= n; ++i) {
        ans = max(ans, dp[i]);
    }
    cout << ans;
    return 0;
}
