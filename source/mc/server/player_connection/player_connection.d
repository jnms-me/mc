module mc.server.player_connection.player_connection;

import std.algorithm : all, each;
import std.range : only;
import std.uuid : UUID;

import vibe.core.core : yield;
import vibe.core.net : TCPConnection;
import vibe.core.task : Task;

import mc.config : Config;
import mc.protocol.enums : State;
import mc.server.player : Player;
import mc.world.world : World;
import mc.server.player_connection.task : KeepAliveTask, PlayerConnectionTask, ReaderTask, WriterTask;
import mc.server.server;
import mc.util.log : Logger;

package:
@safe:

package(mc.server)
class PlayerConnection
{
    private
    {
        Logger m_log = Logger("PlayerConnection");

        Server m_server;
        TCPConnection m_tcpConn;

        ReaderTask m_readerTask;
        WriterTask m_writerTask;
        KeepAliveTask m_keepAliveTask;

        State m_state;

        Player m_player;
        World m_world;
    }

scope:
    pure nothrow @nogc
    invariant
    {
        assert(m_server);
        assert(m_tcpConn);
    }

    this(scope Server server, scope ref TCPConnection tcpConn)
    {
        m_server = server;
        m_tcpConn = tcpConn;
        m_log = m_log.derive(tcpConn.remoteAddress.toString);
    }

    void run()
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
        m_world && m_player && m_world.playerLeave(m_player);

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
    Server getServer()
        => m_server;

    pure nothrow @nogc
    {
        auto allTasks() => only(m_readerTask, m_writerTask, m_keepAliveTask);

        ReaderTask    getReaderTask()    => m_readerTask;
        WriterTask    getWriterTask()    => m_writerTask;
        KeepAliveTask getKeepAliveTask() => m_keepAliveTask;
    }

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

    pure nothrow
    void createPlayer(in UUID uuid, in string userName)
    in (m_player is null)
    {
        m_player = new Player(
            uuid: uuid,
            userName: userName,
            pos: Config.ct_spawnPos,
        );
        m_log = m_log.derive(userName);
        allTasks.each!(t => t.rederiveLogger);
    }

    void joinDefaultWorld()
    {
        m_server.getWorld.playerJoin(m_player);
    }
}
