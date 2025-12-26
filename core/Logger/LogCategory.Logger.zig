const std = @import("std");
const string_module = @import("../Containers/Mod.Containers.zig").String;
const log_name_module = @import("LogName.Logger.zig").impl;

const CategoryMap = std.StringHashMap(*string_module.string);

var global_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const global_alloc = global_arena.allocator();

var global_map = CategoryMap.init(global_alloc);

pub const impl = struct {
    pub const LogCategory = struct {
        data: *string_module.string,

        pub fn getOrCreate(name_str: []const u8) !LogCategory {
            var map = &global_map;

            var canonical = try log_name_module.LogName.canonicalize(std.heap.page_allocator, name_str);

            if (map.get(canonical.as_slice())) |existing| {
                return .{ .data = existing };
            }

            const canonical_str = try global_alloc.create(string_module.string);
            canonical_str.* = try canonical.clone(global_alloc);
            const key = try global_alloc.dupe(u8, canonical.as_slice());

            try map.put(key, canonical_str);

            return .{ .data = canonical_str };
        }

        pub fn getName(self: *const LogCategory) []const u8 {
            return self.data.as_slice();
        }
    };
};