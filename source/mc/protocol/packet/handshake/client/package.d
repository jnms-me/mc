module mc.protocol.packet.handshake.client;

public import mc.protocol.packet.handshake.client.handshake : HandshakePacket;

@safe:

enum Protocol : int
{
    @HandshakePacket handshake  = 0x00,
                     legacyPing = 0x7A,
}
