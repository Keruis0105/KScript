const std = @import("std");

pub const impl = struct {
    pub fn BitUtils(comptime Tr: type) type {
        return struct {
            pub const value_t = Tr.value_t;
            pub const bit_count = Tr.bit_count;

            pub fn print(value: value_t) void {
                var s: [bit_count]u8 = undefined;
                var i: usize = 0;
                var v = value;
                while (i < bit_count)
                : (i += 1) {
                    s[bit_count - 1 - i] = if ((v & 1) != 0) '1' else '0';
                    v >>=1;
                }
                std.debug.print("{s}\n", .{s});
            }

            pub inline fn popcount(value: value_t) usize {
                var v = value;
                var count: usize = 0;
                while (v != 0)
                : (v >>= 1) {
                    if ((v & 1) != 0)
                        count += 1;
                }
                return count;
            }
        };
    }
};