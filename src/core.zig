const std = @import("std");

const c = @import("raw.zig");
const err = @import("error.zig");
const FError = err.FmodError;

pub const DSP = @import("core/DSP.zig");
pub const System = @import("core/System.zig");
pub const VolumeMatrix = @import("core/VolumeMatrix.zig");

/// Check if FMOD is accessing the disk.
///
/// Do not use this to synchronize your own disk I/O with FMOD, since race conditions can occur.
/// `setDiskBusy` will block until FMOD is no longer accessing the disk, so use that if you plan
/// to access the disk.
pub fn getDiskBusy() FError!bool {
    var busy: c_int = undefined;
    try err.resultToError(c.FMOD_File_GetDiskBusy(&busy));
    return busy != 0;
}

/// Set the current disk busy state. Will block if FMOD is accessing the disk. Glorified mutex.
///
/// Pass `true` before you start accessing files that mutually exclusive access from FMOD.
/// Pass `false` once you're done.
pub fn setDiskBusy(busy: bool) FError!void {
    try err.resultToError(c.FMOD_File_SetDiskBusy(@intFromBool(busy)));
}

/// Inspect the current memory usage of FMOD. Set `blocking` to true if you want the DSP network to
/// immediately perform all queued allocations. This is very costly, though.
pub fn getMemoryStats(blocking: bool) FError!struct {
    /// Currently allocated memory, at the time of this call.
    current_allocated: c_int,
    /// Maximum allocated memory since `System.init`.
    max_allocated: c_int,
} {
    var curr: c_int = undefined;
    var max: c_int = undefined;
    try err.resultToError(c.FMOD_Memory_GetStats(&curr, &max, @intFromBool(blocking)));
    return .{ .current_allocated = curr, .max_allocated = max };
}

const _debugflags_end_padding_type = switch (@bitSizeOf(c_uint)) {
    32 => u13,
    64 => u45,
    else => @compileError("c_uint is an unexpected size!"),
};

pub const DebugFlags = packed struct(c_uint) {
    level_error: bool,
    level_warning: bool,
    level_log: bool,
    _padding_1: u5 = 0,
    type_memory: bool,
    type_file: bool,
    type_codec: bool,
    type_trace: bool,
    _padding_2: u4 = 0,
    display_timestamps: bool,
    display_line_numbers: bool,
    display_thread: bool,
    _padding_3: _debugflags_end_padding_type = 0,

    test "core.System: ensure DebugFlags works right" {
        const expectEqual = std.testing.expectEqual;
        const log2 = std.math.log2;
        try expectEqual(@sizeOf(c_uint), @sizeOf(@This()));
        try expectEqual(@bitSizeOf(c_uint), @bitSizeOf(@This()));
        try expectEqual(log2(0x100), @bitOffsetOf(@This(), "type_memory"));
        try expectEqual(log2(0x10000), @bitOffsetOf(@This(), "display_timestamps"));
    }
};

pub const DebugMode = enum(c.FMOD_DEBUG_MODE) {
    tty = c.FMOD_DEBUG_MODE_TTY,
    file = c.FMOD_DEBUG_MODE_FILE,
    callback = c.FMOD_DEBUG_MODE_CALLBACK,
    _,
};

test {
    std.testing.refAllDecls(@This());
}
