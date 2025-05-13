module mc.protocol.packet.play.server.keep_alive;

import mc.protocol.packet.play.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class KeepAlivePacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.keepAlive;

    private
    {
        long m_id;
    }

scope:
pure:
    nothrow @nogc
    this(in long id)
    {
        m_id = id;
    }

    nothrow
    void serialize(scope ref OutputStream output) const
    {
        output.write!long(m_id);
    }
}
