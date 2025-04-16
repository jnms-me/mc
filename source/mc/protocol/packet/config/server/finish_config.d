module mc.protocol.packet.config.server.finish_config;

import mc.protocol.packet.config.server : PacketType;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class FinishConfigPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum PacketType ct_packetType = PacketType.finishConfig;

    this()
    {
    }

    void serialize(ref OutputStream output) const
    {
    }
}
