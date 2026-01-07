const std = @import("std");
const Backend = @import("Backend/String/strlen.zig").Backend;


//   ?????????????????????????????????????????????????????


pub fn main() !void {
    const test_str =
        "abcdefghijklmnopqrstuvwxyz"
            ++ "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            ++ "0123456789"
            ++ "abcdefghijklmnopqrstuvwxyz"
            ++ "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            ++ "0123456789";

    const ptr: [*]const u8 = test_str;

    const qpc = @cImport({
        @cInclude("windows.h");
    });

    var freq: qpc.LARGE_INTEGER = undefined;
    if (qpc.QueryPerformanceFrequency(&freq) == 0) {
        return error.FailedToQueryFrequency;
    }

    var start: qpc.LARGE_INTEGER = undefined;
    if (qpc.QueryPerformanceCounter(&start) == 0) {
        return error.FailedToQueryCounter;
    }

    const iterations: usize = 10_000;
    var sum: usize = 0;

    for (0..iterations) |_| {
        sum += Backend.strlen(u8, ptr);
    }

    var end: qpc.LARGE_INTEGER = undefined;
    if (qpc.QueryPerformanceCounter(&end) == 0) {
        return error.FailedToQueryCounter;
    }

    std.mem.doNotOptimizeAway(sum);

    const elapsed_ticks: f64 = @floatFromInt(end.QuadPart - start.QuadPart);
    const freq_f: f64 = @floatFromInt(freq.QuadPart);

    const elapsed_ms = elapsed_ticks * 1000.0 / freq_f;
    const avg_ns = elapsed_ms * 1_000_000.0 / @as(f64, iterations);

    std.debug.print(
        "strlen = {d}\nstrlen result = {d}\niterations   = {d}\ntotal time   = {d} ms\navg per call = {d} ns\n\n",
        .{ Backend.strlen(u8, ptr), sum, iterations, elapsed_ms, avg_ns }
    );
}