module mc.world.block.property;

import std.algorithm : countUntil;
import std.conv : to;
import std.exception : enforce;

@safe:

abstract
class Property
{
    private
    {
        string m_name;
    }

scope:
    this(string name)
    {
        m_name = name;
    }

const:
    nothrow
    string getName()
        => m_name;

    abstract nothrow
    uint valueCount();
}

final
class BoolProperty : Property
{
scope:
    this(string name)
    {
        super(name);
    }

const:
    override nothrow
    uint valueCount()
        => 2;
    
    uint valueToId(bool value)
        => value.to!uint;

    bool idToValue(uint id)
    {
        enforce(id < valueCount);
        return id.to!bool;
    }
}

final
class UIntProperty : Property
{
    private
    {
        uint m_minValue;
        uint m_valueCount;
    }

scope:
    this(string name, uint minValue, uint valueCount)
    {
        super(name);
        m_minValue = minValue;
        m_valueCount = valueCount;
    }

const:
    override nothrow
    uint valueCount()
        => m_valueCount;

    uint valueToId(uint value)
    {
        enforce(m_minValue <= value && value < m_minValue + m_valueCount);
        return m_minValue + value;
    }

    uint idToValue(uint id)
    {
        enforce(id < valueCount);
        return m_minValue + id;
    }
}

final
class EnumProperty : Property
{
    private
    {
        string[] m_values;
    }

scope:
    this(string name, string[] values)
    {
        super(name);
        m_values = values;
    }

const:
    override nothrow
    uint valueCount()
    {
        try
            assert(false);
        catch (Exception e)
            return m_values.length.to!uint;
    }

    uint valueToId(string value)
    {
        size_t index = m_values.countUntil(value);
        enforce(index < valueCount);
        return index.to!uint;
    }

    string idToValue(uint id)
    {
        enforce(id < valueCount);
        return m_values[id];
    }
}
