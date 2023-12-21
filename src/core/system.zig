//! Management object from which all resources are created and played.
//! Create with `create`.

const c = @import("../raw.zig");
const err = @import("../error.zig");
const This = @This();

system_ptr: ?*c.FMOD_SYSTEM,

/// Creates an instance of the FMOD system.
/// Multiple instances may be created. You must free each instance with `release`.
///
/// This function is not thread-safe. Do not call this function from multiple threads simultaneously.
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
    try err.resultToError(c.FMOD_System_GetSoftwareChannels(self.system_ptr, &num_software_channels));
    return num_software_channels;
}

/// Set the maximum number of software mixed `Channel`s possible.
/// Assumes that `init` has not yet been called, or `close` has been called.
/// Undefined Behavior will occur otherwise.
///
/// For more information, refer to FMOD's 'Virtual Voices' guide.
pub fn setSoftwareChannels(self: This, num_software_channels: c_int) err.FmodError!void {
    try err.resultToError(c.FMOD_System_SetSoftwareChannels(self.system_ptr, num_software_channels));
}

pub const InitFlags = packed struct(c_uint) {
    stream_from_update: bool,
    mix_from_update: bool,
    three_d_right_handed: bool,
    clip_output: bool,
    unused_zero_me_1: u4,
    channel_low_pass: bool,
    channel_distance_filter: bool,
    unused_zero_me_2: u6,
    profile_enable: bool,
    vol0_becomes_virtual: bool,
    geometry_use_closest: bool,
    thread_unsafe: bool,
    profile_meter_all: bool,
    memory_tracking: bool,
};

/// Initialize this `System` and prepare FMOD for playback.
///
/// # Parameters
/// - maxchannels
///   Maximum number of `Channel` objects available for playback, also known as virtual voices.
///   Virtual voices will play with minimal overhead, with a subset of 'real' voices that are
///   mixed, and selected based on priority and audibility. See the Virtual Voices guide for more info.
/// - flags
///   Initialization flags. See `InitFlags`.
/// - extradriverdata
///   Additional output-specific initialization data. This will be passed to the output plugin.
///   See `OutputType` for descriptions of data that can be passed in, based on the selected output mode.
pub fn init(self: This, max_channels: u12, flags: InitFlags, extra_driver_data: ?*anyopaque) err.FmodError!void {
    try err.resultToError(c.FMOD_System_Init(self.system_ptr, max_channels, @bitCast(flags), extra_driver_data));
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

/// Closes and frees this object and its resources. Do not use this object afterwards.
///
/// This will internally call `close`, so calling `close` before this function
/// is not necessary.
///
/// This function is not thread-safe. Do not call this function from multiple threads simultaneously.
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
/// If `OutputType.no_sound_nrt` or `OutputType.wav_writer_nrt` modes are used, this function also
/// drives the software/DSP engine, instead of it running asynchronously in a thread as is the
/// default behavior. This can be used for faster-than-real-time updates to the decoding or DSP
/// engine, which might be useful if the output is the WAV writer, for example.
///
/// If `InitFlags.stream_from_update` is used, this function will update the stream engine.
/// Combining this with the non-realtime output will mean smoother captured output.
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
