const std = @import("std");
const CrossTarget = std.zig.CrossTarget;

const log_scope = std.log.scoped(.fmod_build);

const SpecialTarget = enum {
    android,
    applesim,
    uwp,
};

const TargetPlatform = union(enum) {
    special: SpecialTarget,
    in_std: std.Target.Os.Tag,
};

const fsbank_platforms = [_]TargetPlatform{
    TargetPlatform{ .in_std = .linux },
    TargetPlatform{ .in_std = .macos },
    TargetPlatform{ .in_std = .windows },
};

const PlatformBuildInfo = struct { translate_c_step: *std.Build.Step.TranslateC, lib_search_dir: []const u8, link_lib: []const u8 };

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{
        .whitelist = &[_]CrossTarget{
            CrossTarget{
                .cpu_arch = .aarch64,
                .os_tag = .ios,
                .cpu_features_add = std.Target.aarch64.featureSet(&[_]std.Target.aarch64.Feature{.v8_3a}),
            },
            // Simulator only.
            CrossTarget{ .cpu_arch = .x86_64, .os_tag = .ios },
            CrossTarget{ .cpu_arch = .arm, .os_tag = .linux },
            CrossTarget{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnu },
            CrossTarget{ .cpu_arch = .x86, .os_tag = .linux, .abi = .gnu },
            CrossTarget{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
            CrossTarget{ .cpu_arch = .aarch64, .os_tag = .macos, .abi = .macabi },
            CrossTarget{ .cpu_arch = .x86_64, .os_tag = .macos, .abi = .macabi },
            CrossTarget{ .cpu_arch = .aarch64, .os_tag = .tvos },
            // Simulator only.
            CrossTarget{ .cpu_arch = .x86_64, .os_tag = .tvos },
            CrossTarget{ .cpu_arch = .wasm32, .os_tag = .freestanding },
            // UWP only.
            CrossTarget{ .cpu_arch = .arm, .os_tag = .windows, .abi = .msvc },
            CrossTarget{ .cpu_arch = .x86, .os_tag = .windows, .abi = .msvc },
            CrossTarget{ .cpu_arch = .x86_64, .os_tag = .windows, .abi = .msvc },
        },
    });

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const opts = b.addOptions();

    const special_target = b.option(SpecialTarget, "special_target", "Special target type not represented by std.Target");

    const fsbank = b.option(bool, "fsbank", "Enable fsbank component") orelse false;
    _ = fsbank;
    const studio = b.option(bool, "studio", "Enable studio component") orelse false;
    _ = studio;

    const act_tgt = (std.zig.system.NativeTargetInfo.detect(target) catch @panic("Could not resolve target!")).target;

    const target_platform: TargetPlatform = if (special_target) |st| .{ .special = st } else .{ .in_std = act_tgt.os.tag };

    const pbi = switch (target_platform) {
        .in_std => |tag| switch (tag) {
            else => @panic("TODO"),
        },
        .special => |st| switch (st) {
            .android => handle_android(b, act_tgt),
            else => @panic("TODO"),
        },
    };
    _ = pbi;

    // if (android) {
    //     if (act_tgt.os.tag != .linux) {
    //         fatal("Targeting Android requires targeting Linux!", .{});
    //     }
    //     if (act_tgt.cpu.arch == .arm and (!std.Target.arm.featureSetHas(act_tgt.cpu.features, .v7a) or act_tgt.abi != .gnueabi)) {
    //         fatal("Android support for 32-bit ARM requires ARMv7A and gnueabi, but the requested target does not match this!", .{});
    //     }
    //     if (act_tgt.cpu.arch == .aarch64 and !std.Target.aarch64.featureSetHas(act_tgt.cpu.features, .v8a)) {
    //         fatal("Android support for aarch64 requites ARMv8A, but this is not in the requested target!", .{});
    //     }
    //     if (simulator) {
    //         fatal("Android cannot be targeted at the same time as an iOS/tvOS simulator!", .{});
    //     }
    //     if (uwp) {
    //         fatal("Android cannot be targeted at the same time as UWP!", .{});
    //     }
    //     if (fsbank) {
    //         fatal("fsbank is not supported on Android!", .{});
    //     }
    // }

    const lib = b.addStaticLibrary(.{
        .name = "fmod",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib.addOptions("config", opts);

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

fn handle_android(b: *std.Build, tgt: std.Target) PlatformBuildInfo {
    _ = b;
    std.debug.print("cpu features: {any}", .{tgt.cpu.features});
    return undefined;
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    log_scope.err("Fatal build error:", .{});
    log_scope.err(format ++ "\n\n", args);
    std.process.exit(1);
}
