module mc.protocol.enums;

@safe nothrow @nogc:

enum State : int
{
    handShake = 0,
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
