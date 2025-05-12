module mc.world.block.block_state;

import std.algorithm : countUntil;
import std.exception : enforce;
import std.format : f = format;

import mc.world.block.block : Block;
import mc.world.block.property : Property, PropertyValue;

// TODO: withProperty

@safe:

immutable
struct BlockState
{
    private
    {
        Block m_block;
        uint m_localId;
    }

scope:
pure:
    invariant
    {
        assert(m_block !is null);
    }

    package(mc.world.block) nothrow @nogc
    this(in Block block, in uint localId)
    {
        m_block = block;
        m_localId = localId;
    }

    nothrow @nogc
    Block getBlock()
        => m_block;

    nothrow @nogc
    uint getLocalId()
        => m_localId;

    nothrow @nogc
    uint getGlobalId()
        => m_block.getGlobalStateIdOffset + m_localId;

    PropertyValue getPropertyValue(in string propertyName)
    in (propertyName.length)
    {
        const properties = m_block.getStateProperties;
        const index = properties.countUntil!(el => el.getName == propertyName);
        enforce(
            index < properties.length,
            f!`BlockState.getPropertyValue: Block "%s" has no property "%s"`(m_block.getName, propertyName),
        );
        return m_block.stateIdToPropertyValue(index, m_localId);
    }

    PropertyValue getPropertyValue(in Property property)
    in (property !is null)
    {
        const properties = m_block.getStateProperties;
        const index = properties.countUntil!(el => el is property);
        enforce(
            index < properties.length,
            f!`BlockState.getPropertyValue: Block "%s" has no %s`(m_block.getName, property),
        );
        return m_block.stateIdToPropertyValue(index, m_localId);
    }
}
