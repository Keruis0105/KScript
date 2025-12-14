const category_module = @import("Category.String.zig").impl;

pub const impl = struct {
    pub fn Box(comptime Tr: type) type {
        return struct {
            pub const char_t = Tr.char_t;
            pub const pointer_t = Tr.pointer_t;

            pub const type_size: usize = Tr.type_size;
            pub const category_shift: usize = Tr.category_shift;
            pub const category_bits: usize = Tr.category_bits;

            const MediumLarge = extern struct {
                data_:     pointer_t,
                size_:     usize,
                capcaity_: usize,

                pub fn capacity(self: *const MediumLarge) usize {
                    return self.capcaity_ >> category_shift;
                }

                pub fn setCapacity(
                    self: *MediumLarge,
                    cap:   usize,
                    cat:   category_module.Category
                ) void {
                    self.capcaity_ = (cap << category_shift) | @intFromEnum(cat);
                }
            };

            pub const medium_large_size: usize = @sizeOf(MediumLarge) / type_size;

            pub const Storage = union {
                as_ml: MediumLarge,
                as_small: [medium_large_size]char_t,
            };

            storage: Storage = undefined,

            pub const box_value_t = MediumLarge;
            pub const box_buffer_t = @TypeOf(@field(Storage, "as_small"));
            
            pub fn category(self: *const Storage) category_module.Category {
                return @enumFromInt(self.as_ml.capcaity_ & category_bits); 
            }
        };
    }
};