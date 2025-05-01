module mc.protocol.packet.play.client.set_player_position;

import mc.protocol.packet.play.client : Protocol;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;

@safe:

final
class SetPlayerPositionPacket
{
    static assert(isClientPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.setPlayerPosition;

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
