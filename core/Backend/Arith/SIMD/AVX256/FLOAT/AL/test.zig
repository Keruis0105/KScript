const std = @import("std");
// const avx_add = @import("ADD_.AVX256.AL.FLOAT.zig").impl;

const N = 1 << 10; // 1M floats
const ROUNDS = 200;
const TESTS = 5; // 重复测试次数

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    // 32-byte 对齐
    const a = try alloc.alignedAlloc(f32, std.mem.Alignment.fromByteUnits(32), N);
    const b = try alloc.alignedAlloc(f32, std.mem.Alignment.fromByteUnits(32), N);
    const r = try alloc.alignedAlloc(f32, std.mem.Alignment.fromByteUnits(32), N);
    defer {
        alloc.free(a);
        alloc.free(b);
        alloc.free(r);
    }

    // 初始化数据
    for (0..N) |i| {
        a[i] = @floatFromInt(i);
        b[i] = @floatFromInt(i * 2);
    }

    // ---------- scalar ----------
    {
        var times: [TESTS]u64 = undefined;
        for (0..TESTS) |t| {
            var timer = try std.time.Timer.start();
            for (0..ROUNDS) |_| {
                for (0..N) |i| r[i] = a[i] + b[i];
            }
            times[t] = timer.read();
        }
        var sum: u64 = 0;
        for (times) |x| sum += x;
         std.debug.print("scalar: avg {d} ns over {d} runs\n", .{sum / TESTS, TESTS});
    }

    // // ---------- unrolled ----------
    // {
    //     var times: [TESTS]u64 = undefined;
    //     for (0..TESTS) |t| {
    //         var timer = try std.time.Timer.start();
    //         for (0..ROUNDS) |_| {
    //             var i: usize = 0;
    //             while (i + 8 <= N) : (i += 8) {
    //                 inline for (0..8) |k| r[i+k] = a[i+k] + b[i+k];
    //             }
    //             while (i < N) : (i += 1) r[i] = a[i] + b[i];
    //         }
    //         times[t] = timer.read();
    //     }
    //     var sum: u64 = 0;
    //     for (times) |x| sum += x;
    //      std.debug.print("unrolled: avg {d} ns over {d} runs\n", .{sum / TESTS, TESTS});
    // }
    //
    // // ---------- avx256 ----------
    // {
    //     var times: [TESTS]u64 = undefined;
    //     for (0..TESTS) |t| {
    //         var timer = try std.time.Timer.start();
    //         for (0..ROUNDS) |_| {
    //             avx_add.avx256_f32_aligned_add_vectorized(false, a[0..], b[0..], r[0..]);
    //         }
    //         times[t] = timer.read();
    //     }
    //     var sum: u64 = 0;
    //     for (times) |x| sum += x;
    //      std.debug.print("avx256: avg {d} ns over {d} runs\n", .{sum / TESTS, TESTS});
    // }
}