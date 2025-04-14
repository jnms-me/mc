module mc.protocol.packet.config.client.ack_finish_config;

import mc.protocol.packet.base : Packet;
import mc.protocol.packet.config.client : PacketType;
import mc.protocol.stream_utils : read, readBytes, readString, readVar;

@safe:

class AckFinishConfigPacket : Packet
{
    enum PacketType ct_packetType = PacketType.ackFinishConfig;

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
