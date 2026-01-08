pub const impl = struct {
    pub const category_t = u1;

    pub const Mode = struct {
        pub const Storage = enum(category_t) {
            Small = 0,
            Medium = 1
        };

        pub const Ownership = enum(category_t) {
            Owning = 0,
            Shared = 1
        };

        storage: Storage,
        ownership: Ownership,

        pub fn isSmall(self: Mode) bool { return self.storage == Storage.Small; }
        pub fn isMedium(self: Mode) bool { return self.storage == Storage.Medium; }
        pub fn isShared(self: Mode) bool { return self.ownership == Ownership.Shared; }
    };
};