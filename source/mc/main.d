module mc.main;

import vibe.core.core : runEventLoopOnce;
import vibe.core.net : listenTCP, TCPConnection, TCPListenOptions;

import mc.config : Config;
import mc.log : Logger;
import mc.player : Player;

@safe:

immutable log = Logger.moduleLogger;

void main()
{
    testBlocks;

    const ushort port = Config.ct_listenPort;
    const TCPListenOptions options = Config.ct_listenOptions;
    listenTCP(port, (conn) => handleConnection(conn), options);
    log.info!"Listening on port %s"(port);

    while (true)
    {
        runEventLoopOnce;
    }
}

void testBlocks()
{
    import std.algorithm : map;
    import std.conv : to;

    import mc.world.block.block : Block;
    import mc.data.mc_version : McVersion;
    import mc.data.blocks : BlocksByVersion, BlockSet;
    import mc.world.block.property : PropertyValue;

    const McVersion mcVersion = McVersion("pc", "1.21.4");
    const BlockSet blocks = BlocksByVersion.instance[mcVersion];
    const Block block = blocks.getBlock("redstone_wall_torch");

    log.info!"name = %s"(block.getName);
    log.info!"globalOffsetId = %s"(block.getGlobalStateIdOffset);
    log.info!"defaultState = %s"(block.getDefaultStateId);
    log.info!"stateProperties = %s"(block.getStateProperties.map!(a => typeid(a)));
    log.info!"stateProperties = %s"(block.getStateProperties.map!(a => a.getName));
    log.info!"stateProperties = %s"(block.getStateProperties.map!(a => a.valueCount));

    PropertyValue[string] values = [
        "facing": PropertyValue("north"),
        "true": PropertyValue(true),
    ];
    log.info!"%s"(block.getStateId(values));
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
