module mc.protocol.packet.traits;

import std.meta : Filter;
import std.traits : isFinal, lvalueOf;

import mc.protocol.stream : InputStream, OutputStream;

@safe:

template isPacket(T)
{
    static if (
        is(T == class)
        && isFinal!T
        && is(typeof(T.ct_protocol) EnumValue == enum)
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

template getPacketImplForProtocolMember(alias member)
{
    alias attributes = __traits(getAttributes, member);
    alias filteredAttributes = Filter!(isClientPacket, attributes);
    static if (filteredAttributes.length == 0)
        static assert(false, "Protocol member has no packet class");
    static if (filteredAttributes.length == 1)
        alias getPacketImplForProtocolMember = filteredAttributes[0];
    else
        static assert(false, "Protocol member has multiple packet classes");
}