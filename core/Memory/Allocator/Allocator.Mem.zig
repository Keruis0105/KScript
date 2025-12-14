const std = @import("std");

pub const impl = struct {
    pub fn Allocator(comptime Ty: type) type {
        return struct {
            const pointer_t = [*]Ty;

            gpa: std.heap.GeneralPurposeAllocator(.{}) = .{},

            pub fn allocator(self: *@This(), n: usize) !pointer_t {
                const slice = try self.gpa.allocator().alloc(Ty, n);
                return slice.ptr;
            }

            pub fn deallocator(self: *@This(), p: pointer_t, n: usize) void {
                const slice: []Ty = p[0..n];
                self.gpa.allocator().free(slice);
            }
        };
    }
};