module mc.config;

import vibe.core.net : TCPListenOptions;

import mc.log : LogLevel;
import mc.world.position : BlockPos;

@safe:

struct Config
{
    enum LogLevel ct_logLevel = LogLevel.diagnostic;

    enum string ct_mcDataRootPath = "./mc-data";

    enum ushort ct_listenPort = 25_565;
    enum TCPListenOptions ct_listenOptions = TCPListenOptions.defaults | TCPListenOptions.reusePort;

    enum size_t ct_packetBufSize = 64 * 1024 * 1024;

    enum BlockPos ct_spawnPos = BlockPos(16 + 8, 16, 16 + 8);
    enum uint ct_chunkViewDistance = 8;

    @disable this();
    @disable this(this);
}

shared static this()
{
    import mc.data.blocks : BlocksByVersion, BlockSet;
    import mc.data.mc_version : McVersion;
    import mc.protocol.chunk.chunk : Chunk;
    import mc.world.block.property : PropertyValue;
    import mc.world.position : BlockPos, ChunkPos, ChunkRelativeBlockPos;
    import mc.world.world : g_world;

    const BlockSet blocks = BlocksByVersion.instance[McVersion("pc", "1.21.4")];
    const stone = blocks.getBlock("orange_wool").getDefaultStateId;
    const uint leverOn = 5793;
    const uint leverOff = 5794;

    // 3x3 stone floor
    foreach (x; [0, 1, 2])
        foreach (z; [0, 1, 2])
            g_world.getChunk(ChunkPos(x, 0, z)).fillBlock(stone);

    g_world.setBlock(BlockPos(24, 16, 28), leverOn);
}

void onChangeLever(const bool state)
{
    import std.process : executeShell;
    import std.format : f = format;
    executeShell(f!`mosquitto_pub -t 'zigbee2mqtt/lights/set' -m '{"state": "%s"}'`(state ? "ON" : "OFF"));
}