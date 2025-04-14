module mc.protocol.packet.play.server.set_center_chunk;

import mc.protocol.packet.base : Packet;
import mc.protocol.packet.play.server : PacketType;
import mc.protocol.stream_utils : writeBytes, writeVar;

@safe:

class SetCenterChunkPacket : Packet
{
    enum PacketType ct_packetType = PacketType.setCenterChunk;

    private int m_x;
    private int m_z;

    this(int x, int z)
    {
        m_x = x;
        m_z = z;
    }

    override
    void serialize(ref const(ubyte)[] output) const
    {
        const(ubyte)[] content;
        content.writeVar!int(ct_packetType);
        content.writeVar!int(m_x);
        content.writeVar!int(m_z);

        output.writeVar!int(cast(int) content.length);
        output.writeBytes(content);
    }
}
