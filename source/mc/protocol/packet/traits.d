module mc.protocol.packet.traits;

import std.traits : isFinal, lvalueOf;

import mc.protocol.stream : InputStream, OutputStream;

@safe:

final
template isPacket(T)
{
    static if (
        is(T == class)
        && isFinal!T
        && is(typeof(T.ct_packetType) EnumValue == enum)
        && is(EnumValue == int)
    )
        enum bool isPacket = true;
    else
        enum bool isPacket = false;
}

enum bool isClientPacket(T) =
    isPacket!T
    && is(typeof(&T.deserialize) == T function(ref InputStream));


enum bool isServerPacket(T) =
    isPacket!T
    && is(typeof(&(lvalueOf!T.serialize)) == void delegate(ref OutputStream) const);
