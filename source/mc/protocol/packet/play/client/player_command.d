module mc.protocol.packet.play.client.player_command;

import mc.protocol.packet.play.client : Protocol;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;

@safe:

final
class ClientTickEndPacket
{
    static assert(isClientPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.clientTickEnd;

    private
    this()
    {
    }

    static
    typeof(this) deserialize(ref InputStream)
    {
        return new typeof(this);
    }
}
