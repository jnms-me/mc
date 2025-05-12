module mc.world.block.block;

import std.algorithm : any, map, sum;
import std.conv : to;
import std.exception : enforce;
import std.format : f = format;
import std.range : iota;

import mc.world.block.block_state : BlockState;
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
        uint[] m_statePropertiesIdMultiplier;
        uint m_defaultStateId;
    }

scope:
pure:
    nothrow @nogc
    invariant
    {
        assert(m_name.length);
        assert(m_stateProperties.length == m_statePropertiesIdMultiplier.length);
        assert(m_stateProperties.length || m_defaultStateId == 0);
    }

    nothrow
    this(
        in string name,
        in uint globalStateIdOffset,
        in Property[] stateProperties,
        in uint defaultStateId,
    )
    {
        m_name = name;

        m_globalStateIdOffset = globalStateIdOffset;
        m_stateProperties = stateProperties;
        m_statePropertiesIdMultiplier = {
            uint[] arr;
            if (stateProperties.length)
            {
                arr = new uint[](stateProperties.length);
                arr[$ - 1] = 1;
                foreach_reverse (i; 0 .. stateProperties.length - 1)
                    arr[i] = stateProperties[i + 1].valueCount * arr[i + 1];
            }
            return arr.idup;
        }();
        m_defaultStateId = defaultStateId;

        import mc.log;
        if (name == "lever")
        {
            debug try {Logger.moduleLogger.info!"%s"(m_stateProperties); } catch (Exception e) {}
            debug try {Logger.moduleLogger.info!"%s"(m_statePropertiesIdMultiplier); } catch (Exception e) {}
        }
    }

    package(mc.world.block)
    uint propertyValueToStateId(in size_t index, in PropertyValue value)
    in (index < m_stateProperties.length)
    {
        const property = m_stateProperties[index];
        const multiplier = m_statePropertiesIdMultiplier[index];
        return property.valueToId(value) * multiplier;
    }

    package(mc.world.block)
    uint propertyValuesToStateId(in PropertyValue[string] propertyValues)
    {
        foreach (const name; propertyValues.byKey)
        {
            enforce(
                m_stateProperties.any!(el => el.getName == name),
                f!`Block "%s" can't have the "%s" property`(m_name, name),
            );
        }

        return m_stateProperties.length
            .iota
            .map!((in size_t i) {
                const property = m_stateProperties[i];
                const value = propertyValues.get(
                    key : property.getName,
                    defaultValue: stateIdToPropertyValue(i, m_defaultStateId),
                );
                return propertyValueToStateId(i, value);
            })
            .sum;
    }

    package(mc.world.block)
    PropertyValue stateIdToPropertyValue(in size_t index, in uint id)
    in (index < m_stateProperties.length)
    {
        const property = m_stateProperties[index];
        const multiplier = m_statePropertiesIdMultiplier[index];
        const propertyId = (id / multiplier) % property.valueCount;
        return property.idToValue(propertyId);
    }

    package(mc.world.block) nothrow @nogc
    uint getGlobalStateIdOffset()
        => m_globalStateIdOffset;

    nothrow @nogc
    string getName()
        => m_name;

    nothrow @nogc
    Property[] getStateProperties()
        => m_stateProperties;

    BlockState getState(in PropertyValue[string] propertyValues)
        => BlockState(this, propertyValuesToStateId(propertyValues));

    nothrow @nogc
    BlockState getDefaultState()
        => BlockState(this, m_defaultStateId);
}
