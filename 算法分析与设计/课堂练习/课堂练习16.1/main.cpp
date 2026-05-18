#include <algorithm>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <vector>

using namespace std;


int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    ifstream fin("input.txt");
    ofstream fout;

    istream *in = &cin;
    ostream *out = &cout;

    if (fin.is_open()) {
        in = &fin;
        fout.open("output.txt");
        if (fout.is_open()) {
            out = &fout;
        }
    }

    int n;
    if (!(*in >> n)) {
        return 0;
    }

    vector<long double> weight(n);
    long double totalWeight = 0.0L;
    for (int i = 0; i < n; ++i) {
        *in >> weight[i];
        totalWeight += weight[i];
    }

    sort(weight.begin(), weight.end(), greater<long double>());

    long double leftSum = 0.0L;
    long double rightSum = 0.0L;
    long double cost = 0.0L;

    for (int i = n - 1; i >= 1; --i) {
        long double current = weight[i];
        long double sideSum;

        if (leftSum <= rightSum) {
            leftSum += current;
            sideSum = leftSum;
        } else {
            rightSum += current;
            sideSum = rightSum;
        }

        cost += sideSum * (totalWeight - sideSum);
    }

    long double answer = cost / totalWeight / totalWeight;
    *out << fixed << setprecision(6) << answer << '\n';

    return 0;
}
