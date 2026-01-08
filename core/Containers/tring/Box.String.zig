const category_mode = @import("Category.String.zig").impl;

pub const impl = struct {
    pub fn Box(comptime Tr: type) type {
        return struct {
            pub const char_t = Tr.char_t;
            pub const pointer_t = Tr.pointer_t;
            pub const size_type = Tr.size_type;
            pub const type_size = Tr.type_size;

            const last_char: usize = @sizeOf(Medium) - 1;
            const category_shift: usize = (@sizeOf(usize) - 1) * 8;
            const category_extract_mask: usize = 0b11000000;
            const storage_extract_mask: usize = 0b10000000;
            const ownership_extract_mask: usize = 0b01000000;
            const capacity_extract_mask: usize = ~(category_extract_mask << category_shift);

            const Medium = extern struct {
                data_: pointer_t,
                size_: size_type,
                capcaity_: usize,

                pub fn capacity(self: *const Medium) usize {
                    return self.capcaity_ & capacity_extract_mask;
                }

                pub fn setCapacity(
                    self: *Medium,
                    cap: usize,
                    mode: category_mode.Mode
                ) void {
                    self.capcaity_ = cap |
                        (@as(usize, @intFromEnum(mode.storage)) << 63) |
                        (@as(usize, @intFromEnum(mode.ownership)) << 62);
                }
            };

            pub const medium_size: usize = @sizeOf(Medium) / type_size;

            const Storage = union {
                as_small: [medium_size]char_t,
                as_byte: [@sizeOf(Medium)]u8,
                as_ml: Medium
            };

            storage: Storage = undefined,

            pub const box_value_t = Medium;
            pub const box_buffer_t = @TypeOf(@field(Storage, "as_small"));

            pub fn category(self: *const Storage) category_mode.Mode {
                return category_mode.Mode {
                    .storage = @enumFromInt(self.as_byte[last_char] & storage_extract_mask),
                    .ownership = @enumFromInt(self.as_byte[last_char] & ownership_extract_mask)
                };
            }
        };
    }
};