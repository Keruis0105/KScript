const std = @import("std");
const directory_info = @import("DirectoryInfo.FileSystem.zig").impl.DirectoryInfo;
const window_path_type = @import("WindowsPathType.FileSystem.zig").impl.WindowsPathType;
const file_system_error = @import("Error.FileSystem.zig").impl.FileSystemError;
const string_module = @import("../String/Mod.String.zig").mod;

const c = @cImport({
    @cInclude("io.h");
    @cInclude("windows.h");
    @cInclude("Shlwapi.h");
});

pub const impl = struct {
    pub const DirectoryOps = struct {
        path: string_module.string,
        path_type: window_path_type,
        info: ?directory_info = null,
        err:  ?file_system_error = null,

        pub fn init(path: string_module.string) !DirectoryOps {
            return DirectoryOps{
                .path = try path.init_copy(),
                .path_type = detectWindowsPathType(path.as_slice()),
                .info = null,
                .err = null,
            };
        }

        pub fn deinit(self: *@This()) void {
            self.path.deinit();
            if (self.info) |*info| (@constCast(info)).deinit();
        }

        pub fn getPath(self: *@This()) string_module.string {
            return self.path.init_copy();
        }

        pub fn getInfo(self: *@This()) !?directory_info {
            return if (self.info) |info| return try info.init_copy()
                else null;
        }

        pub fn getError(self: *@This()) ?file_system_error {
            return if (self.err) |err| err 
                else null;
        }

        pub fn scan(self: *@This()) !*@This() {
            var info = directory_info {
                .name = undefined,
                .relative_path = undefined,
                .full_path = undefined,
                .directory_count = 0,
                .file_count = 0,
                .success = true,
                .depth = 0
            };
            const path_slice = self.path.as_slice();
            info.name = try extractNameFromPath(path_slice, self.path_type);
            info.relative_path = try relativePathWin32(path_slice, self.path_type);
            info.full_path = try fullPathWin32(path_slice, self.path_type);            try scanDir(path_slice, &info);
            info.depth = computeDepth(info.full_path.as_slice());
            if (self.info) |*old_info| old_info.deinit();

            self.info = info;
            self.err = null;
            return self;
        }

        pub fn create(self: *@This()) !*@This() {
            const path = self.path.as_slice();
            const ok = c.CreateDirectoryA(path.ptr, null);
            if (ok == 0) {
                const err = c.GetLastError();
                if (err != c.ERROR_ALREADY_EXISTS) return error.IOError;
            }
            return self;
        }

        pub fn createSubdir(self: *@This(), name: []const u8) !*@This() {
            var full_path = try self.path.init_copy();
            _ = try full_path.append("\\");
            _ = try full_path.append(name.ptr);

            const ok = c.CreateDirectoryA(full_path.as_slice().ptr, null);
            if (ok == 0) {
                const err = c.GetLastError();
                if (err != c.ERROR_ALREADY_EXISTS)
                    return error.IOError;
            }

            full_path.deinit();

            return self;
        }

        pub fn createRecursive(self: *@This()) !*@This() {
            const path_slice = try fullPathWin32(self.path.as_slice(), self.path_type);

            var segments = std.ArrayList([]const u8).init();
            var last_start: usize = 0;

            for (path_slice, 0..) |ch, i| {
                if (ch == '\\' or ch == '/') {
                    if (i != last_start) try segments.append(path_slice[last_start..i]);
                    last_start = i + 1;
                }
            }
            if (last_start < path_slice.len) try segments.append(path_slice[last_start..]);

            var stack = std.ArrayList([]const u8).init();
            for (segments.items) |seg| {
                if (std.mem.eql(u8, seg, "..")) {
                    if (stack.items.len > 0) stack.items.len -= 1;
                } else if (!std.mem.eql(u8, seg, ".")) {
                    try stack.append(seg);
                }
            }

            var current_path = try string_module.string.init_slice("");

            switch (self.path_type) {
                .UNC => try current_path.append("\\\\"),
                .Device => try current_path.append("\\\\?\\"),
                .AbsoluteDrive, .Relative => {},
            }

            for (stack.items) |seg| {
                try current_path.append(seg);
                try current_path.append("\\");
                const ok = c.CreateDirectoryA(current_path.as_slice().ptr, null);
                if (ok == 0) {
                    const err = c.GetLastError();
                    if (err != c.ERROR_ALREADY_EXISTS) return error.IOError;
                }
            }

            return self;
        }

        // pub fn remove(self: *@This()) !*@This() {

        // }

        // pub fn removeRecursive(self: *@This()) !*@This() {

        // }

        // pub fn move(self: *@This()) !*@This() {

        // }

        // pub fn copy(self: *@This()) !*@This() {

        // }

        fn computeDepth(path: []const u8) usize {
            var count: usize = 0;
            for (path) |ch| {
                if (ch == '\\') count += 1;
            }

            return count;
        }

        fn detectWindowsPathType(path: []const u8) window_path_type {
            if (path.len == 0)
                return .Relative;

            if ((path.len >= 2 and path[0] == '.' and path[1] == '\\') or
                (path.len >= 3 and path[0] == '.' and path[1] == '.' and (path[2] == '\\' or path[2] == '/'))) {
                return .Relative;
            }

            if (path.len >= 2 and path[0] == '\\' and path[1] == '\\') {
                if (path.len >= 4 and path[2] == '?' and (path[3] == '\\' or path[3] == '/'))
                    return .Device;
                return .UNC;
            }

            if (path.len >= 3
                and ((path[0] >= 'A' and path[0] <= 'Z') or (path[0] >= 'a' and path[0] <= 'z'))
                and path[1] == ':'
                and (path[2] == '\\' or path[2] == '/'))
            {
                return .AbsoluteDrive;
            }

            return .Relative;
        }

        fn extractNameFromPath(path: []const u8, pathType: window_path_type) !string_module.string {
            var start_index: usize = 0;

            switch (pathType) {
                .AbsoluteDrive, .Relative => start_index = 0,
                .UNC => {
                    var sep_count: usize = 0;
                    for (path, 0..) |ch, i| {
                        if (ch == '\\' or ch == '/') sep_count += 1;
                        if (sep_count == 4) {
                            start_index = i + 1;
                            break;
                        }
                    }
                },
                .Device => {
                    if (path.len > 4) start_index = 4;
                }
            }

            var last_segment_start: usize = start_index;
            var last_segment_end: usize = start_index;

            var segment_start: usize = start_index;

            for (path[start_index..], 0..) |ch, i| {
                if (ch == '\\' or ch == '/') {
                    if (i != segment_start) {
                        const seg = path[segment_start..i];
                        if (std.mem.eql(u8, seg, "..")) {
                            last_segment_end = last_segment_start;
                        } else if (!std.mem.eql(u8, seg, ".")) {
                            last_segment_start = segment_start;
                            last_segment_end = i;
                        }
                    }
                    segment_start = i + 1;
                }
            }

            if (segment_start < path.len) {
                const seg = path[segment_start..];
                if (!std.mem.eql(u8, seg, ".") and !std.mem.eql(u8, seg, "..")) {
                    last_segment_start = segment_start;
                    last_segment_end = path.len;
                }
            }

            if (last_segment_end > last_segment_start) {
                return try string_module.string.init_slice(path[last_segment_start..last_segment_end]);
            } else {
                return string_module.string.init_c('.');
            }
        }

        fn relativePathWin32(path: []const u8, pathType: window_path_type) !string_module.string {
            switch (pathType) {
                .AbsoluteDrive, .Device => {
                    var buf: [c.MAX_PATH]u8 = undefined;
                    var cwdBuf: [c.MAX_PATH]u8 = undefined;

                    _ = c.GetCurrentDirectoryA(@intCast(cwdBuf.len), @ptrCast(&cwdBuf[0]));
                    const ok = c.PathRelativePathToA(
                        &buf,
                        &cwdBuf,
                        c.FILE_ATTRIBUTE_DIRECTORY,
                        path.ptr,
                        0
                    );
                    if (ok == 0) return error.IOError;

                    return string_module.string.init_str(&buf);
                },
                .Relative, .UNC => return string_module.string.init_slice(path)
            }
        }

        fn fullPathWin32(path: []const u8, pathType: window_path_type) !string_module.string {
            switch (pathType) {
                .AbsoluteDrive, .UNC, .Device => {
                    return string_module.string.init_slice(path);
                },
                .Relative => {},
            }

            var dba: std.heap.DebugAllocator(.{}) = .init;
            const gpa = dba.allocator();
            const allocator: std.mem.Allocator = gpa;

            var cwd_buf: [c.MAX_PATH]u8 = undefined;
            const cwd_len = c.GetCurrentDirectoryA(cwd_buf.len, &cwd_buf[0]);
            if (cwd_len == 0) return error.IOError;

            const cwd = cwd_buf[0..cwd_len];
          
            var combined = try string_module.string.init_slice("");
            defer combined.deinit();

            _ = try combined.append(cwd.ptr);
            if (!std.mem.endsWith(u8, cwd, "\\")) {
                _ = try combined.append("\\");
            }

            const raw = try std.mem.concat(allocator, u8, &.{combined.as_slice(), path});
      
            const out = try normalizePathWin32Slice(allocator, raw);
            
            return try string_module.string.init_slice(out);
        }

        fn normalizePathWin32Slice(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
            var stack: std.ArrayList([]const u8) = .empty;

            var start: usize = 0;
            var i: usize = 0;
            while (i <= path.len) : (i += 1) {
                const ch = if (i < path.len) path[i] else '\\';
                if (ch == '\\' or ch == '/') {
                    if (i > start) {
                        const seg = path[start..i];
                        if (!std.mem.eql(u8, seg, ".")) {
                            if (std.mem.eql(u8, seg, "..")) {
                                if (stack.items.len > 0) stack.items.len -= 1;
                            } else {
                                try stack.append(allocator, seg);
                            }
                        }
                    }
                    start = i + 1;
                }
            }

            var total_len: usize = 0;
            for (stack.items) |seg| total_len += seg.len;
            if (stack.items.len > 1) total_len += stack.items.len - 1;

            var out_buf = try allocator.alloc(u8, total_len);
            var pos: usize = 0;
            for (stack.items, 0..) |seg, idx| {
                @memcpy(out_buf[pos..], seg);
                pos += seg.len;
                if (idx + 1 < stack.items.len) {
                    out_buf[pos] = '\\';
                    pos += 1;
                }
            }

            return out_buf;
        }

        pub fn scanDir(path: []const u8, info: *directory_info) !void {
            var data: c._finddata_t = undefined;

            var search_path = try string_module.string.init_slice(path);
            defer search_path.deinit();
            _ = try search_path.append("\\*");

            const handle = c._findfirst(search_path.as_c_str(), &data);
            if (handle == -1) {
                info.success = false;
                return error.NotFound;
            }
            defer _ = c._findclose(handle);

            while (true) {
                const name = data.name;

                if (!std.mem.eql(u8, &name, ".") and !std.mem.eql(u8, &name, "..")) {
                    if ((data.attrib & c._A_SUBDIR) != 0) {
                        info.directory_count += 1;
                    } else {
                        info.file_count += 1;
                    }
                }

                if (c._findnext(handle, &data) != 0) break;
            }

            info.success = true;
        }

    };
};