const std = @import("std");
const config = @import("config");

pub const raw = @import("raw.zig");

pub const core = @import("core.zig");

pub const err = @import("error.zig");

pub usingnamespace if (config.fsbank) struct {
    pub const fsbank = @import("fsbank.zig");
} else struct {};

pub usingnamespace if (config.studio) struct {
    pub const studio = @import("studio.zig");
} else struct {};

test {
    std.testing.refAllDecls(@This());
}
