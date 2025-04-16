module mc.protocol.packet.play.server.chunk_batch_start;

import mc.protocol.packet.play.server : PacketType;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class ChunkBatchStartPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum PacketType ct_packetType = PacketType.chunkBatchStart;

    this()
    {
    }

    void serialize(ref OutputStream output) const
    {
    }
}
