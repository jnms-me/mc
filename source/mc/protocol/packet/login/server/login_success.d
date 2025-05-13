module mc.protocol.packet.login.server.login_success;

import std.uuid : UUID;

import mc.protocol.packet.login.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class LoginSuccessPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.loginSuccess;

    private
    {
        UUID m_uuid;
        string m_username;
    }

scope:
pure:
    nothrow @nogc
    this(UUID uuid, string username)
    {
        m_uuid = uuid;
        m_username = username;
    }

    nothrow @nogc
    UUID getUuid() const
        => m_uuid;

    nothrow @nogc
    string getUsername() const
        => m_username;

    nothrow
    void serialize(scope ref OutputStream output) const
    {
        output.write(m_uuid.data);
        output.writePrefixedString(m_username);
        output.writeVar!int(0); // An empty properties array
    }
}
