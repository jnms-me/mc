module mc.protocol.packet.status.server.pong_response;

import mc.protocol.packet.base : Packet;
import mc.protocol.packet.status.server : PacketType;
import mc.protocol.stream_utils : write, writeBytes, writeString, writeVar;

@safe:

class PongResponsePacket : Packet
{
    enum PacketType ct_packetType = PacketType.pongResponse;

    private ulong m_payload;

    this(in ulong payload)
    {
        m_payload = payload;
    }

    ulong getPayload() const
        => m_payload;

    override
    void serialize(ref const(ubyte)[] output) const
    {
        const(ubyte)[] content;
        content.writeVar!int(ct_packetType);
        content.write!ulong(m_payload);

        output.writeVar!int(cast(int) content.length);
        output.writeBytes(content);
    }
}
