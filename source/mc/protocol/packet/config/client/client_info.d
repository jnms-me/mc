module mc.protocol.packet.config.client.client_info;

import mc.protocol.packet.common.client.client_info : CommonClientInfoPacket;
import mc.protocol.packet.config.client : Protocol;

@safe:

final
class ClientInfoPacket
{
    mixin CommonClientInfoPacket!Protocol;
}
