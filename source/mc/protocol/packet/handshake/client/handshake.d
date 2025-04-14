module mc.protocol.packet.handshake.client.handshake;

import mc.protocol.packet.base : Packet;
import mc.protocol.stream_utils : read, readBytes, readString, readVar;

@safe:

class HandshakePacket : Packet
{
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
    typeof(this) deserialize(ref const(ubyte)[] input)
    {
        typeof(this) instance = new typeof(this);

        instance.m_protocolVersion = input.readVar!int;
        instance.m_serverAddress = input.readString;
        instance.m_port = input.read!ushort;
        instance.m_nextState = input.readVar!int;

        return instance;
    }
}
