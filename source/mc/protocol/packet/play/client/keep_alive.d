module mc.protocol.packet.play.client.keep_alive;

import mc.protocol.packet.play.client : Protocol;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;

@safe:

final
class KeepAlivePacket
{
    static assert(isClientPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.keepAlive;

    private long m_id;

scope:
pure:
    private nothrow @nogc
    this()
    {
    }

    nothrow @nogc
    long getId() const
        => m_id;

    static
    typeof(this) deserialize(scope ref InputStream input)
    {
        typeof(this) instance = new typeof(this);

        instance.m_id = input.read!long;

        return instance;
    }
}
