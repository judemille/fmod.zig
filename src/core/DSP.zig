//! The Digital Signal Processor is one node within a graph
//! that transforms input audio signals to an output stream.

const std = @import("std");
const c = @import("../raw.zig");
const err = @import("../error.zig");
const FError = err.FmodError;

const DSP = @This();
const System = @import("System.zig");

const VolumeMatrix = @import("VolumeMatrix.zig");

ptr: ?*c.FMOD_DSP,

pub const Connection = struct {
    ptr: ?*c.FMOD_DSPCONNECTION,

    pub const Type = enum(c.FMOD_DSPCONNECTION_TYPE) {
        /// Default connection type. Audio is mixed from the input to the output
        /// DSP's audible buffer, meaning it will be part of the audible signal.
        /// A standard connection will execute its input DSP if it has not been
        /// executed before.
        standard = c.FMOD_DSPCONNECTION_TYPE_STANDARD,
        /// Sidechain connection type. Audio is mixed from the input to the output
        /// DSP's sidechain buffer, meaning it will NOT be part of the audible signal.
        /// A sidechain connection will execute its input DSP if it has not been
        /// executed before.
        ///
        /// The purpose of the sidechain buffer in a DSP is so that the DSP effect
        /// can privately access the data for analysis purposes. An example of use
        /// in this case could be a compressor which analyzes the signal, to control
        /// its own effect parameters (i.e. compression level or gain).
        ///
        /// For the effect developer to accept sidechain data, it will appear in the
        /// `DSP.State` struct which is passed into the read callback of a DSP unit.
        ///
        /// `DSP.State.sidechain_data` and `DSP.State.sidechain_channels` will hold
        /// the mixed result of any sidechain data flowing into the DSP.
        sidechain = c.FMOD_DSPCONNECTION_TYPE_SIDECHAIN,
        /// Send connection type. Audio is mixed from the input to the output DSP's
        /// audible buffer, meaning it will be part of the audible signal. A send
        /// connection will NOT execute its input DSP if it has not been executed
        /// before.
        ///
        /// A send connection will only read what exists at the input's buffer at
        /// the time of executing the output DSP unit (which can be considered
        /// the 'return').
        send = c.FMOD_DSPCONNECTION_TYPE_SEND,
        /// Send-sidechain connection type. Audio is mixed from the input to the
        /// output DSP's sidechain buffer, meaning it will NOT be part of the
        /// audible signal. A send-sidechain connection will NOT execute its
        /// input DSP if it has not been executed before.
        ///
        /// A send-sidechain connection will only read what exists at the input's
        /// buffer at the time of executing the output DSP unit (which can be
        /// considered the 'sidechain return').
        ///
        /// For the effect developer to accept sidechain data, it will appear in the
        /// `DSP.State` struct which is passed into the read callback of a DSP unit.
        ///
        /// `DSP.State.sidechain_data` and `DSP.State.sidechain_channels` will hold
        /// the mixed result of any sidechain data flowing into the DSP.
        send_sidechain = c.FMOD_DSPCONNECTION_TYPE_SEND_SIDECHAIN,
        /// Maximum number of DSP connection types supported.
        max = c.FMOD_DSPCONNECTION_TYPE_MAX,
        _,
    };

    pub fn getInput(self: @This()) FError!?DSP {
        var dsp_ptr: ?*c.FMOD_DSP = null;
        try err.resultToError(c.FMOD_DSPConnection_GetInput(self.ptr, &dsp_ptr));
        const out = dsp_ptr orelse return null;
        return DSP{ .ptr = out };
    }

    pub fn getOutput(self: @This()) FError!?DSP {
        var dsp_ptr: ?*c.FMOD_DSP = null;
        try err.resultToError(c.FMOD_DSPConnection_GetOutput(self.ptr, &dsp_ptr));
        const out = dsp_ptr orelse return null;
        return DSP{ .ptr = out };
    }

    pub fn getType(self: @This()) FError!Connection.Type {
        var typ: c.FMOD_DSPCONNECTION_TYPE = undefined;
        try err.resultToError(c.FMOD_DSPConnection_GetType(self.ptr, &typ));
        return @enumFromInt(typ);
    }

    pub fn getMix(self: @This()) FError!f32 {
        var volume: f32 = undefined;
        try err.resultToError(c.FMOD_DSPConnection_GetMix(self.ptr, &volume));
        return volume;
    }

    pub fn getMixMatrix(
        self: @This(),
        alloc: std.mem.Allocator,
    ) (FError || std.mem.Allocator.Error)!VolumeMatrix {
        var out_channels: c_int = 0;
        var in_channels: c_int = 0;
        try err.resultToError(c.FMOD_DSPConnection_GetMixMatrix(
            self.ptr,
            null,
            &out_channels,
            &in_channels,
            0,
        ));
        const out_channels_u: usize = @intCast(out_channels);
        const in_channels_u: usize = @intCast(in_channels);
        var vm = try VolumeMatrix.init(
            alloc,
            out_channels_u,
            in_channels_u,
        );
        try err.resultToError(c.FMOD_DSPConnection_GetMixMatrix(
            self.ptr,
            @ptrCast(vm.slice),
            &out_channels,
            &in_channels,
            in_channels,
        ));
        vm.rows_valid = @intCast(out_channels);
        vm.cols_valid = @intCast(in_channels);
        return vm;
    }

    pub fn getUserData(self: @This()) FError!?*anyopaque {
        var user_data: ?*anyopaque = null;
        try err.resultToError(c.FMOD_DSPConnection_GetUserData(
            self.ptr,
            &user_data,
        ));
        return user_data;
    }

    pub fn setMix(self: @This(), volume: f32) FError!void {
        try err.resultToError(c.FMOD_DSPConnection_SetMix(self.ptr, volume));
    }

    pub fn setMixMatrix(self: @This(), vm: ?VolumeMatrix) FError!void {
        try err.resultToError(c.FMOD_DSPConnection_SetMixMatrix(
            self.ptr,
            if (vm) |m| @ptrCast(m.slice) else null,
            if (vm) |m| @intCast(m.rows_valid) else 0,
            if (vm) |m| @intCast(m.cols_valid) else 0,
            if (vm) |m| @intCast(m.row_len) else 0,
        ));
    }

    pub fn setUserData(self: @This(), user_data: ?*anyopaque) FError!void {
        try err.resultToError(c.FMOD_DSPConnection_SetUserData(
            self.ptr,
            user_data,
        ));
    }

    test {
        std.testing.refAllDecls(@This());
    }
};

pub const Type = enum(c.FMOD_DSP_TYPE) {
    /// This DSP was created via a non-FMOD plugin, and has an unknown purpose.
    unknown = c.FMOD_DSP_TYPE_UNKNOWN,

    /// Does not process the signal -- acts as a unit purely for mixing inputs.
    mixer = c.FMOD_DSP_TYPE_MIXER,

    /// Generates sine/square/saw/triangle waves, or noise tones. See
    /// `FMOD_DSP_OSCILLATOR` for parameter information,
    /// [Effect reference - Oscillator](https://fmod.com/docs/2.02/api/effects-reference.html#oscillator)
    /// for overview.
    oscillator = c.FMOD_DSP_TYPE_OSCILLATOR,

    /// DEPRECATED! Will be removed in a future release!
    ///
    /// Filters sound using a high quality, resonant, low-pass filter algorithm,
    /// but consumes more CPU time.
    ///
    /// See `FMOD_DSP_LOWPASS` remarks for parameter information,
    /// [Effect reference - Low Pass](https://fmod.com/docs/2.02/api/effects-reference.html#low-pass)
    /// for overview.
    low_pass = c.FMOD_DSP_TYPE_LOWPASS,

    /// Filters sound using a resonant low-pass filter algorithm that is used in
    /// Impulse Tracker, but with limited cutoff range. See `FMOD_DSP_ITLOWPASS`
    /// for parameter information,
    /// [Effect reference - IT Low Pass](https://fmod.com/docs/2.02/api/effects-reference.html#it-low-pass)
    /// for overview.
    it_low_pass = c.FMOD_DSP_TYPE_ITLOWPASS,

    /// DEPRECATED! Will be removed in a future release!
    ///
    /// Filters sound using a resonant high-pass filter algorithm. See
    /// `FMOD_DSP_HIGHPASS` remarks for parameter information,
    /// [Effect reference - High Pass](https://fmod.com/docs/2.02/api/effects-reference.html#high-pass)
    /// for overview.
    high_pass = c.FMOD_DSP_TYPE_HIGHPASS,

    echo = c.FMOD_DSP_TYPE_ECHO,

    fader = c.FMOD_DSP_TYPE_FADER,

    flange = c.FMOD_DSP_TYPE_FLANGE,

    distortion = c.FMOD_DSP_TYPE_DISTORTION,

    normalize = c.FMOD_DSP_TYPE_NORMALIZE,

    limiter = c.FMOD_DSP_TYPE_LIMITER,

    param_eq = c.FMOD_DSP_TYPE_PARAMEQ,

    pitch_shift = c.FMOD_DSP_TYPE_PITCHSHIFT,

    chorus = c.FMOD_DSP_TYPE_CHORUS,

    vst_plugin = c.FMOD_DSP_TYPE_VSTPLUGIN,

    winamp_plugin = c.FMOD_DSP_TYPE_WINAMPPLUGIN,

    it_echo = c.FMOD_DSP_TYPE_ITECHO,

    compressor = c.FMOD_DSP_TYPE_COMPRESSOR,

    sfx_reverb = c.FMOD_DSP_TYPE_SFXREVERB,

    low_pass_simple = c.FMOD_DSP_TYPE_LOWPASS_SIMPLE,

    delay = c.FMOD_DSP_TYPE_DELAY,

    tremolo = c.FMOD_DSP_TYPE_TREMOLO,

    ladspa_plugin = c.FMOD_DSP_TYPE_LADSPAPLUGIN,

    send = c.FMOD_DSP_TYPE_SEND,

    return_ = c.FMOD_DSP_TYPE_RETURN,

    high_pass_simple = c.FMOD_DSP_TYPE_HIGHPASS_SIMPLE,

    pan = c.FMOD_DSP_TYPE_PAN,

    three_eq = c.FMOD_DSP_TYPE_THREE_EQ,

    fft = c.FMOD_DSP_TYPE_FFT,

    loudness_meter = c.FMOD_DSP_TYPE_LOUDNESS_METER,

    envelope_follower = c.FMOD_DSP_TYPE_ENVELOPEFOLLOWER,

    convolution_reverb = c.FMOD_DSP_TYPE_CONVOLUTIONREVERB,

    channel_mix = c.FMOD_DSP_TYPE_CHANNELMIX,

    transceiver = c.FMOD_DSP_TYPE_TRANSCEIVER,

    object_pan = c.FMOD_DSP_TYPE_OBJECTPAN,

    multi_band_eq = c.FMOD_DSP_TYPE_MULTIBAND_EQ,

    max = c.FMOD_DSP_TYPE_MAX,

    _,
};

pub const CallbackType = enum(c.FMOD_DSP_CALLBACK_TYPE) {
    data_parameter_release = c.FMOD_DSP_CALLBACK_DATAPARAMETERRELEASE,
    max = c.FMOD_DSP_CALLBACK_MAX,
    _,
};

pub const CallbackData = union(enum) {
    data_parameter_release: c.FMOD_DSP_DATA_PARAMETER_INFO,
    nothing,
};

pub const Callback = fn (
    dsp: DSP,
    typ: CallbackType,
    data: CallbackData,
) c.FMOD_RESULT;

pub fn addInput(
    self: DSP,
    p: struct {
        /// The input DSP.
        input: DSP,
        /// The type of connection. Defaults to standard.
        typ: Connection.Type = .standard,
    },
) err.FmodError!Connection {
    var connection: ?*c.FMOD_DSPCONNECTION = null;
    try err.resultToError(c.FMOD_DSP_AddInput(
        self.ptr,
        p.input.ptr,
        &connection,
        @intFromEnum(p.typ),
    ));
    return Connection{ .ptr = connection };
}

pub fn disconnectAll(
    self: DSP,
    inputs: bool,
    outputs: bool,
) err.FmodError!void {
    try err.resultToError(c.FMOD_DSP_DisconnectAll(
        self.ptr,
        @intFromBool(inputs),
        @intFromBool(outputs),
    ));
}

pub fn disconnectFrom(
    self: DSP,
    target: DSP,
    conn: ?Connection,
) err.FmodError!void {
    try err.resultToError(c.FMOD_DSP_DisconnectFrom(
        self.ptr,
        target.ptr,
        if (conn) |cn| cn.ptr else null,
    ));
}

pub fn getInfo(self: DSP) err.FmodError!struct {
    name: [32:0]u8,
    version: c_uint,
    channels: c_int,
    config_width: c_int,
    config_height: c_int,
} {
    var ret = std.mem.zeroes(comptime @typeInfo(
        @typeInfo(@TypeOf(getInfo)).Fn.return_type.?,
    ).ErrorUnion.payload);
    try err.resultToError(c.FMOD_DSP_GetInfo(
        self.ptr,
        @ptrCast(&ret.name),
        &ret.version,
        &ret.channels,
        &ret.config_width,
        &ret.config_height,
    ));
    return ret;
}

pub fn getSystem(self: DSP) err.FmodError!System {
    var sys_ptr: ?*c.FMOD_SYSTEM = undefined;
    try err.resultToError(c.FMOD_DSP_GetSystemObject(self.ptr, &sys_ptr));
    return System{ .system_ptr = sys_ptr };
}

pub fn setCallback(self: DSP, comptime callback: Callback) err.FmodError!void {
    const cb = struct {
        fn actualCallback(
            c_dsp: ?*c.FMOD_DSP,
            cb_type: c.FMOD_DSP_CALLBACK_TYPE,
            data: ?*anyopaque,
        ) callconv(@import("../root.zig").fmodCallConv) c.FMOD_RESULT {
            const typ: CallbackType = @enumFromInt(cb_type);
            return callback(
                DSP{ .ptr = c_dsp },
                typ,
                switch (typ) {
                    .data_parameter_release => CallbackData{
                        .data_parameter_release = data.*,
                    },
                },
            );
        }
    };
    try err.resultToError(c.FMOD_DSP_SetCallback(self.ptr, &(cb.actualCallback)));
}

pub fn reset(self: DSP) err.FmodError!void {
    try err.resultToError(c.FMOD_DSP_Reset(self.ptr));
}

pub fn release(self: DSP) err.FmodError!void {
    try err.resultToError(c.FMOD_DSP_Release(self.ptr));
}

test {
    std.testing.refAllDecls(@This());
}
