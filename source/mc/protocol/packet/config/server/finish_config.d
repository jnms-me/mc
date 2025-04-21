module mc.protocol.packet.config.server.finish_config;

import mc.protocol.packet.config.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class FinishConfigPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.finishConfig;

    this()
    {
    }

    void serialize(ref OutputStream output) const
    {
    }
}
