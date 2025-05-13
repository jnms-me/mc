module mc.protocol.packet.play.client.set_player_position_rotation;

import mc.protocol.packet.play.client : Protocol;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;

@safe:

final
class SetPlayerPositionRotationPacket
{
    static assert(isClientPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.setPlayerPositionRotation;

scope:
pure:
    private nothrow @nogc
    this()
    {
    }

    static nothrow
    typeof(this) deserialize(scope ref InputStream)
    {
        return new typeof(this);
    }
}
