pub const impl = struct {
    pub const FileSystemError = error{
        AccessDenied,   // 拒绝访问 / 权限不足
        NotFound,       // 路径不存在
        InvalidPath,    // 路径无效
        IOError,        // 底层 I/O 读写失败
        Unknown         // 未知错误
    };
};