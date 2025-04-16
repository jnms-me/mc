module mc.protocol.packet.status.client.status_request;

import mc.protocol.packet.status.client : PacketType;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;

@safe:

final
class StatusRequestPacket
{
    static assert(isClientPacket!(typeof(this)));

    enum PacketType ct_packetType = PacketType.statusRequest;

    private
    this()
    {
    }

    static
    typeof(this) deserialize(ref InputStream input)
    {
        return new typeof(this);
    }
}
