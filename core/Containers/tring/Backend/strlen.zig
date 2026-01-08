extern "c" fn strlen_u8(ptr: [*]const u8) usize;
extern "c" fn strlen_u16(ptr: [*]const u16) usize;
extern "c" fn strlen_u32(ptr: [*]const u32) usize;

extern "c" fn strlen_8bit_sse2_x86_x64(ptr: [*]const u8) usize;
extern "c" fn strlen_16bit_sse2_x86_x64(ptr: [*]const u16) usize;
extern "c" fn strlen_32bit_sse2_x86_x64(ptr: [*]const u32) usize;

extern "c" fn strlen_8bit_avx2_x86_x64(ptr: [*]const u8) usize;
extern "c" fn strlen_16bit_avx2_x86_x64(ptr: [*]const u16) usize;
extern "c" fn strlen_32bit_avx2_x86_x64(ptr: [*]const u32) usize;

pub const Backend = struct {
    const StrlenFn_u8 = fn ([*]const u8) usize;
    const StrlenFn_u16 = fn ([*]const u16) usize;
    const StrlenFn_u32 = fn ([*]const u32) usize;
    const strlen_u8_impl = blk: {
        const cpu = @import("builtin").cpu;
        if (cpu.has(.x86, .avx2))
            break :blk strlen_8bit_avx2_x86_x64
        else if (cpu.has(.x86, .sse2))
        break :blk strlen_8bit_sse2_x86_x64
        else
        break :blk strlen_u8;
    };

    const strlen_u16_impl = blk: {
        const cpu = @import("builtin").cpu;
        if (cpu.has(.x86, .avx2))
            break :blk strlen_16bit_avx2_x86_x64
        else if (cpu.has(.x86, .sse2))
            break :blk strlen_16bit_sse2_x86_x64
        else
            break :blk strlen_u16;
    };

    const strlen_u32_impl = blk: {
        const cpu = @import("builtin").cpu;
        if (cpu.has(.x86, .avx2))
            break :blk strlen_32bit_avx2_x86_x64
        else if (cpu.has(.x86, .sse2))
            break :blk strlen_32bit_sse2_x86_x64
        else
            break :blk strlen_u32;
    };

    pub inline fn strlen(comptime Ty: type, ptr: [*]const Ty) usize {
        comptime {
            if (!@import("builtin").cpu.arch.isX86()) {
                @compileError("x86 only");
            }
        }

        switch (Ty) {
            u8 => return strlen_u8_impl(ptr),
            u16 => return strlen_u16_impl(ptr),
            u32 => return strlen_u32_impl(ptr),
            else => @compileError("unsupported type")
        }
    }
};