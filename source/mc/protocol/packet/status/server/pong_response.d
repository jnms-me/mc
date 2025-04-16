module mc.protocol.packet.status.server.pong_response;

import mc.protocol.packet.status.server : PacketType;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class PongResponsePacket
{
    static assert(isServerPacket!(typeof(this)));

    enum PacketType ct_packetType = PacketType.pongResponse;

    private ulong m_payload;

    this(in ulong payload)
    {
        m_payload = payload;
    }

    ulong getPayload() const
        => m_payload;

    void serialize(ref OutputStream output) const
    {
        output.write!ulong(m_payload);
    }
}
