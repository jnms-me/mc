module mc.protocol.packet.play.server.set_player_position;

import mc.protocol.enums : GameEvent;
import mc.protocol.packet.play.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;
import mc.world.position : ContinuousPos;

@safe:

final
class SetPlayerPositionPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.setPlayerPosition;

    private
    {
        int m_id;
        ContinuousPos m_pos;
        ContinuousPos m_velocity;
        float m_yaw;
        float m_pitch;
        uint m_flags;
    }

scope:
pure:
    nothrow @nogc
    this(
        ContinuousPos pos,
        ContinuousPos velocity = ContinuousPos.origin,
        float yaw = 0.0, float pitch = 0.0,
        uint flags = 0,
    )
    {
        m_id = 0;
        m_pos = pos;
        m_velocity = velocity;
        m_yaw = yaw;
        m_pitch = pitch;
        m_flags = flags;
    }

    nothrow
    void serialize(scope ref OutputStream output) const
    {
        output.writeVar!int(m_id);
        output.write!double(m_pos.x);
        output.write!double(m_pos.y);
        output.write!double(m_pos.z);
        output.write!double(m_velocity.x);
        output.write!double(m_velocity.y);
        output.write!double(m_velocity.z);
        output.write!float(m_yaw);
        output.write!float(m_pitch);
        output.write!uint(m_flags);
    }
}
