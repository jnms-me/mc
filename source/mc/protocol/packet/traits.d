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
    && __traits(compiles, {InputStream input; T packet = T.deserialize(input);});


enum bool isServerPacket(T) =
    isPacket!T
    && __traits(compiles, {OutputStream output; T.init.serialize(output);});

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
