const char_type = @import("CharType.String.zig").impl;

pub const impl = struct {
    pub fn Trait(comptime id: char_type.CharTypeId) type {
        const Ty = char_type.CharTypeOf(id);
        return struct {
            pub const char_t = Ty;
            pub const pointer_t = [*]Ty;
            pub const const_pointer_t = [*]const Ty;
            pub const size_type = usize;

            pub const type_size = char_type.SizeOfChar(id);

            pub fn length(str: const_pointer_t) usize {
                return @import("Backend/strlen.zig").Backend.strlen(Ty, str);
            }

            pub fn copy(dest: pointer_t, src: const_pointer_t, count: usize) void {
                var i: usize = 0;
                while (i < count) : (i += 1) {
                    dest[i] = src[i];
                }
            }
        };
    }
};