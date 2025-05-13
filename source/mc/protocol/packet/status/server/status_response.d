module mc.protocol.packet.status.server.status_response;

import std.json : JSONValue;

import mc.protocol.packet.status.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class StatusResponsePacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.statusResponse;

    private
    {
        string m_jsonString;
    }

scope:
pure:
    nothrow @nogc
    this(in string jsonString)
    {
        m_jsonString = jsonString;
    }

    nothrow @nogc
    string getJsonString() const
        => m_jsonString;

    nothrow
    void serialize(scope ref OutputStream output) const
    {
        output.writePrefixedString(m_jsonString);
    }
}
