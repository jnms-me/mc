module mc.protocol.packet.status.client.ping_request;

import mc.protocol.packet.status.client : PacketType;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;

@safe:

final
class PingRequestPacket
{
    static assert(isClientPacket!(typeof(this)));

    enum PacketType ct_packetType = PacketType.pingRequest;

    private ulong m_payload;

    private
    this()
    {
    }

    ulong getPayload() const
        => m_payload;

    static
    typeof(this) deserialize(ref InputStream input)
    {
        typeof(this) instance = new typeof(this);

        instance.m_payload = input.read!ulong;

        return instance;
    }
}
