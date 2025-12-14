pub const impl = struct {
    pub const category_t = u8;

    pub const Category = enum(category_t) {
        isSmall = 0,
        isMedium = 1,
    };
};