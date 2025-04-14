module mc.protocol.packet.status.client.status_request;

import std.uuid : UUID;

import mc.protocol.packet.base : Packet;
import mc.protocol.packet.status.client : PacketType;
import mc.protocol.stream_utils : read, readBytes, readString, readVar;

@safe:

class StatusRequestPacket : Packet
{
    enum PacketType ct_packetType = PacketType.statusRequest;

    private
    this()
    {
    }

    static
    typeof(this) deserialize(ref const(ubyte)[] input)
    {
        return new typeof(this);
    }
}
