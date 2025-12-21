const std = @import("std");
const log_name_module = @import("LogName.Logger.zig").impl;

pub const impl = struct {
    const Arena = std.heap.GeneralPurposeAllocator(.{});
    const Allocator = std.mem.Allocator;

    const LogCategoryEntry = struct {
        ptr: [*]const u8,
        len: usize
    };

    const CategoryMap = std.StringHashMap(LogCategoryEntry);

    var global_arena: Arena = .init;
    var global_map: CategoryMap = CategoryMap.init(std.heap.page_allocator);

    pub const LogCategory = struct {
        data: LogCategoryEntry,

        pub fn getOrCreate(name_str: []const u8) !LogCategory {
            std.debug.print("{s}\n", .{name_str});
            var arena = global_arena;
            var map = global_map;

            var canonical_str = try log_name_module.LogName.canonicalize(name_str);
            if (map.get(canonical_str.as_slice())) |existing| {
                return .{ .data = existing };
            }

            const buf = try arena.allocator().alloc(u8, canonical_str.size() + 1);
            @memcpy(buf, canonical_str.as_slice());
            std.debug.print("buf = {s}\n", .{buf});
            const entry = LogCategoryEntry{ .ptr = buf.ptr, .len = canonical_str.size()};
            try map.put(canonical_str.as_slice(), entry);
            const w = LogCategory { .data = entry };
            std.debug.print("{s}\n", .{w.data.ptr[0..w.data.len]});
            return w;
        }

        pub fn getName(self: *const LogCategory) []const u8 {
            return self.data.ptr[0..self.data.len];
        }
    };
};