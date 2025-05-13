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

    private
    {
        long m_worldAge;
        long m_timeOfDay;
        bool m_timeOfDayIncreasing;
    }

scope:
pure:
    nothrow @nogc
    this(long worldAge, long timeOfDay, bool timeOfDayIncreasing)
    {
        m_worldAge = worldAge;
        m_timeOfDay = timeOfDay;
        m_timeOfDayIncreasing = timeOfDayIncreasing;
    }

    nothrow
    void serialize(scope ref OutputStream output) const
    {
        output.write!long(m_worldAge);
        output.write!long(m_timeOfDay);
        output.write!bool(m_timeOfDayIncreasing);
    }
}
