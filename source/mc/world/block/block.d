module mc.world.block.block;

import std.algorithm : map, reduce;
import std.conv : to;
import std.exception : enforce;
import std.traits : Unqual;

import mc.world.block.property : Property, PropertyValue;

@safe:

immutable
class Block
{
    private
    {
        string m_name;

        uint m_globalStateIdOffset;
        Property[] m_stateProperties;
        uint m_defaultStateId;
    }

scope:
    this(
        const string name,
        const uint globalStateIdOffset,
        const Property[] stateProperties,
        const uint defaultStateId,
    )
    {
        m_name = name;
        m_globalStateIdOffset = globalStateIdOffset;
        m_stateProperties = stateProperties;
        m_defaultStateId = defaultStateId;
    }

    pure nothrow
    string getName()
        => m_name;

    pure nothrow
    uint getGlobalStateIdOffset()
        => m_globalStateIdOffset;

    pure nothrow
    Property[] getStateProperties()
        => m_stateProperties;

    pure nothrow
    uint getDefaultStateId()
        => m_defaultStateId;

    pure
    uint getStateId(in PropertyValue[] propertyValues)
    {
        enforce(m_stateProperties.length == propertyValues.length);

        uint possibleIds = 1;
        uint id;
        foreach (const i, const ref value; propertyValues)
        {
            Property property = m_stateProperties[i];
            const valueId = property.valueToId(value);
            id += valueId * possibleIds;
            possibleIds *= property.valueCount;
        }

        return id;
    }
}
