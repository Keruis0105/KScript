pub const impl = struct {
    pub const category_t = u8;
    pub const ownership_t = u8;

    pub const Category = enum(category_t) {
        isSmall = 0,
        isMedium = 0x80
    };

    pub const Ownership = enum(ownership_t) {
        Owning = 0,
        Shared = 0x40
    };
};