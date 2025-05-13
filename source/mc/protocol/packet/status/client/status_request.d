module mc.protocol.packet.status.client.status_request;

import mc.protocol.packet.status.client : Protocol;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;

@safe:

final
class StatusRequestPacket
{
    static assert(isClientPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.statusRequest;

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
