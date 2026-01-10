const std = @import("std");
const category_mode = @import("Category.String.zig").impl;

pub const impl = struct {
    pub fn Box(comptime Tr: type) type {
        return struct {
            pub const char_t = Tr.char_t;
            pub const pointer_t = Tr.pointer_t;
            pub const size_type = Tr.size_type;
            pub const type_size = Tr.type_size;

            const last_char: usize = @sizeOf(Medium) - 1;
            const max_small_size: usize = last_char / type_size;
            const category_shift: usize = (@sizeOf(usize) - 1) * 8;
            const category_extract_mask: usize = 0b11000000;
            const storage_extract_mask: usize = 0b10000000;
            const ownership_extract_mask: usize = 0b01000000;
            const capacity_extract_mask: usize = ~(category_extract_mask << category_shift);

            const Small = struct {
                data_: [max_small_size + 1]char_t,

                pub fn size(self: @This()) usize {
                    return self.data_[max_small_size];
                }
            };

            const Medium = extern struct {
                data_: pointer_t,
                size_: size_type,
                capacity_: usize,

                pub inline fn capacity(self: *const Medium) usize {
                    return self.capacity_ & capacity_extract_mask;
                }

                pub inline fn setCapacity(
                    self: *Medium,
                    cap: usize,
                    mode: category_mode.Mode
                ) void {
                    self.capacity_ = cap |
                        (@as(usize, @intFromEnum(mode.storage)) << 63) |
                        (@as(usize, @intFromEnum(mode.ownership)) << 62);
                }
            };

            pub const Storage = union {
                as_small: Small,
                as_byte: [@sizeOf(Medium)]u8,
                as_ml: Medium
            };

            storage: Storage,

            pub const box_value_t = Medium;
            pub const box_buffer_t = @TypeOf(@field(@field(Storage, "as_small"), "data_"));

            const STORAGE_SHIFT = 7;
            const OWNERSHIP_SHIFT = 6;

            pub inline fn category(self: *const Storage) category_mode.Mode {
                return category_mode.Mode {
                    .storage = @enumFromInt((self.as_byte[last_char] & storage_extract_mask) >> STORAGE_SHIFT),
                    .ownership = @enumFromInt((self.as_byte[last_char] & ownership_extract_mask) >> OWNERSHIP_SHIFT)
                };
            }

            pub inline fn initEmpty() Storage {
                return .{
                    .as_byte = [_]u8{0} ** @sizeOf(box_value_t)
                };
            }

            pub inline fn initSmall(data: box_buffer_t) Storage {
                comptime {
                    std.debug.assert(@intFromEnum(category_mode.Mode.Storage.Small) == 0);
                    std.debug.assert(@intFromEnum(category_mode.Mode.Ownership.Owning) == 0);
                }
                return .{
                    .as_small = .{
                        .data_ = data
                    }
                };
            }

            pub inline fn initMedium(
                data: pointer_t,
                size: usize,
                cap: usize,
                ow: category_mode.Mode.Ownership
            ) Storage {
                return .{
                    .as_ml = .{
                        .data_ = data,
                        .size_ = size,
                        .capacity_ = cap |
                            (@as(usize, @intFromEnum(category_mode.Mode.Storage.Medium)) << 63) |
                            (@as(usize, @intFromEnum(ow)) << 62)
                    }
                };
            }
        };
    }
};