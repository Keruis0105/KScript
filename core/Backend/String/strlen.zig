extern fn strlen_8bit_sse2_x86_x64(ptr: [*]const u8) usize;
extern fn strlen_16bit_sse2_x86_x64(ptr: [*]const u8) usize;
extern fn strlen_32bit_sse2_x86_x64(ptr: [*]const u8) usize;
extern fn strlen_8bit_avx2_x86_x64(ptr: [*]const u8) usize;
extern fn strlen_16bit_avx2_x86_x64(ptr: [*]const u8) usize;
extern fn strlen_32bit_avx2_x86_x64(ptr: [*]const u8) usize;

pub const Backend = struct {
    pub inline fn strlen(comptime Ty: type, ptr: [*]const Ty) usize {
        comptime {
            if (!@import("builtin").cpu.arch.isX86()) {
                @compileError("x86 only");
            }
        }

        if (@import("builtin").cpu.has(.x86, .avx2)) {
            if (Ty == u8) {
                return strlen_8bit_avx2_x86_x64(ptr);
            } else if (Ty == u16) {
                return strlen_16bit_avx2_x86_x64(ptr);
            } else {
                return strlen_32bit_avx2_x86_x64(ptr);
            }
        } else {
            if (Ty == u8) {
                return strlen_8bit_sse2_x86_x64(ptr);
            } else if (Ty == u16) {
                return strlen_16bit_sse2_x86_x64(ptr);
            } else {
                return strlen_32bit_sse2_x86_x64(ptr);
            }
        }
    }
};