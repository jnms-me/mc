module mc.server.server;

import std.range.primitives : empty;

import vibe.core.net : listenTCP, TCPConnection, TCPListener;

import mc.config : Config;
import mc.server.player_connection : PlayerConnection;
import mc.util.log : Logger;
import mc.world.world : World;

@safe:

class Server
{
    private
    {
        immutable Logger m_log = Logger.packageLogger.derive("Server");
        immutable string[] m_addresses;
        immutable ushort m_port;

        World m_world;

        TCPListener[] m_listeners;
    }

scope:
    this(in immutable(string)[] addresses, in ushort port)
    in (addresses.length)
    {
        m_addresses = addresses;
        m_port = port;

        m_world = new World;
    }

    private nothrow
    void handleConnection(scope TCPConnection conn)
    {
        try
        {
            conn.keepAlive = true;

            m_log.diag!"New connection from %s"(conn.remoteAddress);

            try
            {
                auto playerConnection = new PlayerConnection(this, conn);
                playerConnection.run;
            }
            catch (Exception e)
            {
                m_log.error!"Uncaught %s in PlayerConnection"(typeid(e));
                m_log.error!"%s"((() @trusted => e.toString)());
            }

            m_log.warn!"Connection %s closed"(conn.remoteAddress);
        }
        catch (Exception)
            assert(false, "failed writing log");
    }

    void runAsync()
    in (m_listeners.empty, "already running")
    {
        m_listeners.reserve(m_addresses.length);
        foreach (address; m_addresses)
        {
            m_listeners ~= listenTCP(m_port, &handleConnection, address, Config.ct_listenOptions);
            m_log.info!"Listening on %s"(m_listeners[$ - 1].bindAddress);
        }
    }

    pure nothrow @nogc
    inout(World) getWorld() inout
        => m_world;
}
