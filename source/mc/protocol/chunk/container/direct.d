module mc.protocol.chunk.container.direct;

import std.range.primitives : ElementType, isInputRange;
import std.traits : Unconst;
import std.typecons : Tuple, tuple;

import mc.protocol.chunk.container.base : Container;
import mc.protocol.stream : OutputStream;
import mc.util.math : ceilDiv;
import mc.util.traits : bitSize;
import mc.log;

@safe:

final shared
class DirectContainer : Container
{
    private
    {
        immutable uint m_valueCount;
        immutable ubyte m_bitsPerValue;
        ulong[] m_data;
    }

    invariant
    {
        assert(0 < m_valueCount);
        assert(0 < m_bitsPerValue && m_bitsPerValue <= 64);
        assert(m_data.length);
    }

    this(const uint valueCount, const ubyte bitsPerValue, const uint initialValue = 0)
    {
        m_valueCount = valueCount;
        m_bitsPerValue = bitsPerValue;
        m_data = new typeof(m_data)(dataLength);
        m_data[] = initialValue;
    }

    /// Copy ctor
    this(ref typeof(this) other)
    {
        m_valueCount = other.m_valueCount;
        m_bitsPerValue = other.m_bitsPerValue;
        m_data = other.m_data.dup;
    }

    private pure nothrow
    size_t valuesPerUlong() const
        => bitSize!ulong / m_bitsPerValue;

    private pure nothrow
    size_t dataLength() const
        => m_valueCount.ceilDiv(valuesPerUlong);
    
    private pure nothrow
    auto getValueLocation(const size_t i) const
    in (i < m_valueCount)
    {
        const size_t index    = i / valuesPerUlong;
        const size_t subIndex = i % valuesPerUlong;
        const size_t offset = subIndex * m_bitsPerValue;
        const ulong mask = ((1 << m_bitsPerValue) - 1) << offset;
        return tuple!("index", "offset", "mask")(index, offset, mask);
    }
    
    pure nothrow
    uint opIndex(const size_t i) const
    {
        const loc = getValueLocation(i);
        return cast(uint) (m_data[loc.index] & loc.mask) >> loc.offset;
    }

    synchronized
    uint opIndexAssign(const uint value, const size_t i)
    {
        const loc = getValueLocation(i);
        const valueWithOffset = (cast(ulong) value << loc.offset) & loc.mask;
        return cast(uint) (m_data[loc.index] = (m_data[loc.index] & ~loc.mask) | valueWithOffset);
    }

    override
    void serialize(ref OutputStream output) const
    {
        output.writeVar!uint(m_bitsPerValue);
        output.writePrefixedArray(m_data);
    }
}
