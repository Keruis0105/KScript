const std = @import("std");

pub const impl = struct {
    pub fn Trait(comptime Ty: type) type {
        comptime {
            const info = @typeInfo(Ty);

            _ = switch (info) {
                .int => |i| i,
                else => @compileError("Trait only supports integer types"),
            };
        }

        return struct {
            pub const value_t = Ty;
            pub const bit_count = @bitSizeOf(Ty);
            pub const bit_t = std.meta.Int(
                .unsigned,
                std.math.log2_int_ceil(usize, bit_count)
            );
            pub const is_signed = switch (@typeInfo(Ty)) {
                .Int => |i| i.is_signed,
                else => @compileError("Shift only supports integer types")
            };
        };
    }
};