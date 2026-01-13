extern "c" fn strset_u8(dest: [*]u8, c: u8, length: usize) void;
extern "c" fn strset_u16(dest: [*]u16, c: u16, length: usize) void;
extern "c" fn strset_u32(dest: [*]u32, c: u32, length: usize) void;

pub const Backend = struct {
    const StrsetFn_u8  = fn ([*]u8, u8, usize) void;
    const StrsetFn_u16 = fn ([*]u16, u16, usize) void;
    const StrsetFn_u32 = fn ([*]u32, u32, usize) void;

    const strset_u8_impl  = strset_u8;
    const strset_u16_impl = strset_u16;
    const strset_u32_impl = strset_u32;

    pub inline fn strset(comptime Ty: type, dest: [*]Ty, c: Ty, length: usize) void {
        comptime {
            if (!@import("builtin").cpu.arch.isX86()) {
                @compileError("x86 only for scalar mode");
            }
        }

        switch (Ty) {
            u8 => strset_u8_impl(dest, c, length),
            u16 => strset_u16_impl(dest, c, length),
            u32 => strset_u32_impl(dest, c, length),
            else => @compileError("unsupperted type for strset")
        }
    }
};