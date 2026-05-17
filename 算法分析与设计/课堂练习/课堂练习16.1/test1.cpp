#include <algorithm>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <vector>

using namespace std;

struct Program {
    long long a;
    long long b;
    long long key;
    int id;
};

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

    vector<Program> programs(n);
    long long sumA = 0;
    for (int i = 0; i < n; ++i) {
        *in >> programs[i].a >> programs[i].b;
        programs[i].key = programs[i].a * programs[i].b;
        programs[i].id = i + 1;
        sumA += programs[i].a;
    }

    sort(programs.begin(), programs.end(), [](const Program &lhs, const Program &rhs) {
        if (lhs.key != rhs.key) {
            return lhs.key < rhs.key;
        }
        return lhs.id < rhs.id;
    });

    for (int i = 0; i < n; ++i) {
        if (i) {
            *out << ' ';
        }
        *out << programs[i].id;
    }
    *out << '\n';

    long double prefix = 0.0L;
    long double total = 0.0L;
    for (const auto &program : programs) {
        prefix += static_cast<long double>(program.key);
        total += prefix;
    }

    *out << fixed << setprecision(6) << (total / static_cast<long double>(sumA)) << '\n';

    return 0;
}
