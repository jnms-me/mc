module mc.protocol.packet.status.client.ping_request;

import std.uuid : UUID;

import mc.protocol.packet.base : Packet;
import mc.protocol.packet.status.client : PacketType;
import mc.protocol.stream_utils : read, readBytes, readString, readVar;

@safe:

class PingRequestPacket : Packet
{
    enum PacketType ct_packetType = PacketType.pingRequest;

    private ulong m_payload;

    private
    this()
    {
    }

    ulong getPayload() const
        => m_payload;

    static
    typeof(this) deserialize(ref const(ubyte)[] input)
    {
        typeof(this) instance = new typeof(this);

        instance.m_payload = input.read!ulong;

        return instance;
    }
}
