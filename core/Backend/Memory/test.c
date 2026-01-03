#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdalign.h>
#include <x86intrin.h>

void* memset_sse2_x86_x64(void* dst, int c, size_t n);
void* memset_avx2_x86_x64(void* dst, int c, size_t n);

#define ITERS 50000

static inline uint64_t rdtsc(void) {
    unsigned aux;
    return __rdtscp(&aux);
}

int main(void) {
    alignas(64) uint8_t buf_libc[1024];
    alignas(64) uint8_t buf_sse [1024];
    alignas(64) uint8_t buf_avx [1024];

    volatile uint8_t sink = 0;

    uint64_t total_libc = 0;
    uint64_t total_sse  = 0;
    uint64_t total_avx  = 0;

    for (size_t n = 0; n <= 1024; n++) {

        uint64_t t0, t1;

        // ---- libc ----
        t0 = rdtsc();
        for (int i = 0; i < ITERS; i++) {
            memset(buf_libc, 0x5A, n);
            sink ^= buf_libc[0];
        }
        t1 = rdtsc();
        total_libc += (t1 - t0);

        // ---- sse2 ----
        t0 = rdtsc();
        for (int i = 0; i < ITERS; i++) {
            memset_sse2_x86_x64(buf_sse, 0x5A, n);
            sink ^= buf_sse[0];
        }
        t1 = rdtsc();
        total_sse += (t1 - t0);

        // ---- avx2 ----
        t0 = rdtsc();
        for (int i = 0; i < ITERS; i++) {
            memset_avx2_x86_x64(buf_avx, 0x5A, n);
            sink ^= buf_avx[0];
        }
        t1 = rdtsc();
        total_avx += (t1 - t0);
    }

    // 注意：n 从 0..512 共 513 次
    const double norm = (double)(ITERS * 513);

    double avg_libc = total_libc / norm;
    double avg_sse  = total_sse  / norm;
    double avg_avx  = total_avx  / norm;

    printf("libc avg cycles : %.3f\n", avg_libc);
    printf("sse2 avg cycles : %.3f\n", avg_sse);
    printf("avx2 avg cycles : %.3f\n", avg_avx);

    printf("speedup sse / libc : %.2fx\n", avg_libc / avg_sse);
    printf("speedup avx / libc : %.2fx\n", avg_libc / avg_avx);

    if (sink == 123) puts("ignore");
    return 0;
}