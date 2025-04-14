module mc.protocol.packet.status.server.status_response;

import std.json : JSONValue;

import mc.protocol.packet.base : Packet;
import mc.protocol.packet.status.server : PacketType;
import mc.protocol.stream_utils : write, writeBytes, writeString, writeVar;

@safe:

class StatusResponsePacket : Packet
{
    enum PacketType ct_packetType = PacketType.statusResponse;

    private string m_jsonString;

    this(in JSONValue json)
    {
        m_jsonString = json.toString;
    }

    string getJsonString() const
        => m_jsonString;

    override
    void serialize(ref const(ubyte)[] output) const
    {
        const(ubyte)[] content;
        content.writeVar!int(ct_packetType);
        content.writeString(m_jsonString);

        output.writeVar!int(cast(int) content.length);
        output.writeBytes(content);
    }
}
