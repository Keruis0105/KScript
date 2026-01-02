// DIV AVX256 AL FLOAT

const c = @cImport({
    @cInclude("immintrin.h");
});

pub const impl = struct {
    pub inline fn avx256_f16_aligned_div_vectorized(a: []const f16, b: []const f16, result: []f16) void {
        const len = a.len;
        var i: usize = 0;

        while (i + 8 <= len) : (i += 8) {
            const va_h = c._mm_load_si128(@ptrCast(&a[i]));
            const vb_h = c._mm_load_si128(@ptrCast(&b[i]));

            const va = c._mm256_cvtph_ps(va_h);
            const vb = c._mm256_cvtph_ps(vb_h);

            const vr = c._mm256_div_ps(va, vb);

            const vr_h = c._mm256_cvtps_ph(vr, c._MM_FROUND_TO_NEAREST_INT);

            c._mm_store_si128(@ptrCast(&result[i]), vr_h,);
        }

        while (i < len) : (i += 1) {
            result[i] = a[i] + b[i];
        }
    }

    pub inline fn avx256_f32_aligned_div_vectorized(a: []const f32, b: []const f32, result: []f32) void {
        const len = a.len;
        var i: usize = 0;

        while (i + 16 <= len) : (i += 16) {
            var va = c._mm256_load_ps(&a[i]);
            var vb = c._mm256_load_ps(&b[i]);
            var vr = c._mm256_div_ps(va, vb);
            c._mm256_store_ps(&result[i], vr);

            va = c._mm256_load_ps(&a[i + 8]);
            vb = c._mm256_load_ps(&b[i + 8]);
            vr = c._mm256_div_ps(va, vb);
            c._mm256_store_ps(&result[i + 8], vr);
        }

        while (i < len) : (i += 1) {
            result[i] = a[i] / b[i];
        }
    }

    pub inline fn avx256_f64_aligned_div_vectorized(a: []const f64, b: []const f64, result: []f64) void {
        const len = a.len;
        var i: usize = 0;

        while (i + 8 <= len) : (i += 8) {
            var va = c._mm256_load_pd(&a[i]);
            var vb = c._mm256_load_pd(&b[i]);
            var vr = c._mm256_div_pd(va, vb);
            c._mm256_store_pd(&result[i], vr);

            va = c._mm256_load_pd(&a[i + 4]);
            vb = c._mm256_load_pd(&b[i + 4]);
            vr = c._mm256_div_pd(va, vb);
            c._mm256_store_pd(&result[i + 4], vr);
        }

        while (i < len) : (i += 1) {
            result[i] = a[i] / b[i];
        }
    }
};