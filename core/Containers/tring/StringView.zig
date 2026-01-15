const std = @import("std");
const string_module = @import("String.zig").impl;
const string_trait_module = @import("Trait.String.zig").impl;
const char_type_module = @import("CharType.String.zig").impl;

pub const impl = struct {
    pub fn StringView(comptime Ty: type) type {
        return struct {
            pub const string_trait = string_trait_module.Trait(
                char_type_module.CharTypeIdOf(Ty)
            );
            const String = string_module.String(char_t);
            pub const char_t = string_trait.char_t;
            pub const pointer_t = string_trait.pointer_t;
            pub const const_pointer_t = string_trait.const_pointer_t;

            ptr: const_pointer_t,
            len: usize,

            pub fn init(ptr_: const_pointer_t, len_: usize) @This() {
                return .{
                    .ptr = ptr_,
                    .len = len_
                };
            }

            pub fn fromC(ptr_: const_pointer_t) @This() {
                return .{
                    .ptr = ptr_,
                    .len = @import("Backend/strlen.zig").Backend.strlen(
                        char_t, ptr_
                    )
                };
            }

            pub fn fromSlice(slice_: []const char_t) @This() {
                return .{
                    .ptr = slice_.ptr,
                    .len = slice_.len
                };
            }

            pub fn fromString(s: *const String) @This() {
                return .{
                    .ptr = s.const_pointer(),
                    .len = s.size()
                };
            }

            pub fn slice(self: @This(), start: usize, end: usize) @This() {
                return .{
                    .ptr = self.ptr + start,
                    .len = end - start
                };
            }

            pub fn asSlice(self: @This()) []const char_t {
                return self.ptr[0..self.len];
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


