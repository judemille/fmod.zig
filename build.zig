const std = @import("std");
const CrossTarget = std.zig.CrossTarget;

const log_scope = std.log.scoped(.fmod_build);

const SpecialTarget = enum {
    android,
    iossim,
    tvossim,
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

const PlatformBuildInfo = struct {
    lib_search_dirs: []const []const u8,
    link_libs: []const []const u8,
};

const BuildContext = struct {
    b: *std.Build,
    tgt: std.Target,
    optimize: std.builtin.OptimizeMode,
    fsbank: bool,
    studio: bool,
    fmod_dir: []const u8,
};

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .whitelist = &[_]CrossTarget{
            CrossTarget{
                .cpu_arch = .aarch64,
                .os_tag = .ios,
            },
            // Simulator only.
            CrossTarget{ .cpu_arch = .x86_64, .os_tag = .ios },
            CrossTarget{
                .cpu_arch = .arm,
                .os_tag = .linux,
                .cpu_features_add = std.Target.arm.featureSet(&[_]std.Target.arm.Feature{.v7a}),
            },
            CrossTarget{
                .cpu_arch = .aarch64,
                .os_tag = .linux,
                .abi = .gnu,
                .cpu_features_add = std.Target.aarch64.featureSet(&[_]std.Target.aarch64.Feature{.v8a}),
            },
            CrossTarget{
                .cpu_arch = .x86,
                .os_tag = .linux,
                .abi = .gnu,
                .cpu_features_add = std.Target.x86.featureSet(&[_]std.Target.x86.Feature{.sse2}),
            },
            CrossTarget{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
            CrossTarget{ .cpu_arch = .aarch64, .os_tag = .macos, .abi = .macabi },
            CrossTarget{ .cpu_arch = .x86_64, .os_tag = .macos, .abi = .macabi },
            CrossTarget{ .cpu_arch = .aarch64, .os_tag = .tvos },
            // Simulator only.
            CrossTarget{ .cpu_arch = .x86_64, .os_tag = .tvos },
            CrossTarget{ .cpu_arch = .wasm32, .os_tag = .emscripten },
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

    const special_target = b.option(SpecialTarget, "special-target", "Special target type not represented by std.Target");

    const fmod_dir = b.option([]const u8, "fmod-dir", "The location of the downloaded platform-specific Fmod SDK, as an absolute path.") orelse fatal("Please set -Dfmod_dir=<Fmod SDK location>", .{});

    const fsbank = b.option(bool, "fsbank", "Enable fsbank component") orelse false;
    const studio = b.option(bool, "studio", "Enable studio component") orelse false;

    const act_tgt = (std.zig.system.NativeTargetInfo.detect(target) catch @panic("Could not resolve target!")).target;

    const target_platform: TargetPlatform = if (special_target) |st| .{ .special = st } else .{ .in_std = act_tgt.os.tag };
    if (fsbank) {
        _ = for (fsbank_platforms) |platform| {
            if (std.meta.eql(platform, target_platform)) break platform;
        } else fatal("The platform {any} does not support fsbank!", .{target_platform});
    }

    const translate_c_step = b.addTranslateC(.{
        .source_file = .{ .path = "src/include_all_headers.h" },
        .target = target,
        .optimize = optimize,
    });
    translate_c_step.addIncludeDir(b.pathJoin(&[_][]const u8{ fmod_dir, "api/core/inc" }));

    if (fsbank) {
        translate_c_step.addIncludeDir(b.pathJoin(&[_][]const u8{ fmod_dir, "api/fsbank/inc" }));
        translate_c_step.defineCMacro("_INCLUDE_FSBANK_", null);
        log_scope.warn("fsbank may have additional runtime dependencies on libfsbvorbis and/or", .{});
        log_scope.warn("opus. If your use requires these libraries, please include them in the", .{});
        log_scope.warn("platform-appropriate manner. They can be found in the Fmod SDK.\n\n", .{});
    }

    if (studio) {
        translate_c_step.addIncludeDir(b.pathJoin(&[_][]const u8{ fmod_dir, "api/studio/inc" }));
        translate_c_step.defineCMacro("_INCLUDE_STUDIO_", null);
    }

    const ctx = BuildContext{
        .b = b,
        .fsbank = fsbank,
        .studio = studio,
        .tgt = act_tgt,
        .fmod_dir = fmod_dir,
        .optimize = optimize,
    };

    const pbi = switch (target_platform) {
        .in_std => |tag| switch (tag) {
            .emscripten => handleWasm(ctx),
            .ios => handleAppleEmbedded(ctx, target_platform),
            .linux => handleLinux(ctx),
            .macos => handleMac(ctx),
            .tvos => handleAppleEmbedded(ctx, target_platform),
            .windows => handleWindows(ctx, false),
            else => unreachable,
        },
        .special => |st| switch (st) {
            .android => handleAndroid(ctx),
            .iossim => handleAppleEmbedded(ctx, target_platform),
            .tvossim => handleAppleEmbedded(ctx, target_platform),
            .uwp => handleWindows(ctx, true),
        },
    };

    const lib = b.addStaticLibrary(.{
        .name = "zfmod",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const emit_docs = b.option(bool, "emit-docs", "Emit documentation for the library.") orelse false;
    if (emit_docs) {
        var gen_file = std.Build.GeneratedFile{ .step = &lib.step };
        lib.generated_docs = &gen_file;
    }

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    if (emit_docs) {
        const install_docs_step = std.Build.Step.InstallDir.create(b, .{
            .source_dir = lib.getEmittedDocs(),
            .install_dir = std.Build.InstallDir{ .custom = "share/doc" },
            .install_subdir = "fmod.zig",
        });
        install_docs_step.step.dependOn(&lib.step);
        b.getInstallStep().dependOn(&install_docs_step.step);
    }

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    var preload_paths = std.ArrayList(u8).init(b.allocator);
    for (pbi.lib_search_dirs, 1..) |dir, i| {
        preload_paths.writer().print(
            "{s}{s}",
            .{ dir, if (i < pbi.lib_search_dirs.len) ":" else "" },
        ) catch @panic("OOM");
    }

    const preload_paths_str = preload_paths.toOwnedSlice() catch @panic("OOM");

    // On Windows? Haha, too bad! I can't make the tests automatically find the libs. Sorry.
    run_lib_unit_tests.setEnvironmentVariable("LD_LIBRARY_PATH", preload_paths_str);
    run_lib_unit_tests.setEnvironmentVariable("DYLD_LIBRARY_PATH", preload_paths_str);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    const opts = b.addOptions();
    opts.addOption(bool, "fsbank", fsbank);
    opts.addOption(bool, "studio", studio);

    lib.addOptions("config", opts);
    lib_unit_tests.addOptions("config", opts);

    const c_mod = translate_c_step.createModule();
    lib.addModule("fmod-raw", c_mod);
    lib_unit_tests.addModule("fmod-raw", c_mod);

    for (pbi.lib_search_dirs) |search_dir| {
        lib.addLibraryPath(.{ .cwd_relative = search_dir });
        lib_unit_tests.addLibraryPath(.{ .cwd_relative = search_dir });
    }

    for (pbi.link_libs) |link_lib| {
        lib.linkSystemLibrary2(link_lib, .{
            .needed = true,
            .use_pkg_config = .no,
        });
        lib_unit_tests.linkSystemLibrary2(link_lib, .{
            .needed = true,
            .use_pkg_config = .no,
        });
    }

    if (act_tgt.os.tag == .ios or act_tgt.os.tag == .tvos) {
        lib.linkFrameworkNeeded("AudioToolbox");
        lib.linkFrameworkNeeded("AVFoundation");
        lib_unit_tests.linkFrameworkNeeded("AudioToolbox");
        lib_unit_tests.linkFrameworkNeeded("AVFoundation");
    }
}

fn handleLinux(ctx: BuildContext) PlatformBuildInfo {
    const core_lib = if (ctx.optimize == .Debug) "fmodL" else "fmod";
    const fsbank_lib = if (ctx.optimize == .Debug) "fsbankL" else "fsbank";
    const studio_lib = if (ctx.optimize == .Debug) "fmodstudioL" else "fmodstudio";
    var search_dirs = std.ArrayList([]const u8).initCapacity(ctx.b.allocator, 3) catch @panic("OOM");
    var link_libs = std.ArrayList([]const u8).initCapacity(ctx.b.allocator, 3) catch @panic("OOM");
    link_libs.appendAssumeCapacity(core_lib);
    if (ctx.fsbank) {
        if (ctx.tgt.cpu.arch != .x86 and ctx.tgt.cpu.arch != .x86_64)
            fatal("fsbank only supports x86 and x86_64 on Linux.", .{});

        link_libs.appendAssumeCapacity(fsbank_lib);
    }
    if (ctx.studio)
        link_libs.appendAssumeCapacity(studio_lib);

    switch (ctx.tgt.cpu.arch) {
        .arm => {
            if (ctx.tgt.abi != .gnueabihf)
                fatal("ARM32 support on Linux requires hard-float GNU EABI.", .{});

            search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/core/lib/arm/" }));
            if (ctx.studio)
                search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/studio/lib/arm/" }));
        },
        .aarch64 => {
            search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/core/lib/arm64/" }));
            if (ctx.studio)
                search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/studio/lib/arm64/" }));
        },
        .x86 => {
            search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/core/lib/x86/" }));
            if (ctx.fsbank)
                search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/fsbank/lib/x86/" }));

            if (ctx.studio)
                search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/studio/lib/x86/" }));
        },
        .x86_64 => {
            search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/core/lib/x86_64/" }));
            if (ctx.fsbank)
                search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/fsbank/lib/x86_64/" }));

            if (ctx.studio)
                search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/studio/lib/x86_64/" }));
        },
        else => unreachable,
    }
    return PlatformBuildInfo{
        .lib_search_dirs = search_dirs.toOwnedSlice() catch @panic("OOM"),
        .link_libs = link_libs.toOwnedSlice() catch @panic("OOM"),
    };
}

fn handleAndroid(ctx: BuildContext) PlatformBuildInfo {
    if (ctx.tgt.os.tag != .linux)
        fatal("Targeting Android requires targeting Linux.", .{});

    const core_lib = if (ctx.optimize == .Debug) "fmodL" else "fmod";
    const studio_lib = if (ctx.optimize == .Debug) "fmodstudioL" else "fmodstudio";
    var search_dirs = std.ArrayList([]const u8).initCapacity(ctx.b.allocator, 2) catch @panic("OOM");
    var link_libs = std.ArrayList([]const u8).initCapacity(ctx.b.allocator, 2) catch @panic("OOM");
    link_libs.appendAssumeCapacity(core_lib);
    if (ctx.studio)
        link_libs.appendAssumeCapacity(studio_lib);

    switch (ctx.tgt.cpu.arch) {
        .arm => {
            if (ctx.tgt.abi != .gnueabi)
                fatal("ARM32 support on Android requires the soft-float GNU EABI.", .{});

            search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/core/lib/armeabi-v7a/" }));
            if (ctx.studio)
                link_libs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/studio/lib/armeabi-v7a/" }));
        },
        .aarch64 => {
            search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/core/lib/arm64-v8a/" }));
            if (ctx.studio)
                link_libs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/studio/lib/arm64-v8a/" }));
        },
        .x86 => {
            search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/core/lib/x86/" }));
            if (ctx.studio)
                link_libs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/studio/lib/x86/" }));
        },
        .x86_64 => {
            search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/core/lib/x86_64/" }));
            if (ctx.studio)
                link_libs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/studio/lib/x86_64/" }));
        },
        else => unreachable,
    }
    return PlatformBuildInfo{
        .lib_search_dirs = search_dirs.toOwnedSlice() catch @panic("OOM"),
        .link_libs = link_libs.toOwnedSlice() catch @panic("OOM"),
    };
}

fn handleAppleEmbedded(ctx: BuildContext, tgt_plat: TargetPlatform) PlatformBuildInfo {
    const core_pfx = if (ctx.optimize == .Debug) "fmodL" else "fmod";
    const studio_pfx = if (ctx.optimize == .Debug) "fmodstudioL" else "fmodstudio";
    if (@intFromEnum(tgt_plat) == @intFromEnum(TargetPlatform.in_std) and ctx.tgt.cpu.arch != .aarch64) {
        fatal("Only aarch64 is supported when building for embedded Apple devices.", .{});
    }
    const lib_suffix = switch (tgt_plat) {
        .in_std => |plat| switch (plat) {
            .ios => "iphoneos",
            .tvos => "appletvos",
            else => unreachable,
        },
        .special => |plat| switch (plat) {
            .iossim => "iphonesimulator",
            .tvossim => "appletvsimulator",
            else => unreachable,
        },
    };
    var search_dirs = std.ArrayList([]const u8).initCapacity(ctx.b.allocator, 2) catch @panic("OOM");
    var link_libs = std.ArrayList([]const u8).initCapacity(ctx.b.allocator, 2) catch @panic("OOM");
    search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/core/lib/" }));
    link_libs.appendAssumeCapacity(fmt(ctx, "{s}_{s}", .{ core_pfx, lib_suffix }));
    if (ctx.studio) {
        search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/studio/lib/" }));
        link_libs.appendAssumeCapacity(fmt(ctx, "{s}_{s}", .{ studio_pfx, lib_suffix }));
    }
    return PlatformBuildInfo{
        .lib_search_dirs = search_dirs.toOwnedSlice() catch @panic("OOM"),
        .link_libs = link_libs.toOwnedSlice() catch @panic("OOM"),
    };
}

fn handleMac(ctx: BuildContext) PlatformBuildInfo {
    const core_lib = if (ctx.optimize == .Debug) "fmodL" else "fmod";
    const fsbank_lib = if (ctx.optimize == .Debug) "fsbankL" else "fsbank";
    const studio_lib = if (ctx.optimize == .Debug) "fmodstudioL" else "fmodstudio";
    var search_dirs = std.ArrayList([]const u8).initCapacity(ctx.b.allocator, 3) catch @panic("OOM");
    var link_libs = std.ArrayList([]const u8).initCapacity(ctx.b.allocator, 3) catch @panic("OOM");

    search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/core/lib/" }));
    link_libs.appendAssumeCapacity(core_lib);

    if (ctx.fsbank) {
        search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/fsbank/lib/" }));
        link_libs.appendAssumeCapacity(fsbank_lib);
    }

    if (ctx.studio) {
        search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/studio/lib/" }));
        link_libs.appendAssumeCapacity(studio_lib);
    }

    return PlatformBuildInfo{
        .lib_search_dirs = search_dirs.toOwnedSlice() catch @panic("OOM"),
        .link_libs = link_libs.toOwnedSlice() catch @panic("OOM"),
    };
}

fn handleWindows(ctx: BuildContext, is_uwp: bool) PlatformBuildInfo {
    if (ctx.tgt.cpu.arch == .arm and !is_uwp)
        fatal("The default Windows target does not support ARM with Fmod. Please target UWP if you want ARM support.", .{});

    const lib_infix = if (ctx.optimize == .Debug) "L" else "";
    const lib_suffix = if (is_uwp) "" else "_vc";

    const core_lib = fmt(ctx, "fmod{s}{s}", .{ lib_infix, lib_suffix });
    const studio_lib = fmt(ctx, "fmodstudio{s}{s}", .{ lib_infix, lib_suffix });
    var search_dirs = std.ArrayList([]const u8).initCapacity(ctx.b.allocator, 3) catch @panic("OOM");
    var link_libs = std.ArrayList([]const u8).initCapacity(ctx.b.allocator, 3) catch @panic("OOM");

    link_libs.appendAssumeCapacity(core_lib);

    if (ctx.fsbank) {
        // We know we're not UWP, since that gets filtered out in earlier checks.
        link_libs.appendAssumeCapacity("fsbank_vc");
        log_scope.warn("fsbank may require two additional runtime libraries.", .{});
        log_scope.warn("libfsbvorbis[64].dll and opus.dll can be found in the SDK.", .{});
        log_scope.warn("These libraries may not be needed, depending on your use, and", .{});
        log_scope.warn("they have not been dynamically linked, since it is not possible", .{});
        log_scope.warn("on Windows without import libraries for them.", .{});
    }

    if (ctx.studio)
        link_libs.appendAssumeCapacity(studio_lib);

    switch (ctx.tgt.cpu.arch) {
        .arm => {
            search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/core/lib/arm" }));

            if (ctx.studio)
                search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/studio/lib/arm" }));
        },
        .x86 => {
            search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/core/lib/x86" }));

            if (ctx.fsbank)
                search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/fsbank/lib/x86" }));

            if (ctx.studio)
                search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/studio/lib/x86" }));
        },
        .x86_64 => {
            search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/core/lib/x64" }));

            if (ctx.fsbank)
                search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/fsbank/lib/x64" }));

            if (ctx.studio)
                search_dirs.appendAssumeCapacity(ctx.b.pathJoin(&[_][]const u8{ ctx.fmod_dir, "api/studio/lib/x64" }));
        },
        else => unreachable,
    }

    return PlatformBuildInfo{
        .lib_search_dirs = search_dirs.toOwnedSlice() catch @panic("OOM"),
        .link_libs = link_libs.toOwnedSlice() catch @panic("OOM"),
    };
}

fn handleWasm(ctx: BuildContext) PlatformBuildInfo {
    if (ctx.studio) {
        return PlatformBuildInfo{
            .lib_search_dirs = &[_][]const u8{"api/studio/lib/upstream/w32"},
            .link_libs = &[_][]const u8{if (ctx.optimize == .Debug) "fmodstudioL_wasm" else "fmodstudio_wasm"},
        };
    } else {
        return PlatformBuildInfo{
            .lib_search_dirs = &[_][]const u8{"api/core/lib/upstream/w32"},
            .link_libs = &[_][]const u8{if (ctx.optimize == .Debug) "fmodL_wasm" else "fmod_wasm"},
        };
    }
}

fn fmt(ctx: BuildContext, comptime format: []const u8, args: anytype) []const u8 {
    return std.fmt.allocPrint(ctx.b.allocator, format, args) catch @panic("OOM");
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    log_scope.err("Fatal build error:", .{});
    log_scope.err(format ++ "\n\n", args);
    std.process.exit(1);
}
