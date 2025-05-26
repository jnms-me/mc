module mc.server.player_connection.task.writer;

import std.conv : to;
import std.exception : assumeWontThrow;
import std.range.primitives : empty, front, popFront;

import eventcore.core : IOMode;

import vibe.core.core : yield;
import vibe.core.net : TCPConnection;

import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;
import mc.server.player_connection.player_connection : PlayerConnection;
import mc.server.player_connection.task : PlayerConnectionTask;

package(mc.server.player_connection):
@safe:

final
class WriterTask : PlayerConnectionTask
{
    private
    {
        OutputStream[] m_outgoingPacketQueue;
    }

scope:
    nothrow
    this(scope PlayerConnection playerConn)
    in (playerConn !is null)
    out (; m_task)
    {
        super(playerConn);
        rederiveLogger;
        start;
    }

    protected override pure nothrow
    string getTaskName() const
        => "WriterTask";

    protected override
    void entrypoint()
    {
        ref TCPConnection tcpConn() => m_playerConn.getTcpConn;

        while (tcpConn.connected)
        {
            while (!m_outgoingPacketQueue.empty && tcpConn.connected)
            {
                const OutputStream packet = m_outgoingPacketQueue.front;
                m_outgoingPacketQueue.popFront;

                tcpConn.write(packet.data, IOMode.all);
                tcpConn.flush;
            }
            yield;
        }
    }

    pure
    void sendPacket(Packet)(const Packet packet)
    if (isServerPacket!Packet)
    {
        debug m_log.dbg!"Sending a %s"(Packet.stringof);

        OutputStream output;
        output.writeVar!int(packet.ct_protocol);
        packet.serialize(output);

        OutputStream lengthPrefixedOutput;
        lengthPrefixedOutput.writeVar!int(output.data.length.to!int.assumeWontThrow);
        lengthPrefixedOutput.writeBytes(output.data);

        m_outgoingPacketQueue ~= lengthPrefixedOutput;
    }

    import std.json : JSONValue;

    import mc.config : Config;
    import mc.protocol.enums : GameEvent, State;
    import mc.protocol.nbt : Nbt;
    import mc.server.player : g_players;
    import mc.world.chunk.chunk : Chunk;
    import mc.world.position : ChunkPos;
    import mc.world.world : g_world;
    import packets = mc.protocol.packet.packets;

    pure
    void sendHexPacket(int protocol, string hexString)
    {
        OutputStream output;
        output.writeVar!int(protocol);
        output.writeBytes(cast(immutable(ubyte)[]) hexString);

        OutputStream lengthPrefixedOutput;
        lengthPrefixedOutput.writeVar!int(output.data.length.to!int.assumeWontThrow);
        lengthPrefixedOutput.writeBytes(output.data);

        m_outgoingPacketQueue ~= lengthPrefixedOutput;
    }

    void sendStatusResponse()
    in (m_playerConn.getState == State.status)
    {
        enum ct_jsonStatusTemplate = JSONValue([
            "version": JSONValue([
                "name": JSONValue("1.21.4"),
                "protocol": JSONValue(769),
            ]),
            "description": JSONValue([
                "text": JSONValue("Vage kelder minecraft server"),
            ]),
            "players": JSONValue([
                "online": JSONValue(0),
                "max": JSONValue(0),
            ]),
            "favicon": JSONValue("data:image/png;base64,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"),
            "enforcesSecureChat": JSONValue(false),
            "preventsChatReports": JSONValue(true),
        ]);
        JSONValue json = ct_jsonStatusTemplate;
        json["players"]["online"] = g_players.length;
        const jsonString = json.toString;
        sendPacket(new packets.status.server.StatusResponsePacket(jsonString));
    }

    pure
    void sendRegistryData()
    in (m_playerConn.getState == State.config)
    {
        debug m_log.dbg!"Sending all registry data";

        debug m_log.dbg!"minecraft:painting_variant";
        {
            auto registryDataPacket = new packets.config.server.RegistryDataPacket("minecraft:painting_variant");
            auto entryNbt = Nbt([
                "asset_id": Nbt("minecraft:alban"),
                "width": Nbt(int(1)),
                "height": Nbt(int(1)),
                "title": Nbt([
                  "color": Nbt("yellow"),
                  "translate": Nbt("painting.minecraft.alban.title"),
                ]),
                "author": Nbt([
                    "color": Nbt("gray"),
                    "translate": Nbt("painting.minecraft.alban.author"),
                ]),
            ]);
            registryDataPacket.addEntry("minecraft:alban", entryNbt);
            sendPacket(registryDataPacket);
        }
        debug m_log.dbg!"minecraft:wolf_variant";
        {
            auto registryDataPacket = new packets.config.server.RegistryDataPacket("minecraft:wolf_variant");
            auto entryNbt = Nbt([
                "wild_texture": Nbt("minecraft:entity/wolf/wolf_ashen"),
                "angry_texture": Nbt("minecraft:entity/wolf/wolf_ashen_angry"),
                "tame_texture": Nbt("minecraft:entity/wolf/wolf_ashen_tame"),
                "biomes": Nbt.emptyList,
            ]);
            registryDataPacket.addEntry("minecraft:ashen", entryNbt);
            sendPacket(registryDataPacket);
        }
        debug m_log.dbg!"minecraft:dimension_type";
        {
            auto registryDataPacket = new packets.config.server.RegistryDataPacket("minecraft:dimension_type");
            foreach (dimension; ["overworld", "the_nether", "the_end"])
            {
                auto entryNbt = Nbt([
                    "ultrawarm": Nbt(byte(0)),
                    "natural": Nbt(byte(0)),
                    "coordinate_scale": Nbt(double(1.0)),
                    "has_skylight": Nbt(byte(1)),
                    "has_ceiling": Nbt(byte(0)),
                    "ambient_light": Nbt(float(1.0)),
                    "fixed_time": Nbt(long(0)),
                    "monster_spawn_light_level": Nbt([
                        "type": Nbt("minecraft:constant"),
                        "value": Nbt(int(0)),
                    ]),
                    "monster_spawn_block_light_limit": Nbt(int(0)),
                    "piglin_safe": Nbt(byte(0)),
                    "bed_works": Nbt(byte(0)),
                    "respawn_anchor_works": Nbt(byte(0)),
                    "has_raids": Nbt(byte(0)),
                    "logical_height": Nbt(int(64)),
                    "min_y": Nbt(int(0)),
                    "height": Nbt(int(64)),
                    "infiniburn": Nbt("#minecraft:infiniburn_overworld"),
                    "effects": Nbt("minecraft:overworld"),
                ]);
                registryDataPacket.addEntry("minecraft:" ~ dimension, entryNbt);
            }
            sendPacket(registryDataPacket);
        }
        debug m_log.dbg!"minecraft:damage_type";
        {
            auto registryDataPacket = new packets.config.server.RegistryDataPacket("minecraft:damage_type");
            foreach (damageType; ["arrow", "bad_respawn_point", "cactus", "campfire", "cramming", "dragon_breath", "drown", "dry_out", "ender_pearl", "explosion", "fall", "falling_anvil", "falling_block", "falling_stalactite", "fireball", "fireworks", "fly_into_wall", "freeze", "generic", "generic_kill", "hot_floor", "in_fire", "in_wall", "indirect_magic", "lava", "lightning_bolt", "mace_smash", "magic", "mob_attack", "mob_attack_no_aggro", "mob_projectile", "on_fire", "out_of_world", "outside_border", "player_attack", "player_explosion", "sonic_boom", "spit", "stalagmite", "starve", "sting", "sweet_berry_bush", "thorns", "thrown", "trident", "unattributed_fireball", "wind_charge", "wither", "wither_skull"])
            {
                auto entryNbt = Nbt([
                    "message_id": Nbt("generic"),
                    "exhaustion": Nbt(float(0.0)),
                    "scaling": Nbt("never"),
                ]);
                registryDataPacket.addEntry("minecraft:" ~ damageType, entryNbt);
            }
            sendPacket(registryDataPacket);
        }
        debug m_log.dbg!"minecraft:worldgen/biome";
        {
            auto registryDataPacket = new packets.config.server.RegistryDataPacket("minecraft:worldgen/biome");
            foreach (biome; ["void", "plains"])
            {
                auto entryNbt = Nbt([
                    "has_precipitation": Nbt(byte(1)),
                    "temperature": Nbt(float(0.8)),
                    "downfall": Nbt(float(0.4)),
                    "carvers": Nbt.emptyList,
                    "effects": Nbt([
                      "fog_color": Nbt(int(12_638_463)),
                      "sky_color": Nbt(int(7_907_327)),
                      "water_color": Nbt(int(4_159_204)),
                      "water_fog_color": Nbt(int(329_011)),
                    //   "music_volume": Nbt(float(1.0)),
                    ]),
                    "features": Nbt.emptyList,
                    "spawners": Nbt.emptyCompound,
                    // "spawners": Nbt([
                    //     "ambient": Nbt.emptyList,
                    //     "axolotls": Nbt.emptyList,
                    //     "creature": Nbt.emptyList,
                    //     "misc": Nbt.emptyList,
                    //     "monster": Nbt.emptyList,
                    //     "underground_water_creature": Nbt.emptyList,
                    //     "water_ambient": Nbt.emptyList,
                    //     "water_creature": Nbt.emptyList,
                    // ]),
                    "spawn_costs": Nbt.emptyCompound,
                ]);
                registryDataPacket.addEntry("minecraft:" ~ biome, entryNbt);
            }
            sendPacket(registryDataPacket);
        }
    }

    pure
    void sendWorldTime()
    in (m_playerConn.getState == State.play)
    {
        sendPacket(new packets.play.server.UpdateTimePacket(0, 0, false));
    }

    void sendAllChunks()
    in (m_playerConn.getState == State.play)
    {
        const ChunkPos pos = m_playerConn.getPlayer.getPos.toBlockPos.toChunkPos;
        const uint dist = Config.ct_chunkViewDistance;

        sendPacket(new packets.play.server.SetCenterChunkPacket(pos.x, pos.z));

        debug m_log.dbg!"Sending wait for chunks game event";
        sendPacket(new packets.play.server.GameEventPacket(GameEvent.waitForLevelChunks, 0));

        sendPacket(new packets.play.server.ChunkBatchStartPacket);

        int chunksSent;
        foreach (int x; pos.x - dist - 1 .. pos.x + dist + 2)
            foreach (int z; pos.z - dist - 1 .. pos.z + dist + 2)
            {
                Nbt heightMaps = Nbt.emptyCompound;
                const(Chunk)[] chunks;
                foreach (int y; 0 .. 4)
                    chunks ~= g_world.getChunk(ChunkPos(x, y, z));
                sendPacket(new packets.play.server.ChunkDataPacket(x, z, heightMaps, chunks));
                chunksSent++;
            }
        debug m_log.dbg!"Sent %d chunks"(chunksSent);

        sendPacket(new packets.play.server.ChunkBatchFinishedPacket(chunksSent));
    }
}
