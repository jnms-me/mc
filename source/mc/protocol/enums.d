module mc.protocol.enums;

@safe nothrow @nogc:

enum GameMode : ubyte
{
    survival = 0x00,
    creative = 0x01,
    adventure = 0x02,
    spectator = 0x03,
    unset = 0xFF,
}
