module mc.server.player_connection.keep_alive;

import core.time : Duration;

import std.algorithm : min;
import std.datetime.stopwatch : AutoStart, StopWatch;
import std.exception : enforce;
import std.format : f = format;

import vibe.core.sync : createManualEvent, LocalManualEvent;

import mc.server.player_connection.player_connection : PlayerConnection;
import mc.server.player_connection.task : PlayerConnectionTask;
import mc.util.log : Logger;
import packets = mc.protocol.packet.packets;

package:
@safe:

final
class KeepAliveTask : PlayerConnectionTask
{
    private
    {
        LocalManualEvent m_wakeEvent;
        bool m_received;
        int m_id;
    }

scope:
    pure nothrow @nogc
    invariant
    {
        assert(m_wakeEvent);
    }
    
    nothrow
    this(scope PlayerConnection playerConn)
    in (playerConn !is null)
    out (; m_task)
    {
        super(playerConn);
        m_wakeEvent = createManualEvent;
        start;
    }

    protected override pure nothrow
    string getTaskName() const
        => "KeepAliveTask";

    protected override
    void entrypoint()
    {
        m_wakeEvent.wait;

        for (;; m_id++)
        {
            const sw = StopWatch(AutoStart.yes);
            Duration remaining() => min(sw.peek, Duration.zero);

            m_playerConn.getWriterTask.sendPacket(new packets.play.server.KeepAlivePacket(m_id));

            enforce(remaining, "keepAlive response timed out");
            m_wakeEvent.wait(remaining, m_wakeEvent.emitCount);
            m_received = false;
        }
    }

    nothrow
    void startSending()
    {
        m_wakeEvent.emit;
    }

    void onReceived(in long id)
    {
        enforce(!m_received, "got multiple keepAlive responses");
        enforce(id == m_id, f!"keepAlive id mismatch: got %d, expected %d"(id, m_id));
        m_received = true;
        m_wakeEvent.emit;
    }
}
