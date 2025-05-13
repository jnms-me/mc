module mc.protocol.packet.play.server.game_event;

import mc.protocol.enums : GameEvent;
import mc.protocol.packet.play.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class GameEventPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.gameEvent;

    private
    {
        GameEvent m_event;
        float m_value;
    }

scope:
pure:
    nothrow @nogc
    this(in GameEvent event, in float value = 0.0f)
    {
        m_event = event;
        m_value = value;
    }

    nothrow
    void serialize(scope ref OutputStream output) const
    {
        output.write!ubyte(m_event);
        output.write!float(m_value);
    }
}
