module mc.protocol.packet.login.client.ack_login_success;

import mc.protocol.packet.login.client : PacketType;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;

@safe:

final
class AckLoginSuccessPacket
{
    static assert(isClientPacket!(typeof(this)));

    enum PacketType ct_packetType = PacketType.ackLoginSuccess;

    private
    this()
    {
    }

    static
    typeof(this) deserialize(ref InputStream input)
    {
        return new typeof(this);
    }
}
