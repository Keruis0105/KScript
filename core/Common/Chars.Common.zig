pub const Common = struct {
    pub fn isSeparator(c: u8) bool {
        return c == '.' or c == '/' or c == '\\';
    }

    pub fn isSpace(c: u8) bool {
        return c == ' ' or c == '\t' or c == '\n';
    }
};