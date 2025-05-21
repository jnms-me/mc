module mc.server.player_connection.task;

import vibe.core.core : runTask;
import vibe.core.task : InterruptException, Task;

import mc.server.player_connection.player_connection : PlayerConnection;
import mc.util.log : Logger;

package:
@safe:

abstract
class PlayerConnectionTask
{
    protected
    {
        PlayerConnection m_playerConn;
        Logger m_log;
        Task m_task;
    }

scope:
    pure nothrow @nogc
    invariant
    {
        assert(m_playerConn !is null);
        assert(m_log != Logger.init);
    }

    nothrow
    this(scope PlayerConnection playerConn)
    in (playerConn !is null)
    {
        m_playerConn = playerConn;
        rederiveLogger;
    }

    nothrow
    ~this()
    {
        m_task.interrupt;
    }

    pure nothrow
    void rederiveLogger()
    {
        m_log = m_playerConn.getLogger.derive(getTaskName);
    }

    ref inout(Task) getTask() inout
        => m_task;

    protected nothrow
    void start()
    {
        m_task = runTask({
            try
            {
                m_log.diag!"%s started"(getTaskName);
                try
                    entrypoint;
                catch (InterruptException)
                    m_log.diag!"%s interrupted"(getTaskName);
                catch (Exception e)
                {
                    debug const msg = e.toString;
                    else const msg = e.msg;
                    m_log.error!`Uncaught %s in %s: "%s"`(typeid(e), getTaskName, msg);
                }
                m_log.diag!"%s exited"(getTaskName);
            }
            catch (Exception e)
                assert(false, "wrapTask: Failed writing log");
        });
    }

    protected abstract
    void entrypoint();

    protected abstract pure nothrow
    string getTaskName() const;
}
