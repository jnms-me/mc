module mc.world.block.property;

import std.algorithm : countUntil;
import std.conv : to;
import std.exception : enforce, assumeWontThrow;
import std.sumtype : SumType, tryMatch;

// TODO: toString
// TODO: better exceptions
// TODO: Replace tryMatch with tryGet when ldc updates to frontend 2.111

@safe:

abstract immutable
class Property
{
    private
    {
        string m_name;
    }

scope:
pure:
    protected nothrow
    this(const string name)
    {
        m_name = name;
    }

    nothrow
    string getName()
        => m_name;

    abstract nothrow
    uint valueCount();

    abstract
    uint valueToId(in PropertyValue value);

    abstract
    PropertyValue idToValue(const uint id);
}

final immutable
class BoolProperty : Property
{
scope:
pure:
    this(const string name)
    {
        super(name);
    }

    override nothrow
    uint valueCount()
        => 2;
    
    override
    uint valueToId(in PropertyValue propertyValue)
    {
        const value = propertyValue.tryMatch!((const bool a) => a);
        return value.to!uint;
    }

    override
    PropertyValue idToValue(const uint id)
    {
        enforce(id < valueCount);
        return PropertyValue(id.to!bool);
    }
}

final immutable
class UIntProperty : Property
{
    private
    {
        uint m_minValue;
        uint m_valueCount;
    }

scope:
pure:
    this(const string name, const uint minValue, const uint valueCount)
    {
        super(name);
        m_minValue = minValue;
        m_valueCount = valueCount;
    }

    override nothrow
    uint valueCount()
        => m_valueCount;

    override
    uint valueToId(in PropertyValue propertyValue)
    {
        const uintValue = propertyValue.tryMatch!((const uint a) => a);
        enforce(m_minValue <= uintValue && uintValue < m_minValue + m_valueCount);
        return m_minValue + uintValue;
    }

    override
    PropertyValue idToValue(const uint id)
    {
        enforce(id < valueCount);
        return PropertyValue(m_minValue + id);
    }
}

final immutable
class EnumProperty : Property
{
    private
    {
        const(string)[] m_values;
    }

scope:
pure:
    nothrow
    this(const string name, const immutable(string)[] values)
    {
        super(name);
        m_values = values;
    }

    override nothrow
    uint valueCount()
        => m_values.length.to!uint.assumeWontThrow;

    override
    uint valueToId(in PropertyValue propertyValue)
    {
        const value = propertyValue.tryMatch!((const string a) => a);
        size_t index = m_values.countUntil(value);
        enforce(index < valueCount);
        return index.to!uint;
    }

    override
    PropertyValue idToValue(const uint id)
    {
        enforce(id < valueCount);
        return PropertyValue(m_values[id]);
    }
}

alias PropertyValue = immutable SumType!(bool, uint, string);
