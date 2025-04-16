module mc.protocol.packet.login.client.login_start;

import std.uuid : UUID;

import mc.protocol.packet.login.client : PacketType;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;

@safe:

final
class LoginStartPacket
{
    static assert(isClientPacket!(typeof(this)));

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
    typeof(this) deserialize(ref InputStream input)
    {
        typeof(this) instance = new typeof(this);

        instance.m_userName = input.readPrefixedString;
        instance.m_uuid = UUID(input.read!(ubyte[16]));

        return instance;
    }
}
