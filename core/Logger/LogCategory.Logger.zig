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

            const canonical_str = try log_name_module.LogName.canonicalize(global_alloc, name_str);

            if (map.get(canonical_str.as_slice())) |existing| {
                return .{ .data = existing };
            }

            try map.put(canonical_str.as_slice(), canonical_str);

            return .{ .data = canonical_str };
        }

        pub fn getName(self: *const LogCategory) []const u8 {
            return self.data.as_slice();
        }
    };
};