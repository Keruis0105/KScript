pub const impl = struct {
    pub const CharTypeId = enum {
        char,
        wchar,
        u8char,
        u16char,
        u32char
    };

    pub fn CharTypeOf(comptime id: CharTypeId) type {
        return switch (id) {
            .char    => u8,
            .wchar   => u16,
            .u8char  => u8,
            .u16char => u16,
            .u32char => u32
        };
    }

    pub fn IsCharType(comptime Ty: type) bool {
        comptime for (CharTypeId) |id| {
            if (@TypeOf(CharTypeOf(id)) == Ty) return true;
        };
        return false;
    }
};