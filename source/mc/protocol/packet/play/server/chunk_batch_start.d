module mc.protocol.packet.play.server.chunk_batch_start;

import mc.protocol.packet.play.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class ChunkBatchStartPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.chunkBatchStart;

    this()
    {
    }

    void serialize(ref OutputStream output) const
    {
    }
}
