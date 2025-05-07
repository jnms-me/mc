module mc.protocol.packet.play.client.use_item_on;

import mc.protocol.packet.play.client : Protocol;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;
import mc.world.position : BlockPos;

@safe:

final
class UseItemOnPacket
{
    static assert(isClientPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.useItemOn;

    private
    {
        uint m_hand;
        ulong m_encodedPos;
        uint m_face;
        float m_cursorX;
        float m_cursorY;
        float m_cursorZ;
        bool m_headInsideBlock;
        uint m_sequence;
    }

    private
    this()
    {
    }

    BlockPos getPos() const
    {
        const uint y = m_encodedPos & ((1 << 12) - 1);
        const uint z = (m_encodedPos >> 12) & ((1 << 26) - 1);
        const uint x = (m_encodedPos >> (12 + 26)) & ((1 << 26) - 1);
        return BlockPos(x, y, z);
    }

    static
    typeof(this) deserialize(ref InputStream input)
    {
        typeof(this) instance = new typeof(this);

        instance.m_hand = input.readVar!uint;
        instance.m_encodedPos = input.read!ulong;
        instance.m_face = input.readVar!uint;
        instance.m_cursorX = input.read!float;
        instance.m_cursorY = input.read!float;
        instance.m_cursorZ = input.read!float;
        instance.m_headInsideBlock = input.read!bool;
        input.read!bool; // World border hit, always false
        instance.m_sequence = input.readVar!uint;

        return instance;
    }
}
