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

            pub fn fromView(alloc: std.mem.Allocator, view: anytype) !@This() {
                comptime {
                    if (!@hasField(@TypeOf(view), "ptr") or
                        !@hasField(@TypeOf(view), "len"))
                    {
                        @compileError("fromView expects a StringView-like type");
                    }
                }
                return .{
                    .core = try .init_len(alloc, view.ptr, view.len)
                };
            }

            pub fn fromSlice(alloc: std.mem.Allocator, slice: []const char_t) !@This() {
                return .{
                    .core = try .init_len(alloc, slice.ptr, slice.len)
                };
            }

            pub fn init_c(alloc: std.mem.Allocator, c: char_t) !@This() {
                return .{
                    .core = try .init_c(alloc, c)
                };
            }

            pub fn init_str(alloc: std.mem.Allocator, str: const_pointer_t) !@This() {
                return .{
                    .core = try .init_str(alloc, str)
                };
            }

            pub fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
                self.core.deinit(alloc);
            }

            pub fn pointer(self: *@This()) pointer_t {
                return self.core.pointer();
            }

            pub fn const_pointer(self: *const @This()) const_pointer_t {
                return self.core.const_pointer();
            }

            pub fn size(self: *const @This()) usize {
                return self.core.size();
            }

            pub fn capacity(self: *const @This()) usize {
                return self.core.capacity();
            }

            pub fn empty(self: *const @This()) bool {
                return self.core.empty();
            }

            pub fn clear(self: *@This(), alloc: std.mem.Allocator) !void {
                try self.core.clear(alloc);
            }
        };
    }
};