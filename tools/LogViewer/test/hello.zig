const std = @import("std");
const c = @cImport({
    @cInclude("windows.h");
});

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const utf8_log = "这是中文日志 🌟\n";

    var log_utf16: [:0]u16 = try std.unicode.utf8ToUtf16LeAllocZ(allocator, utf8_log);
    defer allocator.free(log_utf16);

    const pipe_name_utf8 = "\\\\.\\pipe\\LogWindowPipe";
    var pipe_name: [:0]u16 = try std.unicode.utf8ToUtf16LeAllocZ(allocator, pipe_name_utf8);
    defer allocator.free(pipe_name);

    const pipe: c.HANDLE = c.CreateFileW(
        pipe_name.ptr,
        c.GENERIC_WRITE,
        0,
        null,
        c.OPEN_EXISTING,
        0,
        null,
    );

    if (pipe == c.INVALID_HANDLE_VALUE) {
        std.debug.print("Failed to open pipe\n", .{});
        return;
    }

    var bytes_written: c.DWORD = 0;
    const ok = c.WriteFile(
        pipe,
        @ptrCast(log_utf16.ptr),
        @intCast(log_utf16.len * @sizeOf(u16)), // 字节数
        &bytes_written,
        null,
    );

    if (ok == 0) {
        std.debug.print("WriteFile failed\n", .{});
        _ = c.CloseHandle(pipe);
        return;
    }

    _ = c.CloseHandle(pipe);
    std.debug.print("Log sent successfully\n", .{});
}