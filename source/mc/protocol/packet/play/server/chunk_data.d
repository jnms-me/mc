module mc.protocol.packet.play.server.chunk_data;

import std.algorithm : each, move;
import std.conv : to;

import mc.protocol.nbt : Nbt;
import mc.protocol.packet.play.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;
import mc.protocol.chunk : Chunk;

@safe:

final
class ChunkDataPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.chunkData;

    private int m_x;
    private int m_z;
    private Nbt m_heightMaps;
    private const(Chunk)[] m_chunks;

    this(int x, int z, ref Nbt heightMaps, const(Chunk)[] chunks)
    {
        m_x = x;
        m_z = z;
        m_heightMaps = heightMaps.move;
        m_chunks = chunks;
    }

    void serialize(ref OutputStream output) const
    {
        output.write!int(m_x);
        output.write!int(m_z);
        output.writeNbt(m_heightMaps);
        {
            OutputStream chunkData;
            foreach (ref sc; m_chunks)
                sc.serialize(chunkData);
            output.writeVar!int(chunkData.data.length.to!int); // chunks array byte length prefix
            output.writeBytes(chunkData.data); // chunks array
        }
        output.writeVar!int(0); // Empty blockEntities array

        output.writeVar!int(0); // Number of following ulongs that encode the bit array
        // content.write!ulong(0b0_0000_0); // chunkHasSkyLightDataMask
        output.writeVar!int(0);
        // content.write!ulong(0b0_0000_0); // chunkHasBlockLightDataMask
        output.writeVar!int(0);
        // content.write!ulong(0b0_0000_0); // chunkSkyLightDataAllZeroMask
        output.writeVar!int(0);
        // content.write!ulong(0b0_0000_0); // chunkBlockLightDataAllZeroMask
        output.writeVar!int(0); // Empty skyLightData array
        output.writeVar!int(0); // Empty blockLightData array
    }
}
