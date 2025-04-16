module mc.protocol.packet.config.client.ack_finish_config;

import mc.protocol.packet.config.client : PacketType;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;

@safe:

final
class AckFinishConfigPacket
{
    static assert(isClientPacket!(typeof(this)));

    enum PacketType ct_packetType = PacketType.ackFinishConfig;

    private
    this()
    {
    }

    static
    typeof(this) deserialize(ref InputStream input)
    {
        return new typeof(this);
    }
}
