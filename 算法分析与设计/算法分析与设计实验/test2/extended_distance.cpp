#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <cstdlib>

using namespace std;

int main() {
    string A, B;
    int k;

    getline(cin, A);
    getline(cin, B);
    cin >> k;

    int m = A.length();
    int n = B.length();

    // dp[i][j] = val(i, j): A[0..i) 与 B[0..j) 的扩展距离
    vector<vector<int>> dp(m + 1, vector<int>(n + 1, 0));

    // 边界条件
    for (int i = 1; i <= m; i++)
        dp[i][0] = dp[i - 1][0] + k;
    for (int j = 1; j <= n; j++)
        dp[0][j] = dp[0][j - 1] + k;

    // 动态规划递推
    for (int i = 1; i <= m; i++) {
        for (int j = 1; j <= n; j++) {
            int dist = abs(A[i - 1] - B[j - 1]);
            dp[i][j] = min({dp[i - 1][j] + k,
                            dp[i][j - 1] + k,
                            dp[i - 1][j - 1] + dist});
        }
    }

    cout << dp[m][n] << endl;
    return 0;
}
