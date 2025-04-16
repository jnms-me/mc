module mc.protocol.packet.login.server.login_success;

import std.uuid : UUID;

import mc.protocol.packet.login.server : PacketType;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class LoginSuccessPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum PacketType ct_packetType = PacketType.loginSuccess;

    private UUID m_uuid;
    private string m_username;

    this(UUID uuid, string username)
    {
        m_uuid = uuid;
        m_username = username;
    }

    UUID getUuid() const
        => m_uuid;

    string getUsername() const
        => m_username;

    void serialize(ref OutputStream output) const
    {
        output.write(m_uuid.data);
        output.writePrefixedString(m_username);
        output.writeVar!int(0); // An empty properties array
    }
}
