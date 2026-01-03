#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <inttypes.h>
#include <string.h>

// 声明汇编函数
extern void* memset_avx2_x86_x64(void* dest, unsigned char value, int count);

void check_memory(unsigned char* buf, int count, unsigned char expected) {
    for (int i = 0; i < count; i++) {
        if (buf[i] != expected) {
            printf("Memory check failed at offset 0x%X: got 0x%02X, expected 0x%02X\n",
                    i, buf[i], expected);
            return;
        }
    }
    printf("Memory check passed for %d bytes\n", count);
}

int main() {
    const int GUARD = 16; // 哨兵区大小
    const int BUF_SIZE = 0x400000; // 4 MB

    // 分配内存：前后各加16字节保护区
    unsigned char* raw = malloc(BUF_SIZE + 2 * GUARD);
    if (!raw) {
        perror("malloc failed");
        return 1;
    }

    unsigned char* buf = raw + GUARD;

    // 初始化哨兵区
    memset(raw, 0xFE, GUARD);                // 前哨兵
    memset(buf + BUF_SIZE, 0xFE, GUARD);     // 后哨兵

    // --- 小块测试 ---
    printf("Testing small block...\n");
    void* r1 = memset_avx2_x86_x64(buf, 0xAA, 8);
    printf("Returned pointer: %p, expected: %p\n", r1, buf);
    check_memory(buf, 8, 0xAA);

    // 检查哨兵是否被改写
    for (int i = 0; i < GUARD; i++) {
        if (raw[i] != 0xFE) {
            printf("Front guard overwritten at offset %d\n", i);
        }
        if (buf[BUF_SIZE + i] != 0xFE) {
            printf("Back guard overwritten at offset %d\n", i);
        }
    }

    // --- 大块测试 ---
    printf("\nTesting large block...\n");
    void* r2 = memset_avx2_x86_x64(buf, 0x55, BUF_SIZE); // 超过阈值
    printf("Returned pointer: %p (should be special value if your asm sets it)\n", r2);
    check_memory(buf, BUF_SIZE, 0x55);

    // 检查哨兵
    for (int i = 0; i < GUARD; i++) {
        if (raw[i] != 0xFE) {
            printf("Front guard overwritten at offset %d\n", i);
        }
        if (buf[BUF_SIZE + i] != 0xFE) {
            printf("Back guard overwritten at offset %d\n", i);
        }
    }

    free(raw);
    return 0;
}