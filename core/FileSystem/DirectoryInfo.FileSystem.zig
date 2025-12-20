const string_module = @import("../String/Mod.String.zig").mod;

pub const impl = struct {
    pub const DirectoryInfo = struct {
        name:            string_module.string,
        relative_path:   string_module.string,
        full_path:       string_module.string,
        directory_count: usize,
        file_count:      usize,
        success:         bool,
        depth:           usize,

        pub fn init_copy(self: *const @This()) !DirectoryInfo {
            return DirectoryInfo {
                .name = try self.name.init_copy(),
                .relative_path = try self.relative_path.init_copy(),
                .full_path = try self.full_path.init_copy(),
                .directory_count = self.directory_count,
                .file_count = self.file_count,
                .success = self.success,
                .depth = self.depth
            };
        }

        pub fn deinit(self: *@This()) void {
            self.name.deinit();
            self.relative_path.deinit();
            self.full_path.deinit();
        }

        pub fn isEmpty(self: *const @This()) bool {
            return self.directory_count == 0
                and self.file_count == 0;
        }

        pub fn totalCount(self: *const @This()) usize {
            return self.directory_count + self.file_count;
        }

        pub fn hasSubdirectories(self: *const @This()) bool {
            return self.directory_count > 0;
        }

        pub fn hasFiles(self: *const @This()) bool {
            return self.file_count > 0;
        }
    };
};