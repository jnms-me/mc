module mc.protocol.chunk.container.single_value;

import mc.protocol.chunk.container.base : Container;
import mc.protocol.stream : OutputStream;

@safe:

final shared
class SingleValueContainer : Container
{
    private
    {
        uint m_value;
    }

    this(const uint value)
    {
        m_value = value;
    }

    uint getValue() const
        => m_value;

    uint setValue(const uint value)
        => m_value = value;

    override
    void serialize(ref OutputStream output) const
    {
        output.writeVar!int(0); // Bits per value
        output.writeVar!int(m_value);
        output.writePrefixedArray((ulong[]).init);
    }
}
