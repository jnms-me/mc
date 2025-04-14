module mc.protocol.packet.base;

import std.exception : enforce;

@safe:

class Packet
{
    void serialize(ref const(ubyte)[] output)
    {
        enforce(false, "Not implemented");
        assert(false);
    }

    static
    typeof(this) deserialize(ref const(ubyte)[] input)
    {
        enforce(false, "Not implemented");
        assert(false);
    }
}
