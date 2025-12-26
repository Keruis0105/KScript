const std = @import("std");
const string_module = @import("../Containers/Mod.Containers.zig").String;
const chars_common = @import("../Common/Chars.Common.zig").Common;

pub const impl = struct {
    pub const LogName = struct {
        pub fn canonicalize(slice: []const u8) !string_module.string {
            var cname = string_module.string.init();
            
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
                    _ = try cname.append_slice(".");
                    ignoreSeparator = true;
                } else {
                    _ = try cname.append_byte(c);
                    ignoreSeparator = false;
                }
            }

            return cname;
        }

        pub fn getParent(slice: []const u8) !string_module.string {
            if (slice.len == 0) return string_module.string.init();

            var idx: usize = slice.len;
            while (idx > 0 and chars_common.isSeparator(slice[idx - 1])) {
                idx-=1;
            }
            while (idx > 0 and !chars_common.isSeparator(slice[idx - 1])) {
                idx-=1;
            }
            while (idx > 0 and chars_common.isSeparator(slice[idx - 1])) {
                idx-=1;
            }
            return string_module.string.init_slice(slice[0..idx]);
        }

        pub fn cmp(a_init: []const u8, b_init: []const u8) i32 {
            var a = a_init;
            var b = b_init;

            while (a.len > 0 and chars_common.isSeparator(a[a.len - 1]))
                : (a = a[0..a.len - 1]) {}
            while (b.len > 0 and chars_common.isSeparator(b[b.len - 1]))
                : (b = b[0..b.len - 1]) {}

            var ignoreSeparator: bool = true;
            while (true) {
                if (ignoreSeparator) {
                    while (a.len > 0 and chars_common.isSeparator(a[0]))
                        : (a = a[1..]){}
                    while (b.len > 0 and chars_common.isSeparator(b[0]))
                        : (b = b[1..]){}
                }
                if (a.len == 0) return if (b.len == 0) 0 else -1;
                if (b.len == 0) return 1;

                if (chars_common.isSeparator(a[0])) {
                    if (!chars_common.isSeparator(b[0])) {
                        return @as(i32, '.') - @as(i32, b[0]);
                    }
                    ignoreSeparator = true;
                } else {
                    if (a[0] != b[0]) {
                        return @as(i32, a[0]) - @as(i32, b[0]);
                    }
                    ignoreSeparator = false;
                }
                a = a[1..];
                b = b[1..];
            }
        }
    };
};