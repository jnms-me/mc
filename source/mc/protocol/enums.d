module mc.protocol.enums;

@safe nothrow @nogc:

enum State : int
{
    handshake = 0,
    status    = 1,
    login     = 2,
    transfer  = 3,
    config    = 4,
    play      = 5,
}

enum GameMode : ubyte
{
    survival  = 0x00,
    creative  = 0x01,
    adventure = 0x02,
    spectator = 0x03,
    unset     = 0xFF,
}

enum GameEvent : ubyte
{
    respawnPointUnavailable   = 0x00,
    startRain                 = 0x01,
    stopRain                  = 0x02,
    switchGameMode            = 0x03,
    winGame                   = 0x04,
    demoEvent                 = 0x05,
    arrowHitPlayer            = 0x06,
    rainLevelChange           = 0x07,
    thunderLevelChange        = 0x08,
    pufferFishStingEffect     = 0x09,
    elderGuardianEffect       = 0x0A,
    doImmediateRespawnChanged = 0x0B,
    doLimitedCraftingChanged  = 0x0C,
    waitForLevelChunks        = 0x0D,
}
