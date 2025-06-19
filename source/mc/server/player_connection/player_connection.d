module mc.server.player_connection.player_connection;

import std.algorithm : all, among, each;
import std.range : only;
import std.uuid : UUID;

import vibe.core.core : yield;
import vibe.core.net : TCPConnection;
import vibe.core.task : Task;

import mc.config : Config;
import mc.protocol.enums : State;
import mc.server.player : g_players, Player;
import mc.server.player_connection.task : KeepAliveTask, PlayerConnectionTask, ReaderTask, WriterTask;
import mc.util.log : Logger;

package:
@safe:

package(mc.server)
class PlayerConnection
{
    private
    {
        Logger m_log = Logger("PlayerConnection");

        TCPConnection m_tcpConn;

        ReaderTask m_readerTask;
        WriterTask m_writerTask;
        KeepAliveTask m_keepAliveTask;

        State m_state;

        Player m_player;
    }

scope:
    pure nothrow @nogc
    invariant
    {
        assert(m_tcpConn);
        if (m_state.among(State.config, State.play))
            assert(m_player !is null);
    }

    package(mc.server) static
    void handleConnection(scope ref TCPConnection tcpConn)
    in (Task.getThis)
    {
        PlayerConnection instance = new PlayerConnection(tcpConn);
        instance.runTasks;
    }

    private
    this(scope ref TCPConnection tcpConn)
    {
        m_tcpConn = tcpConn;
        m_log = m_log.derive(tcpConn.remoteAddress.toString);
        m_log.info!"Client connected";
    }

    private
    void runTasks()
    {
        scope (exit) cleanup;

        m_readerTask    = new ReaderTask(this);
        m_writerTask    = new WriterTask(this);
        m_keepAliveTask = new KeepAliveTask(this);

        while (allTasks.all!(t => t && t.getTask.running))
            yield;
    }

    private
    void cleanup() @trusted
    {
        m_player && m_player.unregister;

        allTasks.each!(t => t && t.getTask.interrupt);
        allTasks.each!(t => t && t.getTask.join);
    }

    pure nothrow @nogc
    Logger getLogger() const
        => m_log;

    pure nothrow @nogc
    ref TCPConnection getTcpConn()
        => m_tcpConn;

    pure nothrow @nogc
    auto allTasks()
        => only(m_readerTask, m_writerTask, m_keepAliveTask);

    pure nothrow @nogc
    ReaderTask getReaderTask()
        => m_readerTask;

    pure nothrow @nogc
    WriterTask getWriterTask()
        => m_writerTask;

    pure nothrow @nogc
    KeepAliveTask getKeepAliveTask()
        => m_keepAliveTask;

    pure nothrow @nogc
    State getState() const
        => m_state;

    pure nothrow @nogc
    void switchState(const State state)
    {
        m_state = state;
        debug m_log.dbg!"Switched to state %s"(m_state);
    }

    pure nothrow @nogc
    Player getPlayer()
        => m_player;

    pure
    void createPlayer(in UUID uuid, in string userName)
    in (m_player is null)
    {
        m_player = new Player(
            uuid: uuid,
            userName: userName,
            pos: Config.ct_spawnPos,
        );
    }
}
