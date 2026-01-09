const box_module = @import("Box.String.zig").impl;

pub const impl = struct {
    pub fn Core(comptime Tr: type) type {
        return struct {
            pub const string_trait = Tr;
            const type_size: usize = string_trait.type_size;
            pub const char_t = string_trait.char_t;
            pub const pointer_t = string_trait.pointer_t;
            pub const const_pointer_t = string_trait.const_pointer_t;

            const box_t = box_module.Box(Tr);

            storage: box_t.Storage = undefined,

            pub fn init() @This() {
                var instance: @This() = .{};
                instance.reset();
                return instance;
            }

            fn reset(self: *@This()) void {
                setSmallSize(self, 0);
            }

            fn
        };
    }
};