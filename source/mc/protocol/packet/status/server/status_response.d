module mc.protocol.packet.status.server.status_response;

import std.json : JSONValue;

import mc.protocol.packet.status.server : PacketType;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class StatusResponsePacket
{
    static assert(isServerPacket!(typeof(this)));

    enum PacketType ct_packetType = PacketType.statusResponse;

    private string m_jsonString;

    this(in JSONValue json)
    {
        m_jsonString = json.toString;
    }

    string getJsonString() const
        => m_jsonString;

    void serialize(ref OutputStream output) const
    {
        output.writePrefixedString(m_jsonString);
    }
}
