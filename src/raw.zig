pub usingnamespace @import("fmod-raw");
const c = @import("fmod-raw");

pub const FMOD_PRESET_OFF = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 1000.0,
    .EarlyDelay = 7.0,
    .LateDelay = 11.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 100.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 20.0,
    .EarlyLateMix = 96.0,
    .WetLevel = -80.0,
};

pub const FMOD_PRESET_GENERIC = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 1500.0,
    .EarlyDelay = 7.0,
    .LateDelay = 11.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 83.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 14500.0,
    .EarlyLateMix = 96.0,
    .WetLevel = -8.0,
};

pub const FMOD_PRESET_PADDEDCELL = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 170.0,
    .EarlyDelay = 1.0,
    .LateDelay = 2.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 10.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 160.0,
    .EarlyLateMix = 84.0,
    .WetLevel = -7.8,
};

pub const FMOD_PRESET_ROOM = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 400.0,
    .EarlyDelay = 2.0,
    .LateDelay = 3.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 83.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 6050.0,
    .EarlyLateMix = 88.0,
    .WetLevel = -9.4,
};

pub const FMOD_PRESET_BATHROOM = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 1500.0,
    .EarlyDelay = 7.0,
    .LateDelay = 11.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 54.0,
    .Diffusion = 100.0,
    .Density = 60.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 2900.0,
    .EarlyLateMix = 83.0,
    .WetLevel = 0.5,
};

pub const FMOD_PRESET_LIVINGROOM = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 500.0,
    .EarlyDelay = 3.0,
    .LateDelay = 4.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 10.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 160.0,
    .EarlyLateMix = 58.0,
    .WetLevel = -19.0,
};

pub const FMOD_PRESET_STONEROOM = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 2300.0,
    .EarlyDelay = 12.0,
    .LateDelay = 17.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 64.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 7800.0,
    .EarlyLateMix = 71.0,
    .WetLevel = -8.5,
};

pub const FMOD_PRESET_AUDITORIUM = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 4300.0,
    .EarlyDelay = 20.0,
    .LateDelay = 30.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 59.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 5850.0,
    .EarlyLateMix = 64.0,
    .WetLevel = -11.7,
};

pub const FMOD_PRESET_CONCERTHALL = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 3900.0,
    .EarlyDelay = 20.0,
    .LateDelay = 29.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 70.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 5650.0,
    .EarlyLateMix = 80.0,
    .WetLevel = -9.8,
};

pub const FMOD_PRESET_CAVE = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 2900.0,
    .EarlyDelay = 15.0,
    .LateDelay = 22.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 100.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 20000.0,
    .EarlyLateMix = 59.0,
    .WetLevel = -11.3,
};

pub const FMOD_PRESET_ARENA = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 7200.0,
    .EarlyDelay = 20.0,
    .LateDelay = 30.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 33.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 4500.0,
    .EarlyLateMix = 80.0,
    .WetLevel = -9.6,
};

pub const FMOD_PRESET_HANGAR = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 10000.0,
    .EarlyDelay = 20.0,
    .LateDelay = 30.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 23.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 3400.0,
    .EarlyLateMix = 72.0,
    .WetLevel = -7.4,
};

pub const FMOD_PRESET_CARPETTEDHALLWAY = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 300.0,
    .EarlyDelay = 2.0,
    .LateDelay = 30.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 10.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 500.0,
    .EarlyLateMix = 56.0,
    .WetLevel = -24.0,
};

pub const FMOD_PRESET_HALLWAY = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 1500.0,
    .EarlyDelay = 7.0,
    .LateDelay = 11.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 59.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 7800.0,
    .EarlyLateMix = 87.0,
    .WetLevel = -5.5,
};

pub const FMOD_PRESET_STONECORRIDOR = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 270.0,
    .EarlyDelay = 13.0,
    .LateDelay = 20.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 79.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 9000.0,
    .EarlyLateMix = 86.0,
    .WetLevel = -6.0,
};

pub const FMOD_PRESET_ALLEY = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 1500.0,
    .EarlyDelay = 7.0,
    .LateDelay = 11.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 86.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 8300.0,
    .EarlyLateMix = 80.0,
    .WetLevel = -9.8,
};

pub const FMOD_PRESET_FOREST = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 1500.0,
    .EarlyDelay = 162.0,
    .LateDelay = 88.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 54.0,
    .Diffusion = 79.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 760.0,
    .EarlyLateMix = 94.0,
    .WetLevel = -12.3,
};

pub const FMOD_PRESET_CITY = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 1500.0,
    .EarlyDelay = 7.0,
    .LateDelay = 11.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 67.0,
    .Diffusion = 50.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 4050.0,
    .EarlyLateMix = 66.0,
    .WetLevel = -26.0,
};

pub const FMOD_PRESET_MOUNTAINS = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 1500.0,
    .EarlyDelay = 300.0,
    .LateDelay = 100.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 21.0,
    .Diffusion = 27.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 1220.0,
    .EarlyLateMix = 82.0,
    .WetLevel = -24.0,
};

pub const FMOD_PRESET_QUARRY = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 1500.0,
    .EarlyDelay = 61.0,
    .LateDelay = 25.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 83.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 3400.0,
    .EarlyLateMix = 100.0,
    .WetLevel = -5.0,
};

pub const FMOD_PRESET_PLAIN = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 1500.0,
    .EarlyDelay = 179.0,
    .LateDelay = 100.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 50.0,
    .Diffusion = 21.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 1670.0,
    .EarlyLateMix = 65.0,
    .WetLevel = -28.0,
};

pub const FMOD_PRESET_PARKINGLOT = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 1700.0,
    .EarlyDelay = 8.0,
    .LateDelay = 12.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 10.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 20000.0,
    .EarlyLateMix = 56.0,
    .WetLevel = -19.5,
};

pub const FMOD_PRESET_SEWERPIPE = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 2800.0,
    .EarlyDelay = 14.0,
    .LateDelay = 21.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 14.0,
    .Diffusion = 80.0,
    .Density = 60.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 3400.0,
    .EarlyLateMix = 66.0,
    .WetLevel = 1.2,
};

pub const FMOD_PRESET_UNDERWATER = c.FMOD_REVERB_PROPERTIES{
    .DecayTime = 1500.0,
    .EarlyDelay = 7.0,
    .LateDelay = 11.0,
    .HFReference = 5000.0,
    .HFDecayRatio = 10.0,
    .Diffusion = 100.0,
    .Density = 100.0,
    .LowShelfFrequency = 250.0,
    .LowShelfGain = 0.0,
    .HighCut = 500.0,
    .EarlyLateMix = 92.0,
    .WetLevel = 7.0,
};
