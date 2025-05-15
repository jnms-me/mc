module mc.server.server;

import vibe.core.core : runEventLoopOnce;
import vibe.core.net : listenTCP_s, TCPConnection, TCPListenOptions;

import mc.config : Config;
import mc.log : Logger;
import mc.player.player : PlayerConnection;
import mc.player.player_info : PlayerInfo;
import mc.world.world : World;

@safe:

immutable log = Logger.moduleLogger;

void runServerTask()
{
    const ushort port = Config.ct_listenPort;
    const TCPListenOptions options = Config.ct_listenOptions;
    listenTCP_s(port, &handleConnection, options);
    log.info!"Listening on port %s"(port);
}

private nothrow
void handleConnection(TCPConnection conn)
{
    try
    {
        conn.keepAlive = true;

        log.diag!"New connection from %s"(conn.remoteAddress);

        try
            PlayerConnection.handleConnection(conn);
        catch (Exception e)
        {
            log.error!"Uncaught %s in PlayerConnection"(typeid(e));
            log.error!"%s"((() @trusted => e.toString)());
        }

        log.error!"Connection %s closed"(conn.remoteAddress);
    }
    catch(Exception)
        assert(false, "failed writing log");
}