module mc.protocol.packet.login.client.login_start;

import std.uuid : UUID;

import mc.protocol.packet.base : Packet;
import mc.protocol.packet.login.client : PacketType;
import mc.protocol.stream_utils : read, readBytes, readString, readVar;

@safe:

class LoginStartPacket : Packet
{
    enum PacketType ct_packetType = PacketType.loginStart;

    private string m_userName;
    private UUID m_uuid;

    private
    this()
    {
    }

    string getUserName() const
        => m_userName;

    UUID getUuid() const
        => m_uuid;

    static
    typeof(this) deserialize(ref const(ubyte)[] input)
    {
        typeof(this) instance = new typeof(this);

        instance.m_userName = input.readString;
        instance.m_uuid = UUID(input.read!(ubyte[16]));

        return instance;
    }
}
