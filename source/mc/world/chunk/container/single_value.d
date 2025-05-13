module mc.world.chunk.container.single_value;

import mc.world.chunk.container.base : Container;
import mc.protocol.stream : OutputStream;

@safe:

final shared
class SingleValueContainer : Container
{
    private
    {
        uint m_value;
    }

scope:
pure:
    nothrow @nogc
    this(const uint value)
    {
        m_value = value;
    }

    nothrow @nogc
    uint getValue() const
        => m_value;

    nothrow @nogc
    uint setValue(const uint value)
        => m_value = value;

    override nothrow
    void serialize(scope ref OutputStream output) const
    {
        output.writeVar!int(0); // Bits per value
        output.writeVar!int(m_value);
        output.writePrefixedArray((ulong[]).init);
    }
}
