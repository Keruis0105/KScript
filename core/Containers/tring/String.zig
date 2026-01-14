const std = @import("std");

const core_module = @import("Core.String.zig").impl;
const trait_module = @import("Trait.String.zig").impl;
const char_type_module = @import("CharType.String.zig").impl;

pub const impl = struct {
    pub inline fn String(comptime CharT: type) type {
        return struct {
            pub const string_core = core_module.Core(
                trait_module.Trait(
                    char_type_module.CharTypeIdOf(CharT)
                )
            );

            pub const char_t = string_core.char_t;
            pub const pointer_t = string_core.pointer_t;
            pub const const_pointer_t = string_core.const_pointer_t;

            core: string_core = .init(),

            pub fn init_c(alloc: std.mem.Allocator, c: char_t) !@This() {
                return .{
                    .core = try .init_c(alloc, c)
                };
            }

            pub fn pointer(self: *@This()) pointer_t {
                return self.core.pointer();
            }

            pub fn size(self: *@This()) usize {
                return self.core.size();
            }
        };
    }
};