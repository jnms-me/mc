module mc.world.block.block;

import std.conv : to;
import std.exception : enforce;
import std.format : f = format;

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
pure:
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

    nothrow
    string getName()
        => m_name;

    nothrow
    Property[] getStateProperties()
        => m_stateProperties;

    nothrow
    uint getDefaultStateId()
        => m_globalStateIdOffset + m_defaultStateId;

    uint getStateId(in PropertyValue[string] propertyValues)
    {
        uint id;
        uint possibleIds = 1;
        foreach (immutable ref property; m_stateProperties)
        {
            enforce(property.getName in propertyValues, f!`Missing value for %s`(property.toString));
            PropertyValue value = propertyValues[property.getName];

            id += property.valueToId(value) * possibleIds;
            possibleIds *= property.valueCount;
        }
        return m_globalStateIdOffset + id;
    }
}
