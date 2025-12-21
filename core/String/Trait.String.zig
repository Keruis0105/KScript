const std = @import("std");
const character_type = @import("CharacterType.String.zig").impl;

pub const impl = struct {
    pub fn Trait(comptime Id: character_type.CharTypeId) type {
        const Ty = character_type.CharTypeOf(Id);
        return struct {
            pub const char_t = Ty;
            pub const pointer_t = [*]Ty;
            pub const const_pointer_t = [*]const Ty;

            pub const type_size: usize = @sizeOf(Ty);

            pub fn length(str: const_pointer_t) usize {
                var i: usize = 0;
                while (true) :  (i += 1) {
                    if (str[i] == 0) break;
                    std.debug.assert(i < 1 << 30);
                }
                return i;
            }

            pub fn copy(dest: pointer_t, src: const_pointer_t, count: usize) void {
                var i: usize = 0;
                while (i < count) : (i += 1) {
                    dest[i] = src[i];
                }
            }

            pub fn assign(dest: pointer_t, ch: char_t, count: usize) void {
                var i: usize = 0;
                while (i < count) : (i += 1) {
                    dest[i] = ch;
                }
            }

            pub fn compare(ch1: char_t, ch2: char_t) bool {
                return ch1 == ch2;
            }

            pub fn compare_str(str1: const_pointer_t, str2: const_pointer_t, count: usize) bool {
                var i: usize = 0;
                while (i < count) : (i += 1) {
                    if (str1[i] != str2[i]) return false;
                }
                return true;
            }
        };
    }
};