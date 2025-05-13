module mc.protocol.packet.config.client.ack_finish_config;

import mc.protocol.packet.config.client : Protocol;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;

@safe:

final
class AckFinishConfigPacket
{
    static assert(isClientPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.ackFinishConfig;

scope:
pure:
    private nothrow @nogc
    this()
    {
    }

    static nothrow
    typeof(this) deserialize(scope ref InputStream input)
    {
        return new typeof(this);
    }
}
