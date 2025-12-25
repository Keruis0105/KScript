const std = @import("std");
const string_module = @import("../Containers/Mod.Containers.zig").String;
const chars_common = @import("../Common/Chars.Common.zig").Common;

pub const impl = struct {
    pub const LogName = struct {
        pub fn canonicalize(alloc: std.mem.Allocator, slice: []const u8) !*string_module.string {
            var cname = try alloc.create(string_module.string);
            cname.* = string_module.string.init();
            
            var end: usize = slice.len;
            while (end > 0 and chars_common.isSeparator(slice[end - 1])) {
                end-=1;
            }

            var ignoreSeparator: bool = true;
            for (slice[0..end]) |c| {
                if (chars_common.isSeparator(c)) {
                    if (ignoreSeparator) {
                        continue;
                    }
                    _ = try cname.append(".");
                    ignoreSeparator = true;
                } else {
                    _ = try cname.append_c(c);
                    ignoreSeparator = false;
                }
            }

            return cname;
        }
    };
};