module mc.protocol.packet.play.server.chunk_data;

import std.algorithm : each, move;
import std.conv : to;

import mc.protocol.nbt : Nbt;
import mc.protocol.packet.play.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;
import mc.world.chunk.chunk : Chunk;

@safe:

final
class ChunkDataPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.chunkData;

    private
    {
        int m_x;
        int m_z;
        Nbt m_heightMaps;
        const(Chunk)[] m_chunks;
    }

scope:
pure:
    nothrow @nogc
    this(in int x, in int z, ref Nbt heightMaps, in const(Chunk)[] chunks)
    {
        m_x = x;
        m_z = z;
        m_heightMaps = heightMaps.move;
        m_chunks = chunks;
    }

    void serialize(scope ref OutputStream output) const
    {
        output.write!int(m_x);
        output.write!int(m_z);
        m_heightMaps.serialize(output);
        {
            OutputStream chunkData;
            foreach (ref chunk; m_chunks)
                chunk.serialize(chunkData);
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
