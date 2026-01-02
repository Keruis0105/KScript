const std = @import("std");
const strlen = @import("Backend/String/strlen.zig").Backend;

pub fn main() void {
    const str = "sssssdewifcknvw pevd;kw";
    const len = strlen.strlen_u8(str);
    std.debug.print("{}", .{len});
}