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
                return .{
                    .storage = box_t.initEmpty()
                };
            }

            pub fn init_c(c: char_t) @This() {
                var self = @This() {
                    .storage = box_t.initEmpty()
                };


            }

            fn is_small_mode(self: *const @This()) bool {
                return box_t.category(self.storage).isSmall();
            }

            fn assign_init_c(self: *@This(), c: char_t) void {
                if (self.is_small_mode()) {
                    var buffer = self.storage.as_small;
                    const buf_size = buffer.size();
                    
                }
            }
        };
    }
};