module mc.protocol.packet.play.server.chunk_batch_start;

import mc.protocol.packet.base : Packet;
import mc.protocol.packet.play.server : PacketType;
import mc.protocol.stream_utils : writeBytes, writeVar;

@safe:

class ChunkBatchStartPacket : Packet
{
    enum PacketType ct_packetType = PacketType.chunkBatchStart;

    this()
    {
    }

    override
    void serialize(ref const(ubyte)[] output) const
    {
        const(ubyte)[] content;
        content.writeVar!int(ct_packetType);

        output.writeVar!int(cast(int) content.length);
        output.writeBytes(content);
    }
}
