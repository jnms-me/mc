module mc.protocol.packet.login.client.ack_login_success;

import mc.protocol.packet.base : Packet;
import mc.protocol.packet.login.client : PacketType;
import mc.protocol.stream_utils : read, readBytes, readString, readVar;

@safe:

class AckLoginSuccessPacket : Packet
{
    enum PacketType ct_packetType = PacketType.ackLoginSuccess;

    private
    this()
    {
    }

    static
    typeof(this) deserialize(ref const(ubyte)[] input)
    {
        return new typeof(this);
    }
}
