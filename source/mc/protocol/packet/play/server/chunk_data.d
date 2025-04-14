module mc.protocol.packet.play.server.chunk_data;

import std.algorithm : each, move;
import std.conv : to;

import mc.protocol.nbt : Nbt;
import mc.protocol.packet.base : Packet;
import mc.protocol.packet.play.server : PacketType;
import mc.protocol.stream_utils : write, writeBytes, writeNbt, writeString, writeVar;
import mc.protocol.sub_chunk : SubChunk;

@safe:

class ChunkDataPacket : Packet
{
    enum PacketType ct_packetType = PacketType.chunkData;
    
    private int m_x;
    private int m_z;
    private Nbt m_heightMaps;
    private const(SubChunk)[] m_subChunks;

    this(int x, int z, ref Nbt heightMaps, const(SubChunk)[] subChunks)
    {
        m_x = x;
        m_z = z;
        m_heightMaps = heightMaps.move;
        m_subChunks = subChunks;
    }

    override
    void serialize(ref const(ubyte)[] output) const
    {
        const(ubyte)[] content;
        content.writeVar!int(ct_packetType);
        content.write!int(m_x);
        content.write!int(m_z);
        content.writeNbt(m_heightMaps);
        {
            const(ubyte)[] chunkData;
            foreach (ref sc; m_subChunks)
                sc.serialize(chunkData);
            content.writeVar!int(chunkData.length.to!int); // subChunks array byte length prefix
            content.writeBytes(chunkData); // subChunks array
        }
        content.writeVar!int(0); // Empty blockEntities array

        content.writeVar!int(0); // Number of following ulongs that encode the bit array
        // content.write!ulong(0b0_0000_0); // subChunkHasSkyLightDataMask
        content.writeVar!int(0);
        // content.write!ulong(0b0_0000_0); // subChunkHasBlockLightDataMask
        content.writeVar!int(0);
        // content.write!ulong(0b0_0000_0); // subChunkSkyLightDataAllZeroMask
        content.writeVar!int(0);
        // content.write!ulong(0b0_0000_0); // subChunkBlockLightDataAllZeroMask
        content.writeVar!int(0); // Empty skyLightData array
        content.writeVar!int(0); // Empty blockLightData array

        output.writeVar!int(content.length.to!int);
        output.writeBytes(content);
    }
}
