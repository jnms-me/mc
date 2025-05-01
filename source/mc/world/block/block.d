module mc.world.block.block;

import mc.world.block.property : Property;

@safe:

class Block
{
    private
    {
        string m_name;

        uint m_globalStateIdOffset;
        Property[] m_stateProperties;
        uint m_defaultStateId;
    }

    this(string name, uint globalStateIdOffset, Property[] stateProperties, uint defaultStateId)
    {
        m_name = name;
        m_globalStateIdOffset = globalStateIdOffset;
        m_defaultStateId = defaultStateId;
    }
}
