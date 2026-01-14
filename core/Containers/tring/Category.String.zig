const std = @import("std"); 

pub const impl = struct {
    pub const category_t = u1;
    pub const mode_t = u2;

    pub const Mode = struct {
        pub const Storage = enum(category_t) {
            Cache = 0,
            Large = 1
        };

        pub const Ownership = enum(category_t) {
            Owning = 0,
            Shared = 1
        };

        pub const ModeTag = enum(mode_t) {
            Inline = 0b00,
            Heap   = 0b10,
            Shared = 0b11
        };

        storage: Storage,
        ownership: Ownership,

        pub fn isCache(self: Mode) bool { return self.storage == Storage.Cache; }
        pub fn isLarge(self: Mode) bool { return self.storage == Storage.Large; }
        pub fn isOwning(self: Mode) bool { return self.ownership == Ownership.Owning; }
        pub fn isShared(self: Mode) bool { return self.ownership == Ownership.Shared; }

        pub fn tag(self: Mode) ModeTag {
            comptime {
                std.debug.assert(@intFromEnum(ModeTag.Inline)  == 0);
                std.debug.assert(@intFromEnum(ModeTag.Heap) == 2);
                std.debug.assert(@intFromEnum(ModeTag.Shared) == 3);
            }

            const storage_bit: u2 = @intCast(@intFromEnum(self.storage));
            const ownership_bit: u2 = @intCast(@intFromEnum(self.ownership));

            return @enumFromInt(
                (storage_bit << 1) | ownership_bit
            );
        }
    };
};





