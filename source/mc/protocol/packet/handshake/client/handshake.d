module mc.protocol.packet.handshake.client.handshake;

import mc.protocol.packet.handshake.client : Protocol;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;

@safe:

final
class HandshakePacket
{
    static assert(isClientPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.handshake;

    private
    {
        int m_protocolVersion;
        string m_serverAddress;
        ushort m_port;
        int m_nextState;
    }

scope:
pure:
    private nothrow @nogc
    this()
    {
    }

    nothrow @nogc
    int getProtocolVersion() const
        => m_protocolVersion;

    nothrow @nogc
    string getServerAddress() const
        => m_serverAddress;

    nothrow @nogc
    ushort getPort() const
        => m_port;

    nothrow @nogc
    int getNextState() const
        => m_nextState;

    static
    typeof(this) deserialize(scope ref InputStream input)
    {
        typeof(this) instance = new typeof(this);

        instance.m_protocolVersion = input.readVar!int;
        instance.m_serverAddress = input.readPrefixedString;
        instance.m_port = input.read!ushort;
        instance.m_nextState = input.readVar!int;

        return instance;
    }
}
