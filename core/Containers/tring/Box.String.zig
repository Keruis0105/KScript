const std = @import("std");
const category_module = @import("Category.String.zig").impl;

pub const impl = struct {
    pub fn Box(comptime Tr: type) type {
        return struct {
            pub const char_t = Tr.char_t;
            pub const pointer_t = Tr.pointer_t;
            pub const type_size = Tr.type_size;

            const last_byte: usize = @sizeOf(Large) - 1;
            pub const max_cache_size: usize = last_byte / type_size;
            const category_shift: usize = (@sizeOf(usize) - 1) * 8;
            const category_extract_mask: usize = 0b11000000;
            const storage_extract_mask: usize = 0b10000000;
            const ownership_extract_mask: usize = 0b01000000;
            const capacity_extract_mask: usize = ~(category_extract_mask << category_shift);

            const Cache = struct {
                data_: [max_cache_size + 1]char_t,

                pub fn size(self: *const Cache) usize {
                    return self.data_[max_cache_size];
                }

                pub fn pointer(self: *Cache) pointer_t {
                    return @ptrCast(&self.data_[0]);
                }
            };

            const Large = struct {
                data_: pointer_t,
                size_: usize,
                capacity_: usize,

                pub fn size(self: *Large) usize {
                    return self.size_;
                }

                pub fn pointer(self: *Large) pointer_t {
                    return self.data_;
                }

                pub inline fn capacity(self: *const Large) usize {
                    return self.capacity_ & capacity_extract_mask;
                }

                pub inline fn setCapacity(
                    self: *Large,
                    cap: usize,
                    mode: category_module.Mode
                ) void {
                    self.capacity_ = cap |
                        (@as(usize, @intFromEnum(mode.storage)) << 63) |
                        (@as(usize, @intFromEnum(mode.ownership)) << 62);
                }
            };

            pub const rc_header_size: usize = @sizeOf(RcHeader) / type_size;

            pub const RcHeader = struct {
                refcount_: usize,
                size_: usize,
                capacity_: usize,

                pub fn alloc(
                    allocator: *std.mem.Allocator,
                    s: usize,
                    cap: usize
                ) !*RcHeader {
                    const total_size = rc_header_size + cap;

                    const raw = try allocator.alloc(char_t, total_size);
                    const header: *RcHeader = @ptrCast(raw.ptr);

                    header.refcount_ = 1;
                    header.size_ = s;
                    header.capacity_ = cap;

                    return header;
                }

                pub fn size(self: *RcHeader) usize {
                    return self.size_;
                }

                pub fn data(header: *RcHeader) pointer_t {
                    return @ptrCast(header + 1);
                }

                pub fn headerFromData(p: pointer_t) *RcHeader {
                    return @alignCast(@ptrCast(p - rc_header_size));
                }

                pub fn retain(comptime Atomic: bool, self: *RcHeader) void {
                    if (Atomic) {
                        _ = @atomicRmw(usize, &self.refcount_, .Add, 1, .seq_cst);
                    } else {
                        self.refcount_ += 1;
                    }
                }

                pub fn release(comptime Atomic: bool, self: *RcHeader) bool {
                    if (Atomic) {
                        const old = @atomicRmw(usize, &self.refcount_, .Sub, 1, .seq_cst);
                        return old == 1;
                    } else {
                        self.refcount_ -= 1;
                        return self.refcount_ == 0;
                    }
                }
            };

            pub const Storage = union {
                as_cache: Cache,
                as_byte: [@sizeOf(Large)]u8,
                as_large: Large
            };

            storage: Storage,

            pub const box_data_t = Large;
            pub const cache_buffer_t = Cache;

            const STORAGE_SHIFT = 7;
            const OWNERSHIP_SHIFT = 6;

            pub inline fn category(self: *const Storage) category_module.Mode {
                return category_module.Mode {
                    .storage = @enumFromInt((self.as_byte[last_byte] & storage_extract_mask) >> STORAGE_SHIFT),
                    .ownership = @enumFromInt((self.as_byte[last_byte] & ownership_extract_mask) >> OWNERSHIP_SHIFT)
                };
            }

            pub inline fn modeTag(self: *const Storage) category_module.Mode.ModeTag {
                return category_module.Mode.tag(category(self));
            }

            pub inline fn initEmpty() Storage {
                return .{
                    .as_byte = [_]u8{0} ** @sizeOf(Large)
                };
            }
        };
    }
};