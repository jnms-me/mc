module mc.protocol.packet.config.server.finish_config;

import mc.protocol.packet.base : Packet;
import mc.protocol.packet.config.server : PacketType;
import mc.protocol.stream_utils : write, writeBytes, writeString, writeVar;

@safe:

class FinishConfigPacket : Packet
{
    enum PacketType ct_packetType = PacketType.finishConfig;

    this()
    {
    }

    override
    void serialize(ref const(ubyte)[] output) const
    {
        const(ubyte)[] content;
        content.writeVar!int(ct_packetType);

        output.writeVar!int(cast(int) content.length);
        output.writeBytes(content);
    }
}
