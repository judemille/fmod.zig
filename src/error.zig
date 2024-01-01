const c = @import("raw.zig");
const std = @import("std");

/// Non-specialized errors.
pub const GeneralError = error{
    /// Tried to call a function on a data type that does not allow this
    /// type of functionality (i.e. calling `Sound.lock` on a streaming `Sound`).
    BadCommand,

    /// Error trying to allocate a `Channel`.
    ChannelAlloc,

    /// The specified `Channel` has been reused to play another `Sound`.
    ChannelStolen,

    /// DMA failure. See debug output for more information.
    DMA,

    /// Unsupported file or audio format.
    Format,

    /// There is a version mismatch between the FMOD header and either the
    /// FMOD Studio library or the FMOD Core library.
    HeaderMismatch,

    /// FMOD was not initialized correctly to support this function.
    Initialization,

    /// Cannot call this command after `System.init`.
    Initialized,

    /// An error occurred that wasn't supposed to. Contact support.
    Internal,

    /// Reached maximum audible playback count for this `Sound`'s `SoundGroup`.
    MaxAudible,

    /// Not enough memory or resources.
    Memory,

    /// Can't use `FMOD_OPENMEMORY_POINT` on non-PCM source data, or
    /// non mp3/xma/adpcm data if `FMOD_CREATECOMPRESSEDSAMPLE` was used.
    MemoryCantPoint,

    /// Tried to call a command on a 2D `Sound` when the command was meant
    /// for 3D `Sound`.
    Needs3D,

    /// Tried to use a feature that requires hardware support.
    NeedsHardware,

    /// Operation could not be performed because the specified `Sound`/`DSP`
    /// connection is not ready.
    NotReady,

    /// An error occurred trying to initialize the recording device.
    Record,

    /// The specified recording driver has been disconnected.
    RecordDisconnected,

    /// The specified tag could not be found, or there are no tags.
    TagNotFound,

    /// The `Sound` created exceeds the allowable input channel count. This can
    /// be increased using the `maxinputchannels` parameter in `System.setSoftwareFormat`.
    TooManyChannels,

    /// The retrieved string is too long to fit in the supplied buffer and has been truncated.
    Truncated,

    /// Something in FMOD hasn't been implemented when it should be! Contact support!
    Unimplemented,

    /// This command failed because `System.init` or `System.setDriver` was not called.
    Uninitialized,

    /// A command issued was not supported by this object. Possibly a plugin
    /// without certain callbacks specified.
    Unsupported,

    /// The version number of this fule format is not supported.
    Version,

    /// The `studio.System` object is not yet initialized.
    StudioUninitialized,

    /// The specified resource is not loaded, so it can't be unloaded.
    StudioNotLoaded,

    /// The specified resource is already locked.
    AlreadyLocked,

    /// The specified resource is not locked, so it can't be unlocked.
    NotLocked,

    /// The length provided exceeds the allowable limit.
    TooManySamples,

    /// These bindings don't recognize this FMOD error.
    UnrecognizedFmodError,

    _,
};

/// DSP-related errors.
pub const DspError = error{
    /// DSP connection error. Connection possibly caused a cyclic dependency
    /// or connected DSPs with incompatible buffer counts.
    DspConnection,

    /// DSP return code from a DSP process query callback. Tells mixer not to
    /// call the process callback and thereforew not consume CPU. Use this to
    /// optimize the DSP graph.
    DspDontProcess,

    /// DSP format error. A DSP unit may have attempted to connect to this
    /// network with the wrong format, or a matrix may have been set with the
    /// wrong size of the target unit has a specified channel map.
    DspFormat,

    /// DSP is already in the mixer's DSP network. It must be removed before
    /// being reinserted or released.
    DspInUse,

    /// DSP connection error. Couldn't find the DSP unit specified.
    DspNotFound,

    /// DSP operation error. Cannot perform operation on this DSP, as it is
    /// reserved by the system.
    DspReserved,

    /// DSP return code from a DSP process query callback. Tells mixer silence
    /// would be produced from read, so go idle and not consume CPU. Use this
    /// to optimize the DSP graph.
    DspSilence,

    /// DSP operation cannot be performed on a DSP of this type.
    DspType,

    _,
};

/// File-related errors.
pub const FileError = error{
    /// Error loading file.
    FileBad,

    /// Couldn't perform seek operation. This is a limitation of the medium
    /// (ie netstreams) or the file format.
    FileCouldNotSeek,

    /// Media was ejected while reading.
    FileDiskEjected,

    /// End of file unexpectedly reached while trying to read essential data (truncated?).
    FileEof,

    /// End of current chunk reached while trying to read data.
    FileEndOfData,

    /// File not found.
    FileNotFound,

    _,
};

/// HTTP-related errors.
pub const HttpError = error{
    /// Catch-all for HTTP errors not otherwise listed.
    HttpGeneral,

    /// The specified resource requires authentication or is forbidden.
    HttpAccess,

    /// Proxy authentication is required to access the specified resource.
    HttpProxyAuth,

    /// An HTTP server error occurred.
    HttpServerError,

    /// The HTTP request timed out.
    HttpTimeout,

    _,
};

/// Errors relating to invalid parameters.
pub const InvalidParameterError = error{
    /// Value passed in was NaN, Inf, or denormalized float.
    InvalidFloat,

    /// An invalid object handle was used.
    InvalidHandle,

    /// An invalid parameter was passed to this function.
    InvalidParam,

    /// An invalid seek position was passed to this function.
    InvalidPosition,

    /// An invalid speaker was passed to this function based on the current
    /// speaker mode.
    InvalidSpeaker,

    /// The syncpoint did not come from this `Sound` handle.
    InvalidSyncpoint,

    /// Tried to call a function on a thread that is not supported.
    InvalidThread,

    /// The vectors passed in are not unit length, or perpendicular.
    InvalidVector,

    /// An invalid string was passed to this function.
    InvalidString,

    _,
};

/// Network-related errors.
pub const NetError = error{
    /// Couldn't connect to the specified host.
    NetConnect,

    /// Catch-all for socket errors not otherwise listed.
    NetSocket,

    /// The specified URL couldn't be resolved.
    NetUrl,

    /// Operation on a non-blocking socket couldn't complete immediately.
    NetWouldBlock,

    _,
};

/// Output-related errors.
pub const OutputError = error{
    /// The output device is already in use and cannot be reused.
    OutputAllocated,

    /// Error creating hardware sound buffer.
    OutputCreateBuffer,

    /// A call to a standard sound card driver failed, which could possibly
    /// mean a bug in the driver (or resources were missing/exhausted).
    OutputDriverCall,

    /// The sound card does not support the specified format.
    OutputFormat,

    /// Error initializing output device.
    OutputInit,

    /// The output device has no drivers installed. If pre-init,
    /// `FMOD_OUTPUT_NOSOUND` is selected as the output mode. If post-init, the
    /// function just fails.
    OutputNoDrivers,

    _,
};

/// Plugin-related errors.
pub const PluginError = error{
    /// An unspecified error has been returned from a plugin.
    PluginUnspecified,

    /// A requested output, DSP unit type, or codec was not available.
    PluginMissing,

    /// A resource that the plugin requires cannot be allocated
    /// or found. (ie the DLS file for MIDI playback).
    PluginResource,

    /// A plugin was build with an unsupported SDK version.
    PluginVersion,

    _,
};

/// Reverb-related errors.
pub const ReverbError = error{
    /// Reverb properties cannot be set on this `Channel` because a parent
    /// `ChannelGroup` owns the reverb connection.
    ReverbChannelGroup,

    /// Specified instance in `FMOD_REVERB_PROPERTIES` couldn't be set.
    /// Most likely because it is an invalid instance number, or the reverb doesn't exist.
    ReverbInstance,

    _,
};

/// Subsound-related errors.
pub const SubsoundError = error{
    /// The `Sound` referenced contains subsounds when it shouldn't have, or it
    /// doesn't contain subsounds when it should have. The operation may also
    /// not be able to be performed on a parent `Sound`.
    Subsounds,

    /// The subsound is already being used by another `Sound`. You cannot have
    /// more than one parent to a `Sound`. Null out the other parent's entry first.
    SubsoundAllocated,

    /// Shared subsounds cannot be replaced or moved from their parent stream,
    /// such as when the parent stream is an FSB file.
    SubsoundCantMove,

    _,
};

/// Event-related errors.
pub const EventError = error{
    /// The specified bank has already been loaded.
    EventAlreadyLoaded,

    /// The live update connection failed due to the game already being connected.
    EventLiveUpdateBusy,

    /// The live update connection failed due to the game data being
    /// out of sync with the tool.
    EventLiveUpdateMismatch,

    /// The live update connection timed out.
    EventLiveUpdateTimeout,

    /// The requested event, parameter, bus, or VCA could not be found.
    EventNotFound,

    _,
};

/// Everything in `FMOD_RESULT`, except `FMOD_OK`.
pub const FmodError = GeneralError || DspError || FileError || HttpError || InvalidParameterError || NetError || OutputError || PluginError || ReverbError || SubsoundError || EventError;

pub fn resultToError(res: c.FMOD_RESULT) FmodError!void {
    switch (res) {
        c.FMOD_OK => {},
        c.FMOD_ERR_BADCOMMAND => return GeneralError.BadCommand,
        c.FMOD_ERR_CHANNEL_ALLOC => return GeneralError.ChannelAlloc,
        c.FMOD_ERR_CHANNEL_STOLEN => return GeneralError.ChannelStolen,
        c.FMOD_ERR_DMA => return GeneralError.DMA,
        c.FMOD_ERR_DSP_CONNECTION => return DspError.DspConnection,
        c.FMOD_ERR_DSP_DONTPROCESS => return DspError.DspDontProcess,
        c.FMOD_ERR_DSP_FORMAT => return DspError.DspFormat,
        c.FMOD_ERR_DSP_INUSE => return DspError.DspInUse,
        c.FMOD_ERR_DSP_NOTFOUND => return DspError.DspNotFound,
        c.FMOD_ERR_DSP_RESERVED => return DspError.DspReserved,
        c.FMOD_ERR_DSP_SILENCE => return DspError.DspSilence,
        c.FMOD_ERR_DSP_TYPE => return DspError.DspType,
        c.FMOD_ERR_FILE_BAD => return FileError.FileBad,
        c.FMOD_ERR_FILE_COULDNOTSEEK => return FileError.FileCouldNotSeek,
        c.FMOD_ERR_FILE_DISKEJECTED => return FileError.FileDiskEjected,
        c.FMOD_ERR_FILE_EOF => return FileError.FileEof,
        c.FMOD_ERR_FILE_ENDOFDATA => return FileError.FileEndOfData,
        c.FMOD_ERR_FILE_NOTFOUND => return FileError.FileNotFound,
        c.FMOD_ERR_FORMAT => return GeneralError.Format,
        c.FMOD_ERR_HEADER_MISMATCH => return GeneralError.HeaderMismatch,
        c.FMOD_ERR_HTTP => return HttpError.HttpGeneral,
        c.FMOD_ERR_HTTP_ACCESS => return HttpError.HttpAccess,
        c.FMOD_ERR_HTTP_PROXY_AUTH => return HttpError.HttpProxyAuth,
        c.FMOD_ERR_HTTP_SERVER_ERROR => return HttpError.HttpServerError,
        c.FMOD_ERR_HTTP_TIMEOUT => return HttpError.HttpTimeout,
        c.FMOD_ERR_INITIALIZATION => return GeneralError.Initialization,
        c.FMOD_ERR_INITIALIZED => return GeneralError.Initialized,
        c.FMOD_ERR_INTERNAL => return GeneralError.Internal,
        c.FMOD_ERR_INVALID_FLOAT => return InvalidParameterError.InvalidFloat,
        c.FMOD_ERR_INVALID_HANDLE => return InvalidParameterError.InvalidHandle,
        c.FMOD_ERR_INVALID_PARAM => return InvalidParameterError.InvalidParam,
        c.FMOD_ERR_INVALID_POSITION => return InvalidParameterError.InvalidPosition,
        c.FMOD_ERR_INVALID_SPEAKER => return InvalidParameterError.InvalidSpeaker,
        c.FMOD_ERR_INVALID_SYNCPOINT => return InvalidParameterError.InvalidSyncpoint,
        c.FMOD_ERR_INVALID_THREAD => return InvalidParameterError.InvalidThread,
        c.FMOD_ERR_INVALID_VECTOR => return InvalidParameterError.InvalidVector,
        c.FMOD_ERR_MAXAUDIBLE => return GeneralError.MaxAudible,
        c.FMOD_ERR_MEMORY => return GeneralError.Memory,
        c.FMOD_ERR_MEMORY_CANTPOINT => return GeneralError.MemoryCantPoint,
        c.FMOD_ERR_NEEDS3D => return GeneralError.Needs3D,
        c.FMOD_ERR_NEEDSHARDWARE => return GeneralError.NeedsHardware,
        c.FMOD_ERR_NET_CONNECT => return NetError.NetConnect,
        c.FMOD_ERR_NET_SOCKET_ERROR => return NetError.NetSocket,
        c.FMOD_ERR_NET_URL => return NetError.NetUrl,
        c.FMOD_ERR_NET_WOULD_BLOCK => return NetError.NetWouldBlock,
        c.FMOD_ERR_NOTREADY => return GeneralError.NotReady,
        c.FMOD_ERR_OUTPUT_ALLOCATED => return OutputError.OutputAllocated,
        c.FMOD_ERR_OUTPUT_CREATEBUFFER => return OutputError.OutputCreateBuffer,
        c.FMOD_ERR_OUTPUT_DRIVERCALL => return OutputError.OutputDriverCall,
        c.FMOD_ERR_OUTPUT_FORMAT => return OutputError.OutputFormat,
        c.FMOD_ERR_OUTPUT_INIT => return OutputError.OutputInit,
        c.FMOD_ERR_OUTPUT_NODRIVERS => return OutputError.OutputNoDrivers,
        c.FMOD_ERR_PLUGIN => return PluginError.PluginUnspecified,
        c.FMOD_ERR_PLUGIN_MISSING => return PluginError.PluginMissing,
        c.FMOD_ERR_PLUGIN_RESOURCE => return PluginError.PluginResource,
        c.FMOD_ERR_PLUGIN_VERSION => return PluginError.PluginVersion,
        c.FMOD_ERR_RECORD => return GeneralError.Record,
        c.FMOD_ERR_REVERB_CHANNELGROUP => return ReverbError.ReverbChannelGroup,
        c.FMOD_ERR_REVERB_INSTANCE => return ReverbError.ReverbInstance,
        c.FMOD_ERR_SUBSOUNDS => return SubsoundError.Subsounds,
        c.FMOD_ERR_SUBSOUND_ALLOCATED => return SubsoundError.SubsoundAllocated,
        c.FMOD_ERR_SUBSOUND_CANTMOVE => return SubsoundError.SubsoundCantMove,
        c.FMOD_ERR_TAGNOTFOUND => return GeneralError.TagNotFound,
        c.FMOD_ERR_TOOMANYCHANNELS => return GeneralError.TooManyChannels,
        c.FMOD_ERR_TRUNCATED => return GeneralError.Truncated,
        c.FMOD_ERR_UNIMPLEMENTED => return GeneralError.Unimplemented,
        c.FMOD_ERR_UNINITIALIZED => return GeneralError.Uninitialized,
        c.FMOD_ERR_UNSUPPORTED => return GeneralError.Unsupported,
        c.FMOD_ERR_VERSION => return GeneralError.Version,
        c.FMOD_ERR_EVENT_ALREADY_LOADED => return EventError.EventAlreadyLoaded,
        c.FMOD_ERR_EVENT_LIVEUPDATE_BUSY => return EventError.EventLiveUpdateBusy,
        c.FMOD_ERR_EVENT_LIVEUPDATE_MISMATCH => return EventError.EventLiveUpdateMismatch,
        c.FMOD_ERR_EVENT_LIVEUPDATE_TIMEOUT => return EventError.EventLiveUpdateTimeout,
        c.FMOD_ERR_EVENT_NOTFOUND => return EventError.EventNotFound,
        c.FMOD_ERR_STUDIO_UNINITIALIZED => return GeneralError.StudioUninitialized,
        c.FMOD_ERR_STUDIO_NOT_LOADED => return GeneralError.StudioNotLoaded,
        c.FMOD_ERR_INVALID_STRING => return InvalidParameterError.InvalidString,
        c.FMOD_ERR_ALREADY_LOCKED => return GeneralError.AlreadyLocked,
        c.FMOD_ERR_NOT_LOCKED => return GeneralError.NotLocked,
        c.FMOD_ERR_RECORD_DISCONNECTED => return GeneralError.RecordDisconnected,
        c.FMOD_ERR_TOOMANYSAMPLES => return GeneralError.TooManySamples,
        else => return GeneralError.UnrecognizedFmodError,
    }
}

test {
    std.testing.refAllDecls(@This());
}
