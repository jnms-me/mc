module mc.main;

import vibe.core.core : runEventLoopOnce;
import vibe.core.net : listenTCP, TCPConnection, TCPListenOptions;

import mc.config : Config;
import mc.log : Logger;
import mc.player.player : Player;
import mc.player.player_info : PlayerInfo;
import mc.world.world : World;

@safe:

immutable log = Logger.moduleLogger;

void main()
{
    const ushort port = Config.ct_listenPort;
    const TCPListenOptions options = Config.ct_listenOptions;
    listenTCP(port, (conn) => handleConnection(conn), options);
    log.info!"Listening on port %s"(port);

    while (true)
    {
        runEventLoopOnce;
    }
}

nothrow
void handleConnection(TCPConnection conn)
{
    log.diag!"New connection from %s"(conn.remoteAddress);

    conn.keepAlive = true;

    Player player = new Player;
    try
        player.handleConnection(conn);
    catch (Exception e)
    {
        log.error!"Uncaught %s in handleConnection"(typeid(e));
        log.error!"%s"((() @trusted => e.toString)());
    }

    log.diag!"Connection %s closed"(conn.remoteAddress);
}
