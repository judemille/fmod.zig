const builtin = @import("builtin");
const std = @import("std");

const c = @import("../raw.zig");
const err = @import("../error.zig");

const This = @This();

slice: []f32,
mat: []const []f32,
alloc: std.mem.Allocator,
row_len: usize,
rows_valid: usize = 0,
cols_valid: usize = 0,

pub fn init(alloc: std.mem.Allocator, rows: usize, cols: usize) std.mem.Allocator.Error!This {
    std.debug.assert(rows > 0);
    std.debug.assert(cols > 0);
    const slice = try alloc.alloc(f32, rows * cols);

    var mat = try std.ArrayList([]f32).initCapacity(alloc, rows);
    errdefer mat.deinit();

    for (0..rows) |row| {
        const lower_bound = row * cols;
        const upper_bound = (row + 1) * cols;
        mat.appendAssumeCapacity(slice[lower_bound..upper_bound]);
    }
    return This{
        .slice = slice,
        .mat = try mat.toOwnedSlice(),
        .alloc = alloc,
        .row_len = cols,
    };
}

pub fn deinit(self: This) void {
    self.alloc.free(self.mat);
    self.alloc.free(self.slice);
}

test "core.VolumeMatrix" {
    const expectEqual = std.testing.expectEqual;

    var vm = try This.init(std.testing.allocator, 5, 8);
    defer vm.deinit();

    try expectEqual(@as(usize, 5), vm.mat.len);
    try expectEqual(@as(usize, 8), vm.mat[0].len);

    try expectEqual(&vm.slice[8], &vm.mat[1][0]);
}
