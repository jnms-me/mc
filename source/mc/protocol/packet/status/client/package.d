module mc.protocol.packet.status.client;

import mc.protocol.packet.traits : isClientPacket;

public import mc.protocol.packet.status.client.ping_request : PingRequestPacket;
public import mc.protocol.packet.status.client.status_request : StatusRequestPacket;

@safe:

enum Protocol : int
{
    @StatusRequestPacket statusRequest = 0x00,
    @PingRequestPacket   pingRequest   = 0x01,
}
