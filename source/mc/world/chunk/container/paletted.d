module mc.world.chunk.container.paletted;

import std.range.primitives : ElementType, isInputRange;

import mc.world.chunk.container.base : Container;
import mc.protocol.stream : OutputStream;

@safe:

version (none):

final shared
class PalettedContainer : Container
{
    private
    {
        immutable uint m_valueCount;
        immutable ubyte m_minBitsPerValue;
        immutable ubyte m_maxBitsPerValue;
        uint[] m_palette;
        ulong[] m_data;
    }

scope:
pure:
    nothrow @nogc
    invariant
    {
        assert(0 < m_minBitsPerValue);
        assert(m_minBitsPerValue <= m_maxBitsPerValue);
        assert(m_maxBitsPerValue <= 12);
        assert(m_palette.length);
        assert(m_data.length);
    }

    /// Create empty container ctor
    nothrow
    this(ubyte minBitsPerValue, ubyte maxBitsPerValue, uint initialSingleValue = 0)
    in (minBitsPerValue <= maxBitsPerValue && maxBitsPerValue <= 12)
    {
        m_minBitsPerValue = minBitsPerValue;
        m_maxBitsPerValue = maxBitsPerValue;
        m_palette = [initialSingleValue];
        m_data = new typeof(m_data)(dataLength);
    }

    /// Copy ctor
    nothrow
    this(in typeof(this) other)
    {
        m_minBitsPerValue = other.m_minBitsPerValue;
        m_maxBitsPerValue = other.m_maxBitsPerValue;
        m_palette         = other.m_palette.dup;
        m_data            = other.m_data.dup;
    }

    private nothrow @nogc
    size_t bitsPerValue() const
    in (m_palette.length)
        => m_maxBitsPerValue;

    private nothrow @nogc
    size_t valuesPerUlong() const
        => bitSize!ulong / bitsPerValue;

    private nothrow @nogc
    size_t dataLength() const
        => ct_blocksPerChunk.ceilDiv(valuesPerUlong);

    private nothrow
    void recreateDataIfNeeded(ubyte lastBitsPerValue)
    {
        const newDataLength = dataLength;
        if (m_data.length == newDataLength)
            return;

        typeof(m_data) newData = new typeof(m_data)(dataLength);
        // TODO:
        // read m_data using lastBitsPerValue
        // write each element

        m_data = newData;
    }

    /// After modifying the pallette length, a new `values` range must be obtained.
    nothrow @nogc
    auto values() inout
    {
        static
        struct Range
        {
            const(shared(ulong))[] data;
            immutable ubyte bitsPerValue;

            bool empty() const
                => data.length == 0;

            uint front() const
            {
                return data[0] & cast(uint) ((1 << bitsPerValue) - 1);
            }

            void popFront()
            {
                data = data[1 .. $];
            }

        }
        // static assert(isInputRange!Range);
        return Range(m_data, bitsPerValue);
    }

    override nothrow
    void serialize(scope ref OutputStream output) const
    {
        output.writeVar!uint(m_minBitsPerValue);
        foreach (const uint id; m_palette)
            output.writeVar!uint(id);
        output.writePrefixedArray(m_data);
    }
}
