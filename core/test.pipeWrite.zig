const std = @import("std");
const pipeW = @import("Logger/PipeLogWriter.Logger.zig").impl;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const writer = try pipeW.initPipeLogWriter(
        allocator,
        "\\\\.\\pipe\\LogWindowPipe"
    );
    defer writer.deinit();

    writer.base.writeMessage("你是小男娘！！！");
}