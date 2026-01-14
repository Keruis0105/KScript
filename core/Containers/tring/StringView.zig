const std = @import("std");
const string_module = @import("String.zig").impl;

pub const impl = struct {
    pub fn StringView(comptime Tr: type) type {
        return struct {
            pub const string_trait = Tr;
            const String = string_module.String(char_t);
            pub const char_t = string_trait.char_t;
            pub const pointer_t = string_trait.pointer_t;
            pub const const_pointer_t = string_trait.const_pointer_t;

            ptr: const_pointer_t,
            len: usize,

            pub fn slice(self: @This(), start: usize, end: usize) @This() {
                return .{
                    .ptr = self.ptr + start,
                    .len = end - start
                };
            }

            pub fn length(self: @This()) usize {
                return self.len;
            }

            pub fn empty(self: @This()) bool {
                return self.len == 0;
            }

            pub fn at(self: @This(), index: usize) char_t {
                return self.ptr[index];
            }

            pub fn toOwned(self: @This(), alloc: std.mem.Allocator) !String {
                return try String.fromView(alloc, self);
            }
        };
    }
};


