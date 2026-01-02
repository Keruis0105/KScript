extern fn strlen_8bit_sse2_x86_x64(ptr: [*]const u8) usize;
extern fn strlen_16bit_sse2_x86_x64(ptr: [*]const u8) usize;
extern fn strlen_32bit_sse2_x86_x64(ptr: [*]const u8) usize;
extern fn strlen_8bit_avx2_x86_x64(ptr: [*]const u8) usize;
extern fn strlen_16bit_avx2_x86_x64(ptr: [*]const u8) usize;
extern fn strlen_32bit_avx2_x86_x64(ptr: [*]const u8) usize;

pub const Backend = struct {
    pub inline fn strlen_u8(ptr: [*]const u8) usize {
        comptime {
            if (!@import("builtin").cpu.arch.isX86()) {
                @compileError("x86 only");
            }
        }

        if (@import("builtin").cpu.has(.x86, .avx2)) {
            return strlen_8bit_avx2_x86_x64(ptr);
        } else {
            return strlen_8bit_sse2_x86_x64(ptr);
        }
    }

    pub inline fn strlen_u16(ptr: [*]const u16) usize {
        comptime {
            if (!@import("builtin").cpu.arch.isX86()) {
                @compileError("x86 only");
            }
        }

        if (@import("builtin").cpu.has(.x86, .avx2)) {
            return strlen_16bit_avx2_x86_x64(ptr);
        } else {
            return strlen_16bit_sse2_x86_x64(ptr);
        }
    }

    pub inline fn strlen_u32(ptr: [*]const u8) usize {
        comptime {
            if (!@import("builtin").cpu.arch.isX86()) {
                @compileError("x86 only");
            }
        }

        if (@import("builtin").cpu.has(.x86, .avx2)) {
            return strlen_32bit_avx2_x86_x64(ptr);
        } else {
            return strlen_32bit_sse2_x86_x64(ptr);
        }
    }
};