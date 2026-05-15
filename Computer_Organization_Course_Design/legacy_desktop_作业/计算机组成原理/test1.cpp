#include <stdio.h>

// 通用函数：打印任意变量的内存二进制编码
void print_memory(void* ptr, size_t size) {
    unsigned char* p = (unsigned char*)ptr;
    // 小端模式（x86/x64）：从高地址到低地址打印，符合人类阅读习惯（MSB在前）
    for (int i = size - 1; i >= 0; i--) {
        unsigned char byte = p[i];
        // 打印当前字节的8位（从高位到低位）
        for (int j = 7; j >= 0; j--) {
            printf("%d", (byte >> j) & 1);
        }
        printf(" "); // 字节之间用空格分隔
    }
    printf("\n");
}

int main() {
    // 整数类型（补码）
    int i1 = 0;
    int i2 = -1;
    int i3 = 17;
    int i4 = -17;

    // 单精度浮点数（IEEE 754）
    float f1 = 0.0f;
    float f2 = -1.0f;
    float f3 = 17.0f;
    float f4 = -17.0f;

    // 双精度浮点数（IEEE 754）
    double d1 = 0.0;
    double d2 = -1.0;
    double d3 = 17.0;
    double d4 = -17.0;

    // 打印结果
    printf("=== int 类型 (4字节, 补码) ===\n");
    printf("i1 = 0:\t");    print_memory(&i1, sizeof(i1));
    printf("i2 = -1:\t");   print_memory(&i2, sizeof(i2));
    printf("i3 = 17:\t");   print_memory(&i3, sizeof(i3));
    printf("i4 = -17:\t");  print_memory(&i4, sizeof(i4));

    printf("\n=== float 类型 (4字节, IEEE 754单精度) ===\n");
    printf("f1 = 0.0f:\t");  print_memory(&f1, sizeof(f1));
    printf("f2 = -1.0f:\t"); print_memory(&f2, sizeof(f2));
    printf("f3 = 17.0f:\t"); print_memory(&f3, sizeof(f3));
    printf("f4 = -17.0f:\t");print_memory(&f4, sizeof(f4));

    printf("\n=== double 类型 (8字节, IEEE 754双精度) ===\n");
    printf("d1 = 0.0:\t");   print_memory(&d1, sizeof(d1));
    printf("d2 = -1.0:\t");  print_memory(&d2, sizeof(d2));
    printf("d3 = 17.0:\t");  print_memory(&d3, sizeof(d3));
    printf("d4 = -17.0:\t"); print_memory(&d4, sizeof(d4));

    return 0;
}