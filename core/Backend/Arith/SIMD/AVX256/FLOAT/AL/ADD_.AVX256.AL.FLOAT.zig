// ADD AVX256 AL FLOAT

const c = @cImport({
    @cInclude("immintrin.h");
});

pub const impl = struct {
    pub inline fn avx256_f16_aligned_add_vectorized(comptime HasTail: bool, a: []const f16, b: []const f16, result: []f16) void {
        @setRuntimeSafety(false);
        @setFloatMode(.optimized);
        const len = a.len;
        var i: usize = 0;

        while (i + 32 <= len) : (i += 32) {
            const a0 = c._mm_load_si128(@ptrCast(&a[i +  0]));
            const a1 = c._mm_load_si128(@ptrCast(&a[i +  8]));
            const a2 = c._mm_load_si128(@ptrCast(&a[i + 16]));
            const a3 = c._mm_load_si128(@ptrCast(&a[i + 24]));

            const b0 = c._mm_load_si128(@ptrCast(&b[i +  0]));
            const b1 = c._mm_load_si128(@ptrCast(&b[i +  8]));
            const b2 = c._mm_load_si128(@ptrCast(&b[i + 16]));
            const b3 = c._mm_load_si128(@ptrCast(&b[i + 24]));

            const va0 = c._mm256_cvtph_ps(a0);
            const va1 = c._mm256_cvtph_ps(a1);
            const va2 = c._mm256_cvtph_ps(a2);
            const va3 = c._mm256_cvtph_ps(a3);

            const vb0 = c._mm256_cvtph_ps(b0);
            const vb1 = c._mm256_cvtph_ps(b1);
            const vb2 = c._mm256_cvtph_ps(b2);
            const vb3 = c._mm256_cvtph_ps(b3);

            const vr0 = c._mm256_add_ps(va0, vb0);
            const vr1 = c._mm256_add_ps(va1, vb1);
            const vr2 = c._mm256_add_ps(va2, vb2);
            const vr3 = c._mm256_add_ps(va3, vb3);

            c._mm_store_si128(@ptrCast(&result[i +  0]), c._mm256_cvtps_ph(vr0, c._MM_FROUND_TO_NEAREST_INT));
            c._mm_store_si128(@ptrCast(&result[i +  8]), c._mm256_cvtps_ph(vr1, c._MM_FROUND_TO_NEAREST_INT));
            c._mm_store_si128(@ptrCast(&result[i + 16]), c._mm256_cvtps_ph(vr2, c._MM_FROUND_TO_NEAREST_INT));
            c._mm_store_si128(@ptrCast(&result[i + 24]), c._mm256_cvtps_ph(vr3, c._MM_FROUND_TO_NEAREST_INT));
        }

        if (comptime HasTail) {
            while (i < len) : (i += 1) {
                result[i] = a[i] + b[i];
            }
        }
    }

    pub inline fn avx256_f32_aligned_add_vectorized(comptime HasTail: bool, a: []const f32, b: []const f32, result: []f32) void {
        @setRuntimeSafety(false);
        @setFloatMode(.optimized);
        const len = a.len;
        var i: usize = 0;

        while (i + 32 <= len) : (i += 32) {
            const va0 = c._mm256_load_ps(&a[i + 0]);
            const va1 = c._mm256_load_ps(&a[i + 8]);
            const va2 = c._mm256_load_ps(&a[i + 16]);
            const va3 = c._mm256_load_ps(&a[i + 24]);

            const vb0 = c._mm256_load_ps(&b[i + 0]);
            const vb1 = c._mm256_load_ps(&b[i + 8]);
            const vb2 = c._mm256_load_ps(&b[i + 16]);
            const vb3 = c._mm256_load_ps(&b[i + 24]);

            const vr0 = c._mm256_add_ps(va0, vb0);
            const vr1 = c._mm256_add_ps(va1, vb1);
            const vr2 = c._mm256_add_ps(va2, vb2);
            const vr3 = c._mm256_add_ps(va3, vb3);

            c._mm256_store_ps(&result[i + 0], vr0);
            c._mm256_store_ps(&result[i + 8], vr1);
            c._mm256_store_ps(&result[i + 16], vr2);
            c._mm256_store_ps(&result[i + 24], vr3);
        }

        if (comptime HasTail) {
            while (i < len) : (i += 1) {
                result[i] = a[i] + b[i];
            }
        }
    }

    pub inline fn avx256_f64_aligned_add_vectorized(comptime HasTail: bool, a: []const f64, b: []const f64, result: []f64) void {
        @setRuntimeSafety(false);
        @setFloatMode(.optimized);
        const len = a.len;
        var i: usize = 0;

        while (i + 8 <= len) : (i += 8) {
            var va = c._mm256_load_pd(&a[i]);
            var vb = c._mm256_load_pd(&b[i]);
            var vr = c._mm256_add_pd(va, vb);
            c._mm256_store_pd(&result[i], vr);

            va = c._mm256_load_pd(&a[i + 4]);
            vb = c._mm256_load_pd(&b[i + 4]);
            vr = c._mm256_add_pd(va, vb);
            c._mm256_store_pd(&result[i + 4], vr);
        }

        if (comptime HasTail) {
            while (i < len) : (i += 1) {
                result[i] = a[i] + b[i];
            }
        }
    }
};