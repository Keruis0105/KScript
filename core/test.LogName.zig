const std = @import("std");
const log_name = @import("Logger/LogName.Logger.zig").impl;

pub fn main() !void {
    const raw_name = "foo//bar\\.baz..";
    const s = try log_name.LogName.canonicalize(raw_name);
    std.debug.print("{s}", .{s.as_slice()});
}