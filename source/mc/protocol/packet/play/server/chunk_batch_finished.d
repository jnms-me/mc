module mc.protocol.packet.play.server.chunk_batch_finished;

import mc.protocol.packet.base : Packet;
import mc.protocol.packet.play.server : PacketType;
import mc.protocol.stream_utils : writeBytes, writeVar;

@safe:

class ChunkBatchFinishedPacket : Packet
{
    enum PacketType ct_packetType = PacketType.chunkBatchFinished;

    private int m_batchSize;

    this(int batchSize)
    {
        m_batchSize = batchSize;
    }

    override
    void serialize(ref const(ubyte)[] output) const
    {
        const(ubyte)[] content;
        content.writeVar!int(ct_packetType);
        content.writeVar!int(m_batchSize);

        output.writeVar!int(cast(int) content.length);
        output.writeBytes(content);
    }
}
