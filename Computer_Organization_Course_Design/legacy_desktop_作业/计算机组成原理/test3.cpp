#include <iostream>
#include <iomanip>
using namespace std;

int main()
{
    short si = -1234;
    int i = si;
    unsigned short usi = si;
    unsigned int ui = usi;

    int y = 123456789;
    float f1 = y;
    double d = 5.8;
    int z = (int) d;
    float f2 = (float)d;

    cout << "======== 教材表3.10 数据转换验证结果 ========" << endl;
    cout << "short si = -1234;          十进制: " << si << "\t 十六进制: 0x" << hex << (unsigned short)si << dec << endl;
    cout << "int i = si;                十进制: " << i << "\t 十六进制: 0x" << hex << i << dec << endl;
    cout << "unsigned short usi = si;   十进制: " << usi << "\t 十六进制: 0x" << hex << usi << dec << endl;
    cout << "unsigned int ui = usi;     十进制: " << ui << "\t 十六进制: 0x" << hex << ui << dec << endl;
    cout << "------------------------------------------------" << endl;
    cout << "int y = 123456789;         十进制: " << y << endl;
    cout << "float f1 = y;              十进制: " << fixed << setprecision(1) << f1 << endl;
    cout << "double d = 5.8;            十进制: " << d << endl;
    cout << "int z = (int)d;            十进制: " << z << endl;
    cout << "float f2 = (float)d;       十进制: " << f2 << endl;

    return 0;
}