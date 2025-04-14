module mc.protocol.packet.login.server.login_success;

import std.uuid : UUID;

import mc.protocol.packet.base : Packet;
import mc.protocol.packet.login.server : PacketType;
import mc.protocol.stream_utils : write, writeBytes, writeString, writeVar;

@safe:

class LoginSuccessPacket : Packet
{
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

    override
    void serialize(ref const(ubyte)[] output) const
    {
        const(ubyte)[] content;
        content.writeVar!int(ct_packetType);
        content.write(m_uuid.data);
        content.writeString(m_username);
        content.writeVar!int(0); // An empty properties array

        output.writeVar!int(cast(int) content.length);
        output.writeBytes(content);
    }
}
