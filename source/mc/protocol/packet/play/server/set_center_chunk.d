module mc.protocol.packet.play.server.set_center_chunk;

import mc.protocol.packet.play.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class SetCenterChunkPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.setCenterChunk;

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
