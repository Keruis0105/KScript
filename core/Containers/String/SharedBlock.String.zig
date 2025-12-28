const std = @import("std");

pub const impl = struct {
    pub fn SharedBlock(comptime Tr: type, comptime Alloc: type) type {
        return struct {
            pub const char_t = Tr.char_t;
            pub const pointer_t = Tr.pointer_t;
            pub const alloc_t = Alloc;

            ref_count_: u32,
            data_: pointer_t,

            pub fn createSharedBlock(
                data: pointer_t
            ) !*@This() {
                var block = try alloc_t.create(@This());
                block.ref_count_ = 1;
                block.data_ = data;
                return block;
            }

            pub fn retain(self: *@This()) void {
                _ = @atomicRmw(u32, &self.ref_count_, .Add, 1, .seq_cst);
            }

            pub fn release(self: *@This(), n: usize) void {
                const old = @atomicRmw(u32, &self.ref_count_, .Sub, 1, .seq_cst);
                if (old == 1) {
                    self.destory(n);
                }
            }

            fn destory(self: *@This(), n: usize) void {
                alloc_t.deallocator(self.data_, n);
            }
        };
    }
};