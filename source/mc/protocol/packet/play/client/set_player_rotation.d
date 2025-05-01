module mc.protocol.packet.play.client.set_player_rotation;

import mc.protocol.packet.play.client : Protocol;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;

@safe:

final
class SetPlayerRotationPacket
{
    static assert(isClientPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.setPlayerRotation;

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
