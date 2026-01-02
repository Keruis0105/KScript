#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <wchar.h>
#include <time.h>

/* 声明汇编函数 */
#ifdef _WIN32
#define ASM_CALL_CONV __fastcall
#else
#define ASM_CALL_CONV
#endif

// 8-bit
size_t ASM_CALL_CONV strlen_8bit_sse2_x86_x64(const char* ptr);
size_t ASM_CALL_CONV strlen_8bit_avx2_x86_x64(const char* ptr);

// 16-bit
size_t ASM_CALL_CONV strlen_16bit_sse2_x86_x64(const uint16_t* ptr);
size_t ASM_CALL_CONV strlen_16bit_avx2_x86_x64(const uint16_t* ptr);

// 32-bit
size_t ASM_CALL_CONV strlen_32bit_sse2_x86_x64(const uint32_t* ptr);
size_t ASM_CALL_CONV strlen_32bit_avx2_x86_x64(const uint32_t* ptr);

/* 测试时间函数 */
static double benchmark8(size_t (*func)(const char*), const char* ptr, int iters, size_t* out_len) {
    clock_t start = clock();
    size_t sum = 0;
    for (int i = 0; i < iters; ++i) sum += func(ptr);
    if (out_len) *out_len = sum;
    return (double)(clock() - start) / CLOCKS_PER_SEC * 1000.0;
}

static double benchmark16(size_t (*func)(const uint16_t*), const uint16_t* ptr, int iters, size_t* out_len) {
    clock_t start = clock();
    size_t sum = 0;
    for (int i = 0; i < iters; ++i) sum += func(ptr);
    if (out_len) *out_len = sum;
    return (double)(clock() - start) / CLOCKS_PER_SEC * 1000.0;
}

static double benchmark32(size_t (*func)(const uint32_t*), const uint32_t* ptr, int iters, size_t* out_len) {
    clock_t start = clock();
    size_t sum = 0;
    for (int i = 0; i < iters; ++i) sum += func(ptr);
    if (out_len) *out_len = sum;
    return (double)(clock() - start) / CLOCKS_PER_SEC * 1000.0;
}

int main(void) {
    const char* str8  = "hello world 1234567890abcdefghijklmnopqrstuvwxyz";
    const uint16_t str16[] = u"hello world 1234567890abcdefghijklmnopqrstuvwxyz";
    const uint32_t str32[] = U"hello world 1234567890abcdefghijklmnopqrstuvwxyz";

    const int iters = 10000000;
    size_t len;

    // 8-bit
    printf("=== 8-bit strlen ===\n");
    printf("SSE2: %zu\n", strlen_8bit_sse2_x86_x64(str8));
    printf("AVX2: %zu\n", strlen_8bit_avx2_x86_x64(str8));
    printf("LIBC: %zu\n", strlen(str8));
    printf("Timing...\n");
    double t_sse2 = benchmark8(strlen_8bit_sse2_x86_x64, str8, iters, &len);
    double t_avx2 = benchmark8(strlen_8bit_avx2_x86_x64, str8, iters, &len);
    double t_libc = benchmark8((size_t(*)(const char*))strlen, str8, iters, &len);
    printf("SSE2 time: %.3f ms\nAVX2 time: %.3f ms\nLIBC time: %.3f ms\n", t_sse2, t_avx2, t_libc);
    printf("Speedup SSE2/AVX2: %.2fx\nSpeedup LIBC/AVX2: %.2fx\n\n", t_sse2/t_avx2, t_libc/t_avx2);

    // 16-bit
    printf("=== 16-bit strlen ===\n");
    printf("SSE2: %zu\n", strlen_16bit_sse2_x86_x64(str16));
    printf("AVX2: %zu\n", strlen_16bit_avx2_x86_x64(str16));
    printf("LIBC: %zu\n", wcslen((const wchar_t*)str16));
    t_sse2 = benchmark16(strlen_16bit_sse2_x86_x64, str16, iters, &len);
    t_avx2 = benchmark16(strlen_16bit_avx2_x86_x64, str16, iters, &len);
    t_libc = benchmark16((size_t(*)(const uint16_t*))wcslen, (const uint16_t*)str16, iters, &len);
    printf("SSE2 time: %.3f ms\nAVX2 time: %.3f ms\nLIBC time: %.3f ms\n", t_sse2, t_avx2, t_libc);
    printf("Speedup SSE2/AVX2: %.2fx\nSpeedup LIBC/AVX2: %.2fx\n\n", t_sse2/t_avx2, t_libc/t_avx2);

    // 32-bit
    printf("=== 32-bit strlen ===\n");
    printf("SSE2: %zu\n", strlen_32bit_sse2_x86_x64(str32));
    printf("AVX2: %zu\n", strlen_32bit_avx2_x86_x64(str32));
    // 没有标准库直接支持 char32_t，所以这里用 uint32_t cast 后用 wcslen (仅在 Linux wchar_t=4)
#ifdef __linux__
    printf("LIBC: %zu\n", wcslen((const wchar_t*)str32));
#endif
    t_sse2 = benchmark32(strlen_32bit_sse2_x86_x64, str32, iters, &len);
    t_avx2 = benchmark32(strlen_32bit_avx2_x86_x64, str32, iters, &len);
#ifdef __linux__
    t_libc = benchmark32((size_t(*)(const uint32_t*))wcslen, str32, iters, &len);
#else
    t_libc = 0.0;
#endif
    printf("SSE2 time: %.3f ms\nAVX2 time: %.3f ms\n", t_sse2, t_avx2);
#ifdef __linux__
    printf("LIBC time: %.3f ms\n", t_libc);
#endif
    printf("Speedup SSE2/AVX2: %.2fx\n", t_sse2/t_avx2);
#ifdef __linux__
    printf("Speedup LIBC/AVX2: %.2fx\n\n", t_libc/t_avx2);
#endif

    return 0;
}