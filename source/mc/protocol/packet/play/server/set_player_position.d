module mc.protocol.packet.play.server.set_player_position;

import mc.protocol.enums : GameEvent;
import mc.protocol.packet.play.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class SetPlayerPositionPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.setPlayerPosition;

    private
    {
        int m_id;
        double m_x;
        double m_y;
        double m_z;
        double m_vx;
        double m_vy;
        double m_vz;
        float m_yaw;
        float m_pitch;
        uint m_flags;
    }

scope:
pure:
    nothrow @nogc
    this(
        double x, double y, double z,
        double vx = 0.0, double vy = 0.0, double vz = 0.0,
        float yaw = 0.0, float pitch = 0.0,
        uint flags = 0,
    )
    {
        m_id = 0;
        m_x = x;
        m_y = y;
        m_z = z;
        m_vx = vx;
        m_vy = vy;
        m_vz = vz;
        m_yaw = yaw;
        m_pitch = pitch;
        m_flags = flags;
    }

    nothrow
    void serialize(scope ref OutputStream output) const
    {
        output.writeVar!int(m_id);
        output.write!double(m_x);
        output.write!double(m_y);
        output.write!double(m_z);
        output.write!double(m_vx);
        output.write!double(m_vy);
        output.write!double(m_vz);
        output.write!float(m_yaw);
        output.write!float(m_pitch);
        output.write!uint(m_flags);
    }
}
