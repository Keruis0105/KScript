pub const impl = struct {
    pub const CharTypeId = enum {
        u8char,
        u16char,
        u32char
    };

    const type_table: [3]type = [_]type {
        u8,
        u16,
        u32
    };

    pub fn CharTypeOf(comptime id: CharTypeId) type {
        return type_table[@intFromEnum(id)];
    }

    pub fn CharTypeIdOf(comptime T: type) CharTypeId {
        inline for (type_table, 0..) |Ty, i| {
            if (T == Ty)
                return @enumFromInt(i);
        }
        @compileError("Unsupported char type");
    }

    pub fn SizeOfChar(comptime id: CharTypeId) usize {
        return @sizeOf(CharTypeOf(id));
    }
};