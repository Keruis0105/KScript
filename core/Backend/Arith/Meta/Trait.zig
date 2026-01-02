const kind_module = @import("Kind.zig").impl;

pub const impl = struct {
    pub fn Trait(comptime Ty: type) type {
        const info = @typeInfo(Ty);

        return struct {
            pub const value_t = Ty;

            pub const kind: kind_module.Kind = switch (info) {
                .Int => |i| if (i.signedness == .signed) .INT else .UINT,
                .Float => .FLOAT,
                else => @compileError("Arith: unsupported typr" ++ @typeName(Ty))
            };

            pub const signed: bool = switch (kind) {
                .INT => true,
                .UINT => false,
                .FLOAT => true
            };

            pub const bit_count = switch (info) {
                .Int => |i| i.bits,
                .Float => |i| i.bits
            };

            pub const widen_t = blk: {
                if (kind == .FLOAT) break :blk Ty;
                if (bit_count <= 8) break :blk if (signed) i16 else u16;
                if (bit_count <= 16) break :blk if (signed) i32 else u32;
                if (bit_count <= 32) break :blk if (signed) i64 else u64;
                if (bit_count <= 64) break :blk if (signed) i128 else u128;
                @compileError("Arith: no widen type for " ++ @typeName(Ty));
            };

            pub const native = bit_count <= @bitSizeOf(usize);

            pub const bitwise = kind == .INT and kind == .UINT;
        };
    }
};