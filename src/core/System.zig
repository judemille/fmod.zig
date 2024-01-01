//! Management object from which all resources are created and played.
//! Create with `create`.

const builtin = @import("builtin");
const std = @import("std");

const c = @import("../raw.zig");
const err = @import("../error.zig");

const DSP = @import("DSP.zig");
const This = @This();

system_ptr: ?*c.FMOD_SYSTEM,

/// Creates an instance of the FMOD system.
/// Up to 8 instances may be created. You must free each instance with `release`.
///
/// This function is not thread-safe. Do not call this function from multiple
/// threads simultaneously.
pub fn create() err.FmodError!This {
    var ptr: ?*c.FMOD_SYSTEM = null;
    try err.resultToError(c.FMOD_System_Create(&ptr, c.FMOD_VERSION));
    return This{
        .system_ptr = ptr,
    };
}

/// Get the maximum number of software mixed `Channel`s possible.
///
/// For more information, refer to FMOD's 'Virtual Voices' guide.
pub fn getSoftwareChannels(self: This) err.FmodError!c_int {
    var num_software_channels: c_int = undefined;
    try err.resultToError(c.FMOD_System_GetSoftwareChannels(
        self.system_ptr,
        &num_software_channels,
    ));
    return num_software_channels;
}

/// Set the maximum number of software mixed `Channel`s possible.
/// Assumes that `init` has not yet been called, or `close` has been called.
/// Undefined Behavior will occur otherwise.
///
/// For more information, refer to FMOD's 'Virtual Voices' guide.
pub fn setSoftwareChannels(
    self: This,
    num_software_channels: c_int,
) err.FmodError!void {
    try err.resultToError(c.FMOD_System_SetSoftwareChannels(
        self.system_ptr,
        num_software_channels,
    ));
}

const _initflags_end_padding_type = switch (@bitSizeOf(c_uint)) {
    32 => u9,
    64 => u41,
    else => @compileError("c_uint is an unexpected size!"),
};

/// Flags for initialization of an FMOD System.
pub const InitFlags = packed struct(c_uint) {
    /// Do not create a stram thread internally. Streams are driven from `update`.
    /// Mainly used with non-realtime outputs.
    stream_from_update: bool,
    /// Do not create a mixer thread internally. Mixing is driven from `update`.
    /// Only applies to polling-based output modes such as `OutputType.no_sound`
    /// or `OutputType.wav_writer`.
    mix_from_update: bool,
    /// Perform 3D calculations in right-handed coordinates.
    three_d_right_handed: bool,
    /// Enable hard clipping of output values greater than 1.0 or less than -1.0.
    clip_output: bool,
    _padding_1: u4 = 0,
    /// Enable use of `ChannelControl.setLowPassGain`, `ChannelControl.set3DOcclusion`,
    /// or automatic usage by the `Geometry` API. All voices will add a software
    /// low-pass filter effect into the DSP chain, which is idle unless one of the
    /// mentioned functions/features is used.
    channel_low_pass: bool,
    /// If enabled, all 3D voices will add a software low-pass and high-pass filter
    /// effect into the DSP chain, which will act as a distance-automated band-pass
    /// filter. Use `setAdvancedSettings` to adjust the center frequency.
    channel_distance_filter: bool,
    _padding_2: u6 = 0,
    /// Enable TCP/IP-based host, which allows FMOD Studio or FMOD Profile to connect
    /// to this `System`, and view memory, CPU, and the DSP network graph in real-time.
    profile_enable: bool,
    /// When enabled, any sounds with a volume of 0 will become virtual and will not
    /// be processed, except for having their positions updated virtually. Use
    /// `setAdvancedSettings` to adjust what volume besides zero to switch to virtual
    /// at. Implied by `profile_meter_all`.
    vol0_becomes_virtual: bool,
    /// With the geometry engine, only procest the closest polygon, rather than
    /// accumulating all polygons the sound to listener line intersects.
    geometry_use_closest: bool,
    /// When using `SpeakerMode.s5_1` with a stereo output device, use the Dolby Pro
    /// Logic II downmix algorithm, instead of the default stereo downmix algorithm.
    prefer_dolby_downmix: bool,
    /// Disables thread-safety for API calls. Only use this is FMOD is being called
    /// from a single thread, and if the Studio API will not be used!
    thread_unsafe: bool,
    /// Reduces performance. Adds level metering for every single DSP unit in the graph.
    /// Use `DSP.setMeteringEnabled` to turn meters off individually. Setting this flag
    /// implies `profile_enable`.
    profile_meter_all: bool,
    /// Enables memory allocation tracking. Currently only useful when using the Studio
    /// API. Increases memory footprint, and reduces performance. This flag is
    /// implied by `studio.System.InitFlags.memory_tracking`.
    memory_tracking: bool,
    _padding_3: _initflags_end_padding_type = 0,

    test "core: ensure InitFlags works right" {
        const expectEqual = std.testing.expectEqual;
        const log2 = std.math.log2;
        try expectEqual(
            @sizeOf(c_uint),
            @sizeOf(@This()),
        );
        try expectEqual(
            @bitSizeOf(c_uint),
            @bitSizeOf(@This()),
        );
        try expectEqual(
            log2(0x100),
            @bitOffsetOf(InitFlags, "channel_low_pass"),
        );
        try expectEqual(
            log2(0x10000),
            @bitOffsetOf(InitFlags, "profile_enable"),
        );
        try expectEqual(
            log2(0x100000),
            @bitOffsetOf(InitFlags, "thread_unsafe"),
        );
        try expectEqual(
            log2(0x400000),
            @bitOffsetOf(InitFlags, "memory_tracking"),
        );
    }
};

/// Initialize this `System` and prepare FMOD for playback.
///
/// Assumes that `init` has not yet been called, or `close` has since been called.
///
/// # Parameters
/// - maxchannels
///   Maximum number of `Channel` objects available for playback, also known as virtual
///   voices. Virtual voices will play with minimal overhead, with a subset of 'real'
///   voices that are mixed, and selected based on priority and audibility. See
///   the Virtual Voices guide for more info.
/// - flags
///   Initialization flags. See `InitFlags`.
/// - extra_driver_data
///   Additional output-specific initialization data. This will be passed to the
///   output plugin. See `OutputType` for descriptions of data that can be passed
///   in, based on the selected output mode.
pub fn init(
    self: This,
    max_channels: u12,
    flags: InitFlags,
    extra_driver_data: ?*anyopaque,
) err.FmodError!void {
    try err.resultToError(c.FMOD_System_Init(
        self.system_ptr,
        max_channels,
        @bitCast(flags),
        extra_driver_data,
    ));
}

/// Close the connection to the output and return to an uninitialized state
/// without releasing the object.
///
/// Closing renders objects created with this `System` invalid. Make sure
/// any `Sound`, `ChannelGroup`, `Geometry`, and `DSP` objects are released
/// before calling this.
///
/// All pre-initialized configuration settings will remain, and the `System`
/// can be reinitialized as needed.
pub fn close(self: This) err.FmodError!void {
    try err.resultToError(c.FMOD_System_Close(self.system_ptr));
}

/// Closes and frees this object and its resources. Do not use this object
/// afterwards.
///
/// This will internally call `close`, so calling `close` before this function
/// is not necessary.
///
/// This function is not thread-safe. Do not call this function from multiple
/// threads simultaneously.
pub fn release(self: This) err.FmodError!void {
    try err.resultToError(c.FMOD_System_Release(self.system_ptr));
}

/// Updates the FMOD system.
///
/// Should be called once per tick/frame, to perform actions such as:
/// - Panning and reverb from 3D attributes changes.
/// - Virtualization of `Channel`s based on their audibility.
/// - Streaming if using `InitFlags.stream_from_update`.
/// - Mixing if using `InitFlags.mix_from_update`.
/// - Firing callbacks that are deferred until Update.
/// - DSP cleanup.
///
/// If `OutputType.no_sound_nrt` or `OutputType.wav_writer_nrt` modes are used,
/// this function also drives the software/DSP engine, instead of it running
/// asynchronously in a thread as is the default behavior. This can be used for
/// faster-than-real-time updates to the decoding or DSP engine, which might be useful
/// if the output is the WAV writer, for example.
///
/// If `InitFlags.stream_from_update` is used, this function will update the stream
/// engine. Combining this with the non-realtime output will mean smoother captured
/// output.
pub fn update(self: This) err.FmodError!void {
    try err.resultToError(c.FMOD_System_Update(self.system_ptr));
}

/// Retrieve arbitrary user data stored with `setUserData`.
pub fn getUserData(self: This) err.FmodError!?*anyopaque {
    var user_data: ?*anyopaque = undefined;
    try err.resultToError(c.FMOD_System_GetUserData(self.system_ptr, &user_data));
    return user_data;
}

/// Store arbitrary user data with this FMOD system. This data will be passed with any
/// system notification callbacks. The data can also be retrieved with `getUserData`.
pub fn setUserData(self: This, user_data: ?*anyopaque) err.FmodError!void {
    try err.resultToError(c.FMOD_System_SetUserData(self.system_ptr, user_data));
}

pub fn lockDSP(self: This) err.FmodError!void {
    try err.resultToError(c.FMOD_System_LockDSP(self.system_ptr));
}

pub fn unlockDSP(self: This) err.FmodError!void {
    try err.resultToError(c.FMOD_System_UnlockDSP(self.system_ptr));
}

pub fn setPluginPath(self: This, path: [*:0]const u8) err.FmodError!void {
    try err.resultToError(c.FMOD_System_SetPluginPath(self.system_ptr, path));
}

pub fn mixerSuspend(self: This) err.FmodError!void {
    try err.resultToError(c.FMOD_System_MixerSuspend(self.system_ptr));
}

pub fn mixerResume(self: This) err.FmodError!void {
    try err.resultToError(c.FMOD_System_MixerResume(self.system_ptr));
}

pub const OutputType = enum(c.FMOD_OUTPUTTYPE) {
    /// Pick the best output mode for the platform. Default behavior.
    autodetect = c.FMOD_OUTPUTTYPE_AUTODETECT,

    /// 3rd party plugin, unknown. Do not make values of this variant by yourself.
    unknown = c.FMOD_OUTPUTTYPE_UNKNOWN,

    /// Perform all mixing but discard the final output.
    no_sound = c.FMOD_OUTPUTTYPE_NOSOUND,

    /// Writes output to a .wav file.
    ///
    /// # Extra Driver Data
    /// Pass the WAV file name, as a `[*:0]const u8`, in `extra_driver_data`,
    /// in the `init` call.
    wav_writer = c.FMOD_OUTPUTTYPE_WAVWRITER,

    /// Non-real-time version of `no_sound`.
    no_sound_nrt = c.FMOD_OUTPUTTYPE_NOSOUND_NRT,

    /// Non-real-time version of `wav_writer`.
    ///
    /// # Extra Driver Data
    /// Pass the WAV file name, as a `[*:0]const u8`, in `extra_driver_data`,
    /// in the `init` call.
    wav_writer_nrt = c.FMOD_OUTPUTTYPE_WAVWRITER_NRT,

    /// Windows/UWP/Xbox One/Game Core -- Windows Audio Session API. Default on
    /// relevant platforms.
    wasapi = c.FMOD_OUTPUTTYPE_WASAPI,

    /// Windows -- Low-latency ASIO 2.0.
    ///
    /// # Extra Driver Data
    /// Pass the application window handle, as a `*anyopaque`, in the
    /// `extra_driver_data` of the `init` call.
    asio = c.FMOD_OUTPUTTYPE_ASIO,

    /// Linux -- PulseAudio. Default on Linux if available.
    ///
    /// # Extra Driver Data
    /// Pass the application name, as a `[*:0]const u8`, in the `extra_driver_data`
    /// of the `init` call.
    pulseaudio = c.FMOD_OUTPUTTYPE_PULSEAUDIO,

    /// Linux -- Advanced Linux Sound Architecture. Default on Linux if PulseAudio
    /// is unavailable.
    alsa = c.FMOD_OUTPUTTYPE_ALSA,

    /// Mac/iOS -- Core Audio. Default on relevant platforms.
    core_audio = c.FMOD_OUTPUTTYPE_COREAUDIO,

    /// Android -- Java Audio Track. Default on Android <= 2.2.
    audio_track = c.FMOD_OUTPUTTYPE_AUDIOTRACK,

    /// Android -- OpenSL ES. Default on Android versions 2.3..=7.1.
    opensl = c.FMOD_OUTPUTTYPE_OPENSL,

    /// PS4/PS5 -- Audio Out. Default on relevant platforms.
    audio_out = c.FMOD_OUTPUTTYPE_AUDIOOUT,

    /// PS4 -- Audio3D.
    audio_3d = c.FMOD_OUTPUTTYPE_AUDIO3D,

    /// HTML5 -- WebAudio ScriptProcessorNode output. Default on HTML5 if AWN
    /// isn't available.
    web_audio = c.FMOD_OUTPUTTYPE_WEBAUDIO,

    /// Switch -- nn::audio. Default on Switch.
    nn_audio = c.FMOD_OUTPUTTYPE_NNAUDIO,

    /// Win10/Xbox One/Game Core -- Windows Sonic.
    windows_sonic = c.FMOD_OUTPUTTYPE_WINSONIC,
    /// Android -- AAudio. Default on Android >= 8.1.
    aaudio = c.FMOD_OUTPUTTYPE_AAUDIO,

    /// HTML5 -- WebAudio AudioWorkletNode output. Default on HTML5 if available.
    audio_worklet = c.FMOD_OUTPUTTYPE_AUDIOWORKLET,

    /// iOS -- PHASE framework. Disabled.
    phase = c.FMOD_OUTPUTTYPE_PHASE,

    /// OpenHarmony -- OHAudio.
    oh_audio = c.FMOD_OUTPUTTYPE_OHAUDIO,

    /// Maximum number of output types supported.
    max = c.FMOD_OUTPUTTYPE_MAX,

    _,
};

test {
    std.testing.refAllDecls(@This());
}
