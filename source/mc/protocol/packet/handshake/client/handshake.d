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

    private int m_protocolVersion;
    private string m_serverAddress;
    private ushort m_port;
    private int m_nextState;

    private
    this()
    {
    }

    int getProtocolVersion() const
        => m_protocolVersion;

    string getServerAddress() const
        => m_serverAddress;

    ushort getPort() const
        => m_port;

    int getNextState() const
        => m_nextState;

    static
    typeof(this) deserialize(ref InputStream input)
    {
        typeof(this) instance = new typeof(this);

        instance.m_protocolVersion = input.readVar!int;
        instance.m_serverAddress = input.readPrefixedString;
        instance.m_port = input.read!ushort;
        instance.m_nextState = input.readVar!int;

        return instance;
    }
}
