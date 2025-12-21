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

    var global_arena: ?Arena = null;
    var global_map: ?CategoryMap = null;
    var initialized: bool = false;

    fn ensureGlobal(allocator: *Allocator) !void {
        if (!initialized) {
            global_arena = Arena.init;
            global_map = CategoryMap.init(allocator.*);
            initialized = true;
        }
    }

    pub const LogCategory = struct {
        data: LogCategoryEntry,

        pub fn getOrCreate(name_str: []const u8, allocator: *Allocator) !LogCategory {
            try impl.ensureGlobal(allocator);

            var arena = global_arena.?;
            var map = global_map.?;

            var canonical_str = try log_name_module.LogName.canonicalize(name_str);
            if (map.get(canonical_str.as_slice())) |existing| {
                return .{ .data = existing };
            }

            const buf = try arena.allocator().alloc(u8, canonical_str.size() + 1);
            @memcpy(buf, canonical_str.as_slice());
            const entry = LogCategoryEntry{ .ptr = buf.ptr, .len = canonical_str.size() + 1};
            try map.put(canonical_str.as_slice(), entry);
            return LogCategory { .data = entry };
        }

        pub fn getName(self: *const LogCategory) []const u8 {
            return self.data.ptr[0..self.data.len];
        }
    };
};