module mc.config;

import core.time : Duration, seconds;

import vibe.core.net : TCPListenOptions;

import mc.util.log : Logger, LogLevel;
import mc.world.position : ContinuousPos;

@safe:

immutable log = Logger.moduleLogger;

struct Config
{
    enum LogLevel ct_logLevel = LogLevel.diagnostic;

    enum string ct_mcDataRootPath = "./mc-data";

    enum ushort ct_listenPort = 25_565;
    enum TCPListenOptions ct_listenOptions = TCPListenOptions.defaults | TCPListenOptions.reusePort;

    enum size_t ct_packetBufSize = 64 * 1024 * 1024;

    enum Duration ct_keepAliveTimeout = 15.seconds;
    enum Duration ct_keepAliveInterval = 2.seconds;

    enum ContinuousPos ct_spawnPos = ContinuousPos(16 + 8, 16, 16 + 8);
    enum uint ct_chunkViewDistance = 8;

    @disable this();
    @disable this(this);
}

shared static this()
{
    import mc.data.blocks : BlocksByVersion, BlockSet;
    import mc.data.mc_version : McVersion;
    import mc.util.log : Logger;
    import mc.world.block.block : Block;
    import mc.world.block.block_state : BlockState;
    import mc.world.block.property : PropertyValue;
    import mc.world.chunk.chunk : Chunk;
    import mc.world.position : BlockPos, ChunkPos, ChunkRelativeBlockPos;
    import mc.world.world : g_world;

    const BlockSet blocks = BlocksByVersion.instance[McVersion("pc", "1.21.4")];

    // 3x3 stone floor
    const floorBlock = blocks["red_wool"].getDefaultState;
    foreach (x; [0, 1, 2])
        foreach (z; [0, 1, 2])
            g_world.getChunk(ChunkPos(x, 0, z)).fillBlock(floorBlock);

    const leverOn = blocks["lever"].getState([
        "face": PropertyValue("floor"),
        "facing": PropertyValue("south"),
        "powered": PropertyValue(true),
    ]);
    g_world.setBlock(BlockPos(24, 16, 28), leverOn);

    {
        int i = 0;
        foreach (face; ["floor", "wall", "ceiling"])
            foreach (facing; ["north", "south", "west", "east"])
                foreach (powered; [true, false])
                {
                    const pos = BlockPos(i++ * 2, 16, 16);
                    const state = blocks["lever"].getState([
                        "face": PropertyValue(face),
                        "facing": PropertyValue(facing),
                        "powered": PropertyValue(powered),
                    ]);
                    log.info!"%s:\t%s"(pos[], state.getLocalId);
                    g_world.setBlock(pos, state);
                }
    }

    {
        int i = 0;
        foreach (has0; [true, false])
            foreach (has1; [true, false])
                foreach (has2; [true, false])
                {
                    const pos = BlockPos(i++ * 2, 16, 17);
                    const state = blocks["brewing_stand"].getState([
                        "has_bottle_0": PropertyValue(has0),
                        "has_bottle_1": PropertyValue(has1),
                        "has_bottle_2": PropertyValue(has2),
                    ]);
                    log.info!"%s:\t%s"(pos[], state.getLocalId);
                    g_world.setBlock(pos, state);
                }
    }
}

void onChangeLever(const bool state)
{
    import std.format : f = format;
    import std.process : executeShell;
    // executeShell(f!`mosquitto_pub -t 'zigbee2mqtt/lights/set' -m '{"state": "%s"}'`(state ? "ON" : "OFF"));
}