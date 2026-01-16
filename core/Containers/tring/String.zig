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

            const StringView = @import("StringView.zig").impl.StringView(char_t);

            core: string_core = .init(),

            pub fn fromView(alloc: std.mem.Allocator, view: *const StringView) !@This() {
                return .{
                    .core = try .init_len(alloc, view.ptr, view.len)
                };
            }

            pub fn asView(self: *const @This()) StringView {
                return .{
                    .ptr = self.const_pointer(),
                    .len = self.size()
                };
            }

            pub fn fromSlice(alloc: std.mem.Allocator, slice: []const char_t) !@This() {
                return .{
                    .core = try .init_len(alloc, slice.ptr, slice.len)
                };
            }

            pub fn asSlice(self: *const @This()) []const char_t {
                return self.const_pointer()[0..self.size()];
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

            pub fn clone(self: *@This(), alloc: std.mem.Allocator) !@This() {
                return .{
                    .core = try self.core.clone(alloc)
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

            pub fn at(self: *const @This(), index: usize) char_t {
                return self.const_pointer()[index];
            }

            pub fn set(self: *@This(), alloc: std.mem.Allocator, index: usize, c: char_t) !void {
                try self.core.set(alloc, index, c);
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

            pub fn append(self: *@This(), alloc: std.mem.Allocator, args: anytype) !void {
                const Ty = @TypeOf(args);
                switch (@typeInfo(Ty)) {
                    .@"struct" => |info| {
                        if (info.is_tuple) {
                            inline for (args) |elem| {
                                try self.append(alloc, elem);
                            }
                        } else {
                            if (@TypeOf(args) == @This()) {
                                try self.core.append_len(alloc, args.const_pointer(), args.size());
                            } else if (@hasField(Ty, "ptr") and @hasField(Ty, "len")) {
                                try self.core.append_len(alloc, args.ptr, args.len);
                            } else {
                                @compileError("append: unsupported struct type");
                            }
                        }
                    },
                    .comptime_int, .int => {
                        try self.append_c(alloc, args);
                    },
                    .pointer => |info| {
                        const pT = info.child;
                        if (@typeInfo(pT) == .array) {
                            if (@typeInfo(pT).array.child == char_t) {
                                try self.core.append_str(alloc, args);
                            }
                        } else if (pT == @This()) {
                            try self.core.append_len(alloc, args.const_pointer(), args.size());
                        } else if (@hasField(pT, "ptr") and @hasField(pT, "len")) {
                            try self.core.append_len(alloc, args.ptr, args.len);
                        } else {
                            @compileError("append: unsupported pointer type");
                        }
                    },
                    else => {
                        @compileError("append: unsupported argument type");
                    }
                }
            }

            pub fn append_c(self: *@This(), alloc: std.mem.Allocator, c: char_t) !void {
                try self.core.append_c(alloc, c);
            }

            pub fn append_str(self: *@This(), alloc: std.mem.Allocator, str: const_pointer_t) !void {
                try self.core.append_str(alloc, str);
            }
        };
    }
};