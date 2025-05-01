module mc.protocol.packet.play.client.player_input;

import mc.protocol.packet.play.client : Protocol;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;

@safe:

final
class PlayerInputPacket
{
    static assert(isClientPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.playerInput;

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
