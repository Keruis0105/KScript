const std = @import("std");

var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};

pub const impl = struct {
    pub fn Allocator(comptime Ty: type) type {
        return struct {
            pub const pointer_t = [*]Ty;

            pub fn create(comptime U: type) !type {
                return try gpa.allocator().create(U);
            }

            pub fn allocator(n: usize) !pointer_t {
                const slice = try gpa.allocator().alloc(Ty, n);
                return slice.ptr;
            }

            pub fn deallocator(p: pointer_t, n: usize) void {
                const slice: []Ty = p[0..n];
                gpa.allocator().free(slice);
            }

            pub fn deinit() void {
                _ = gpa.deinit();
            }
        };
    }
};