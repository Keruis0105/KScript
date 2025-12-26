const std = @import("std");
const log_writer_module = @import("LogWriter.Logger.zig").impl;
const c = @cImport({
    @cInclude("windows.h");
});

pub const impl = struct {
    pub const PipeLogWriter = struct {
        base: log_writer_module.LogWriter,
        pipe: c.HANDLE,
        allocator: std.mem.Allocator,

        pub fn deinit(self: *@This()) void {
            _ = c.CloseHandle(self.pipe);
            self.allocator.destroy(self);
        }
    };
    
    fn pipeWriteMessage(base: *log_writer_module.LogWriter, buffer: []const u8) void {
        const self: *PipeLogWriter = @fieldParentPtr("base", base);
        const utf16 = std.unicode.utf8ToUtf16LeAllocZ(self.allocator, buffer) catch return;
        defer self.allocator.free(utf16);

        var written: c.DWORD = 0;
        _ = c.WriteFile(
            self.pipe,
            @ptrCast(utf16.ptr),
            @intCast(utf16.len * @sizeOf(u16)),
            &written,
            null
        );
    }

    fn pipeFlush(base: *const log_writer_module.LogWriter) void {
        _ = base;
    }

    fn pipeTtyOutput(base: *const log_writer_module.LogWriter) bool {
        _ = base;
        return false;
    }
    
    pub fn initPipeLogWriter(alloc: std.mem.Allocator, pipe_name_utf8: []const u8) !*PipeLogWriter {
        const pipe_name_utf16 = try std.unicode.utf8ToUtf16LeAllocZ(alloc, pipe_name_utf8);
        defer alloc.free(pipe_name_utf16);
        
        const pipe = c.CreateFileW(
            pipe_name_utf16.ptr,
            c.GENERIC_WRITE,
            0,
            null,
            c.OPEN_EXISTING,
            0,
            null
        );
        
        if (pipe == c.INVALID_HANDLE_VALUE) {
            return error.OpenPipeFailed;
        }
        
        const self = try alloc.create(PipeLogWriter);
        self.* = .{
            .base = .{
                .writerMessage_ = pipeWriteMessage,
                .flush_ = pipeFlush,
                .ttyOutput_ = pipeTtyOutput,
            },
            .pipe = pipe,
            .allocator = alloc
        };
        
        return self;
    }
};