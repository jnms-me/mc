module mc.kelder;

import std.format : f = format;
import std.process : executeShell;

import mc.config : Config;
import mc.data.blocks : BlocksByVersion, BlockSet;
import mc.data.mc_version : McVersion;
import mc.protocol.packet.play.client : UseItemOnPacket;
import mc.util.log : Logger;
import mc.world : World;
import mc.world.block.block : Block;
import mc.world.block.block_state : BlockState;
import mc.world.block.property : PropertyValue;
import mc.world.chunk.chunk : Chunk;
import mc.world.position : BlockPos, ChunkPos, ChunkRelativeBlockPos;

@safe:

final shared
class Kelder
{
    // Singleton
    private static Kelder g_instance;
    static nothrow @nogc Kelder instance() => g_instance;

    enum BlockPos ct_leverPos = BlockPos(24, 16, 28);

    private
    {
        immutable Logger m_log = Logger.moduleLogger;
        immutable BlockState m_floorBS;
        immutable BlockState m_leverOffBS;
        immutable BlockState m_leverOnBS;

        World m_world;
    }

    private static
    this()
    {
        g_instance = new Kelder;
    }

    private
    this() scope
    {
        const BlockSet blocks = BlocksByVersion.instance[McVersion("pc", "1.21.4")];
        m_floorBS = blocks["red_wool"].getDefaultState;
        m_leverOffBS = blocks["lever"].getState([
            "face": PropertyValue("floor"),
            "facing": PropertyValue("south"),
            "powered": PropertyValue(false),
        ]);
        m_leverOnBS = blocks["lever"].getState([
            "face": PropertyValue("floor"),
            "facing": PropertyValue("south"),
            "powered": PropertyValue(true),
        ]);
    }

    void generateWorld(World world)
    {
        m_world = world;

        // 48x16x48 floor
        foreach (x; [0, 1, 2])
            foreach (z; [0, 1, 2])
                world.getChunk(ChunkPos(x, 0, z)).fillBlock(m_floorBS);

        // The lever
        world.setBlock(ct_leverPos, m_leverOnBS);

        // Some example blockstates
        const BlockSet blocks = BlocksByVersion.instance[McVersion("pc", "1.21.4")];
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
                        m_log.info!"%s:\t%s"(pos[], state.getLocalId);
                        world.setBlock(pos, state);
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
                        m_log.info!"%s:\t%s"(pos[], state.getLocalId);
                        world.setBlock(pos, state);
                    }
        }
    }

    void onUseItemOnPacket(in UseItemOnPacket packet)
    {
        if (m_world is null)
            return;
        if (packet.getPos != ct_leverPos)
            return;

        const bool oldState = m_world.getBlock(ct_leverPos) == m_leverOnBS.getGlobalId;
        const bool newState = !oldState;
        m_log.info!"Lever is now %s"(newState ? "on" : "off");
        m_world.setBlock(ct_leverPos, newState ? m_leverOnBS : m_leverOffBS);
        executeShell(f!`mosquitto_pub -t 'zigbee2mqtt/lights/set' -m '{"state": "%s"}'`(newState ? "ON" : "OFF"));
    }
}
