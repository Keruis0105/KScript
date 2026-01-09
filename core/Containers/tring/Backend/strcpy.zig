extern "c" fn strcpy_u8(dest: [*]u8, src: [*]const u8, length: usize) void;
extern "c" fn strcpy_u16(dest: [*]u16, src: [*]const u16, length: usize) void;
extern "c" fn strcpy_u32(dest: [*]u32, src: [*]const u32, length: usize) void;

extern "c" fn strmove_u8(dest: [*]u8, src: [*]const u8, length: usize) void;
extern "c" fn strmove_u16(dest: [*]u16, src: [*]const u16, length: usize) void;
extern "c" fn strmove_u32(dest: [*]u32, src: [*]const u32, length: usize) void;

pub const Backend = struct {
    const StrcpyFn_u8  = fn ([*]u8, [*]const u8, usize) void;
    const StrcpyFn_u16 = fn ([*]u16, [*]const u16, usize) void;
    const StrcpyFn_u32 = fn ([*]u32, [*]const u32, usize) void;

    const StrmoveFn_u8  = fn ([*]u8, [*]const u8, usize) void;
    const StrmoveFn_u16 = fn ([*]u16, [*]const u16, usize) void;
    const StrmoveFn_u32 = fn ([*]u32, [*]const u32, usize) void;

    const strcpy_u8_impl  = strcpy_u8;
    const strcpy_u16_impl = strcpy_u16;
    const strcpy_u32_impl = strcpy_u32;

    const strmove_u8_impl  = strmove_u8;
    const strmove_u16_impl = strmove_u16;
    const strmove_u32_impl = strmove_u32;

    pub inline fn strcpy(comptime Ty: type, dest: [*]Ty, src: [*]const Ty, length: usize) void {
        comptime {
            if (!@import("builtin").cpu.arch.isX86()) {
                @compileError("x86 only for scalar mode");
            }
        }

        switch (Ty) {
            u8  => strcpy_u8_impl(dest, src, length),
            u16 => strcpy_u16_impl(dest, src, length),
            u32 => strcpy_u32_impl(dest, src, length),
            else => @compileError("unsupported type for strcpy"),
        }
    }

    pub inline fn strmove(comptime Ty: type, dest: [*]Ty, src: [*]const Ty, length: usize) void {
        comptime {
            if (!@import("builtin").cpu.arch.isX86()) {
                @compileError("x86 only for scalar mode");
            }
        }

        switch (Ty) {
            u8  => strmove_u8_impl(dest, src, length),
            u16 => strmove_u16_impl(dest, src, length),
            u32 => strmove_u32_impl(dest, src, length),
            else => @compileError("unsupported type for strmove"),
        }
    }
};