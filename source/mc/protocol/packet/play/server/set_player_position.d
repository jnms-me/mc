module mc.protocol.packet.play.server.set_player_position;

import mc.protocol.enums : GameEvent;
import mc.protocol.packet.play.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe nothrow:

final
class SetPlayerPositionPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.setPlayerPosition;

    private int m_id;
    private double m_x;
    private double m_y;
    private double m_z;
    private double m_vx;
    private double m_vy;
    private double m_vz;
    private float m_yaw;
    private float m_pitch;
    private uint m_flags;

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

    void serialize(ref OutputStream output) const
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
