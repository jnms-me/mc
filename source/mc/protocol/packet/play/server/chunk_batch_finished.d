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

    private
    {
        int m_batchSize;
    }

scope:
pure:
    nothrow @nogc
    this(in int batchSize)
    {
        m_batchSize = batchSize;
    }

    nothrow
    void serialize(scope ref OutputStream output) const
    {
        output.writeVar!int(m_batchSize);
    }
}
