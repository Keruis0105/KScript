const category_module = @import("Category.String.zig").impl;

pub const impl = struct {
    pub fn Box(comptime Tr: type) type {
        return struct {
            const bit_module = @import("../../Bit/Mod.Bit.zig").mod.Bit(usize);

            pub const char_t = Tr.char_t;
            pub const pointer_t = Tr.pointer_t;

            pub const type_size: usize = Tr.type_size;
            pub const last_char: usize = @sizeOf(MediumLarge) - 1;
            pub const category_shift: usize = (@sizeOf(usize) - 1) * 8;
            pub const category_extract_mask: usize = bit_module.shift.shl(
                bit_module.mask.low(2), 6
            );
            pub const capacity_extract_mask: usize = bit_module.shift.shl(
                bit_module.ops.not(category_extract_mask),
                category_shift
            );

            const MediumLarge = extern struct {
                data_:     pointer_t,
                size_:     usize,
                capcaity_: usize,

                pub fn capacity(self: *const MediumLarge) usize {
                    return self.capcaity_ & capacity_extract_mask;
                }

                pub fn setCapacity(
                    self: *MediumLarge,
                    cap:   usize,
                    cat:   category_module.Category
                ) void {
                    self.capcaity_ = cap | (@as(usize, @intFromEnum(cat)) << category_shift);
                }
            };

            pub const medium_large_size: usize = @sizeOf(MediumLarge) / type_size;

            pub const Storage = union {
                as_byte: [@sizeOf(MediumLarge)]u8,
                as_ml: MediumLarge,
                as_small: [medium_large_size]char_t,
            };

            storage: Storage = undefined,

            pub const box_value_t = MediumLarge;
            pub const box_buffer_t = @TypeOf(@field(Storage, "as_small"));
            
            pub fn category(self: *const Storage) category_module.Category {
                return @enumFromInt(self.as_byte[last_char] & category_extract_mask); 
            }
        };
    }
};