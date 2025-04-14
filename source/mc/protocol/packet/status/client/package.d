module mc.protocol.packet.status.client;

public import mc.protocol.packet.status.client.ping_request : PingRequestPacket;
public import mc.protocol.packet.status.client.status_request : StatusRequestPacket;

@safe:

enum PacketType : int
{
    statusRequest = 0x00,
    pingRequest   = 0x01,
}
