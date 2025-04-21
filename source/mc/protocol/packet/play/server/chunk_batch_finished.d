module mc.protocol.packet.play.server.chunk_batch_finished;

import mc.protocol.packet.play.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class ChunkBatchFinishedPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.chunkBatchFinished;

    private int m_batchSize;

    this(int batchSize)
    {
        m_batchSize = batchSize;
    }

    void serialize(ref OutputStream output) const
    {
        output.writeVar!int(m_batchSize);
    }
}
