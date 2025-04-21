module mc.protocol.packet.status.server;

public import mc.protocol.packet.status.server.pong_response : PongResponsePacket;
public import mc.protocol.packet.status.server.status_response : StatusResponsePacket;

@safe:

enum Protocol : int
{
    statusResponse = 0x00,
    pongResponse   = 0x01,
}
