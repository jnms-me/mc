module mc.protocol.chunk;

import std.conv : to;
import std.math : log2;

import mc.world.block.block : Block;
import mc.protocol.stream : OutputStream;
import mc.world.position : ChunkRelativeBlockPos;

@safe:

struct Chunk
{
    private
    {
        short m_nonAirBlockCount;
        int[] m_blockTypePallette;
        int[] m_biomeTypePallette;
        ubyte[] m_blockData;
        ubyte[] m_biomeData;
    }

    private this(bool disableFieldInitializer) {}
    @disable this(ref typeof(this));

    static
    typeof(this) createEmpty()
    {
        Chunk chunk;
        chunk.m_nonAirBlockCount = 0;
        chunk.m_blockTypePallette = [0];
        chunk.m_biomeTypePallette = [1];
        return chunk;
    }

    static
    typeof(this) createFilled()
    {
        Chunk chunk;
        chunk.m_nonAirBlockCount = 4096;
        chunk.m_blockTypePallette = [1];
        chunk.m_biomeTypePallette = [1];
        return chunk;
    }

    int bitsPerBlock() const
        => m_blockTypePallette.length.to!double.log2.to!int;

    int bitsPerBiome() const
        => m_biomeTypePallette.length.to!double.log2.to!int;
    
    void setBlock(in ChunkRelativeBlockPos pos, in Block block)
    {

    }

    void serialize(ref OutputStream output) const
    {
        output.write!short(m_nonAirBlockCount);

        assert(m_blockData.length == 0);
        assert(m_blockTypePallette.length == 1);

        output.writeVar!int(bitsPerBlock);
        output.writeVar!int(m_blockTypePallette[0]); // Single value
        output.writeVar!int(0); // Data long length

        assert(m_biomeData.length == 0);
        assert(m_biomeTypePallette.length == 1);

        output.writeVar!int(bitsPerBiome);
        output.writeVar!int(m_biomeTypePallette[0]);
        output.writeVar!int(0);
    }
}