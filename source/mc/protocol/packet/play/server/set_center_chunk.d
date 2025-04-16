module mc.protocol.packet.play.server.set_center_chunk;

import mc.protocol.packet.play.server : PacketType;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class SetCenterChunkPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum PacketType ct_packetType = PacketType.setCenterChunk;

    private int m_x;
    private int m_z;

    this(int x, int z)
    {
        m_x = x;
        m_z = z;
    }

    void serialize(ref OutputStream output) const
    {
        output.writeVar!int(m_x);
        output.writeVar!int(m_z);
    }
}
