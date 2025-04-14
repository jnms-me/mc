module mc.protocol.sub_chunk;

import std.conv : to;
import std.math : log2;

import mc.protocol.stream_utils : write, writeBytes, writeString, writeVar;

@safe:

struct SubChunk
{
    private short m_nonAirBlockCount;
    private int[] m_blockTypePallette;
    private int[] m_biomeTypePallette;
    private ubyte[] m_blockData;
    private ubyte[] m_biomeData;

    private this(bool disableFieldInitializer) {}
    @disable this(ref typeof(this));

    int bitsPerBlock() const
        => m_blockTypePallette.length.to!double.log2.to!int;

    int bitsPerBiome() const
        => m_biomeTypePallette.length.to!double.log2.to!int;

    static
    typeof(this) emptySubChunk()
    {
        SubChunk chunk;
        chunk.m_blockTypePallette = [0];
        chunk.m_biomeTypePallette = [1];
        return chunk;
    }

    void serialize(ref const(ubyte)[] output) const
    {
        output.write!short(m_nonAirBlockCount);

        assert(m_blockData.length == 0);
        assert(m_blockTypePallette.length == 1);
        assert(m_biomeData.length == 0);
        assert(m_biomeTypePallette.length == 1);

        output.writeVar!int(bitsPerBlock);
        output.writeVar!int(m_blockTypePallette[0]); // Single value
        output.writeVar!int(0); // Data long length

        output.writeVar!int(bitsPerBiome);
        output.writeVar!int(m_biomeTypePallette[0]);
        output.writeVar!int(0);
    }
}