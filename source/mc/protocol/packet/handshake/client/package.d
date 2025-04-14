module mc.protocol.packet.handshake.client;

public import mc.protocol.packet.handshake.client.handshake : HandshakePacket;

@safe:

enum PacketType : int
{
    handshake  = 0x00,
    legacyPing = 0x7A,
}
