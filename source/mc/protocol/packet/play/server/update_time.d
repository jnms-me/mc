module mc.protocol.packet.play.server.update_time;

import mc.protocol.packet.play.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class UpdateTimePacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.updateTime;

    private long m_worldAge;
    private long m_timeOfDay;
    private bool m_timeOfDayIncreasing;

    this(long worldAge, long timeOfDay, bool timeOfDayIncreasing)
    {
        m_worldAge = worldAge;
        m_timeOfDay = timeOfDay;
        m_timeOfDayIncreasing = timeOfDayIncreasing;
    }

    void serialize(ref OutputStream output) const
    {
        output.write!long(m_worldAge);
        output.write!long(m_timeOfDay);
        output.write!bool(m_timeOfDayIncreasing);
    }
}
