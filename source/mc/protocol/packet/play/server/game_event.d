module mc.protocol.packet.play.server.game_event;

import mc.protocol.enums : GameEvent;
import mc.protocol.packet.play.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe nothrow:

final
class GameEventPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.gameEvent;

    private GameEvent m_event;
    private float m_value;

    this(GameEvent event, float value = 0.0f)
    {
        m_event = event;
        m_value = value;
    }

    void serialize(ref OutputStream output) const
    {
        output.write!ubyte(m_event);
        output.write!float(m_value);
    }
}
