module mc.protocol.packet.status.server.pong_response;

import mc.protocol.packet.status.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class PongResponsePacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.pongResponse;

    private
    {
        ulong m_payload;
    }

scope:
pure:
    nothrow @nogc
    this(in ulong payload)
    {
        m_payload = payload;
    }

    nothrow @nogc
    ulong getPayload() const
        => m_payload;

    nothrow
    void serialize(scope ref OutputStream output) const
    {
        output.write!ulong(m_payload);
    }
}
