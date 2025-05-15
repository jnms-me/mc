module mc.player.player;

import core.time : seconds;

import std.algorithm : map;
import std.conv : hexString, to;
import std.exception : assumeWontThrow;
import std.format : f = format;
import std.json : JSONValue;
import std.range.primitives : empty, front, popFront;
import std.uuid : UUID;

import eventcore.core : IOMode;

import vibe.core.core : runTask, sleep, yield;
import vibe.core.net : TCPConnection;
import vibe.core.task : InterruptException, Task;

import mc.config : Config;
import mc.data.blocks : BlocksByVersion, BlockSet;
import mc.data.mc_version : McVersion;
import mc.util.log : Logger;
import mc.player.player_info : PlayerInfo;
import mc.player.players : g_players;
import mc.protocol.enums : GameEvent, State;
import mc.protocol.nbt : Nbt;
import mc.protocol.packet.traits : getPacketImplForProtocolMember, isServerPacket;
import mc.protocol.stream : EOFException, InputStream, OutputStream;
import mc.util.meta : enumSwitch;
import mc.world.block.property : PropertyValue;
import mc.world.chunk.chunk : Chunk;
import mc.world.position : BlockPos, ChunkPos;
import mc.world.world : g_world;
import packets = mc.protocol.packet.packets;

@safe:

immutable log = Logger.moduleLogger;

struct PlayerConnection
{
    private
    {
        Logger m_log = log.derive("PlayerConnection");

        OutputStream[] m_outgoingPacketQueue;

        State m_state;
        long m_keepAliveId;

        PlayerInfo m_sharedPlayerInfo;
        UUID m_uuid;
        string m_userName;

        BlockPos m_pos = Config.ct_spawnPos;
    }

scope:
    pure
    invariant
    {

    }

    static
    void handleConnection(scope ref TCPConnection conn)
    in (Task.getThis)
    {
        PlayerConnection instance = PlayerConnection(conn);

        // These run in the same thread as this task
        Task reader = runTask(&instance.wrapTask!("reader", readerTaskEntrypoint), conn);
        Task writer = runTask(&instance.wrapTask!("writer", writerTaskEntrypoint), conn);

        while (reader.running && writer.running)
            yield;

        reader.interrupt;
        writer.interrupt;
    }

    private
    this(scope ref TCPConnection conn)
    {
        m_log = m_log.derive(f!" %s"(conn.remoteAddress));
        m_log.info!"Client connected";
    }

    private
    ~this()
    {
        if (m_sharedPlayerInfo !is null)
            g_players.remove(m_sharedPlayerInfo);
    }

    private nothrow
    void wrapTask(string ct_name, alias entrypoint)(scope ref TCPConnection conn)
    {
        try
        {
            m_log.diag!`Task "%s" started`(ct_name);
            try
                entrypoint(conn);
            catch (InterruptException)
                m_log.diag!`Task "%s" interrupted`(ct_name);
            catch (Exception e)
            {
                debug const msg = e.toString;
                else const msg = e.msg;
                m_log.error!`Uncaught %s in "%s" task: "%s"`(typeid(e), ct_name, msg);
            }
            m_log.diag!`Task "%s" exited`(ct_name);
        }
        catch (Exception e)
            assert(false, "wrapTask: Failed writing log");
    }

    private
    void readerTaskEntrypoint(scope ref TCPConnection conn)
    {
        ubyte[] buf = new ubyte[](Config.ct_packetBufSize);
        immutable(ubyte)[] readData;

        while (conn.waitForData)
        {
            size_t read = conn.read(buf, IOMode.once);
            readData ~= buf[0 .. read];

            immutable(ubyte)[][] readPackets;
            while (readData.length)
            {
                // Setup temp InputStream for readVar
                InputStream input = InputStream(readData);

                // Call readVar
                size_t lengthPrefix;
                try
                    lengthPrefix = input.readVar!int.to!size_t;
                catch (EOFException e)
                    break;

                // Determine how many bytes readVar advanced
                const ptrdiff_t lengthPrefixLength = readData.length - input.data.length;
                assert(lengthPrefixLength > 0);

                // Add this packet
                immutable(ubyte)[] packet = readData[lengthPrefixLength .. lengthPrefixLength + lengthPrefix];
                readData = readData[lengthPrefixLength + lengthPrefix .. $];
                readPackets ~= packet;
            }

            foreach (InputStream input; readPackets.map!InputStream)
            {
                const uint protocolUint;
                handleRawPacket(protocolUint, input);
            }
        }
    }

    private
    void writerTaskEntrypoint(scope ref TCPConnection conn)
    {
        while (conn.connected)
        {
            while (!m_outgoingPacketQueue.empty)
            {
                const OutputStream packet = m_outgoingPacketQueue.front;
                m_outgoingPacketQueue.popFront;

                conn.write(packet.data, IOMode.all);
                conn.flush;
            }
            yield;
        }
    }

    private
    void handleRawPacket(in uint protocolUint, scope ref InputStream input)
    {
        mixin enumSwitch!(m_state, handleRawPacketBodyInState, protocolUint, input);
        sw();
    }

    private
    void handleRawPacketBodyInState(State ct_state)(in uint protocolUint, scope ref InputStream input)
    {
        static if (is(mixin(f!"packets.%s.client"(ct_state.stringof)) client == module))
        {
            alias Protocol = client.Protocol;
            static assert(is(Protocol BaseType == enum) && is(BaseType == int));

            Protocol protocol;
            try
                protocol = protocolUint.to!Protocol;
            catch (ConvException)
            {
                m_log.diag!"Dropping packet for unknown protocol %02x in state %s"(protocol, m_state);
                return;
            }

            mixin enumSwitch!(protocol, handleRawPacketBodyForStateProtocolMember, input);
            sw();
        }
        else
        {
            throw new Exception(f!"Entered invalid state %s"(m_state));
        }
    }

    private
    void handleRawPacketBodyForStateProtocolMember(alias protocolMember)(scope ref InputStream input)
    {
        static if (is(getPacketImplForProtocolMember!protocolMember Packet))
        {
            Packet packet = Packet.deserialize(input);
            debug m_log.dbg!"Got a %s"(Packet.stringof);
            this.handlePacket(packet);
        }
        else
            m_log.diag!"Dropping packet for unimplemented protocol %s in state %s"(protocolMember.stringof, m_state);
    }

    private pure
    void handlePacket(packets.handshake.client.HandshakePacket packet)
    {
        debug m_log.dbg!"  protocolVersion = %s"(packet.getProtocolVersion);
        debug m_log.dbg!"  serverAddress = %s, port = %s"(packet.getServerAddress, packet.getPort);
        debug m_log.dbg!"  nextState = %s"(packet.getNextState);

        switchState(packet.getNextState.to!State);
    }

    private
    void handlePacket(packets.status.client.StatusRequestPacket)
    {
        sendStatusResponse;
    }

    private pure nothrow
    void handlePacket(packets.status.client.PingRequestPacket packet)
    {
        sendPacket(new packets.status.server.PongResponsePacket(packet.getPayload));
    }

    private
    void handlePacket(packets.login.client.LoginStartPacket packet)
    {
        m_log.diag!"  userName = %s"(packet.getUserName);
        m_log.diag!"  uuid = %s"(packet.getUuid);

        m_uuid = packet.getUuid;
        m_userName = packet.getUserName;
        m_log = m_log.derive(f!" %s"(m_userName));

        m_sharedPlayerInfo = new PlayerInfo(m_uuid, m_userName);
        g_players[m_sharedPlayerInfo] = true;

        sendPacket(new packets.login.server.LoginSuccessPacket(packet.getUuid, packet.getUserName));
    }

    private pure
    void handlePacket(packets.login.client.AckLoginSuccessPacket)
    {
        switchState(State.config);

        sendRegistryData;
        sendPacket(new packets.config.server.FinishConfigPacket);
    }

    private pure nothrow @nogc
    void handlePacket(packets.login.client.PluginMessagePacket packet)
    {
        debug m_log.dbg!"  channel = %s"(packet.getChannel);
        debug m_log.dbg!"  data = %s"(packet.getData);
    }

    private pure nothrow @nogc
    void handlePacket(packets.config.client.ClientInfoPacket packet)
    {
        debug m_log.dbg!"  locale              = %s"(packet.getLocale);
        debug m_log.dbg!"  renderDistance      = %s"(packet.getRenderDistance);
        debug m_log.dbg!"  chatMode            = %s"(packet.getChatMode);
        debug m_log.dbg!"  chatColors          = %s"(packet.getChatColors);
        debug m_log.dbg!"  displayedSkinParts  = %s"(packet.getDisplayedSkinParts);
        debug m_log.dbg!"  mainHand            = %s"(packet.getMainHand);
        debug m_log.dbg!"  textFiltering       = %s"(packet.getTextFiltering);
        debug m_log.dbg!"  showInOnlinePlayers = %s"(packet.getShowInOnlinePlayers);
        debug m_log.dbg!"  particleLevel       = %s"(packet.getParticleLevel);
    }

    private pure nothrow @nogc
    void handlePacket(packets.config.client.PluginMessagePacket packet)
    {
        debug m_log.dbg!"  channel = %s"(packet.getChannel);
        debug m_log.dbg!"  data = %s"(packet.getData);
    }

    private
    void handlePacket(packets.config.client.AckFinishConfigPacket)
    {
        switchState(State.play);

        sendPacket(new packets.play.server.LoginPacket);
        m_log.info!"Joined the world";

        debug m_log.dbg!"Sending abilities";
        sendHexPacket(0x3a, hexString!("0f" ~ "3d4ccccd" ~ "3dcccccd"));

        debug m_log.dbg!"Sending player entity status";
        sendHexPacket(0x1f, hexString!("00000000" ~ "18")); // op level 0

        sendPacket(new packets.play.server.SetPlayerPositionPacket(
            m_pos.x, m_pos.y, m_pos.z,
        ));

        sendWorldTime;

        debug m_log.dbg!"Sending default spawn position";
        sendHexPacket(0x5b, hexString!"0000020000008fc100000000");

        sendAllChunks;

        debug m_log.dbg!"Sending keep alive";
        sendPacket(new packets.play.server.KeepAlivePacket(m_keepAliveId));
    }

    private
    void handlePacket(packets.play.client.KeepAlivePacket packet)
    {
        if (m_keepAliveId != packet.getId)
            m_log.warn!"Keep alive id mismatch: expected %d, got %d"(m_keepAliveId, packet.getId);

        runTask(() nothrow {
            try
            {
                sleep(5.seconds);
                debug m_log.dbg!"Sending keep alive";
                sendPacket(new packets.play.server.KeepAlivePacket(++m_keepAliveId));
            }
            catch (Exception e) {}
        });
    }

    private
    void handlePacket(packets.play.client.UseItemOnPacket packet)
    {
        m_log.diag!"useItemOnPacket: pos = %s"(packet.getPos);

        const leverPos = BlockPos(24, 16, 28);
        if (packet.getPos == leverPos)
        {
            m_log.info!"lever hit";

            import mc.config : onChangeLever;

            const BlockSet blocks = BlocksByVersion.instance[McVersion("pc", "1.21.4")];
            const leverOff = blocks["lever"].getState([
                "face": PropertyValue("floor"),
                "facing": PropertyValue("south"),
                "powered": PropertyValue(false),
            ]);
            const leverOn = blocks["lever"].getState([
                "face": PropertyValue("floor"),
                "facing": PropertyValue("south"),
                "powered": PropertyValue(true),
            ]);

            if (g_world.getBlock(leverPos) == leverOn.getGlobalId)
            {
                m_log.info!"lever is now off";
                g_world.setBlock(leverPos, leverOff);
                onChangeLever(false);
            }
            else
            {
                m_log.info!"lever is now on";
                g_world.setBlock(leverPos, leverOn);
                onChangeLever(true);
            }
            sendAllChunks;
        }
    }

    private pure nothrow @nogc void handlePacket(packets.play.client.ClientTickEndPacket) const {}
    private pure nothrow @nogc void handlePacket(packets.play.client.SetPlayerPositionPacket) const {}
    private pure nothrow @nogc void handlePacket(packets.play.client.SetPlayerPositionRotationPacket) const {}
    private pure nothrow @nogc void handlePacket(packets.play.client.SetPlayerRotationPacket) const {}
    private pure nothrow @nogc void handlePacket(packets.play.client.PlayerInputPacket) const {}

    private
    void sendStatusResponse()
    in (m_state == State.status)
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

    private pure
    void sendRegistryData()
    in (m_state == State.config)
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

    private pure
    void sendWorldTime()
    in (m_state == State.play)
    {
        sendPacket(new packets.play.server.UpdateTimePacket(0, 0, false));
    }

    private
    void sendAllChunks()
    in (m_state == State.play)
    {
        sendPacket(new packets.play.server.SetCenterChunkPacket(
            Config.ct_spawnPos.toChunkPos.x,
            Config.ct_spawnPos.toChunkPos.z,
        ));

        debug m_log.dbg!"Sending wait for chunks game event";
        sendPacket(new packets.play.server.GameEventPacket(GameEvent.waitForLevelChunks, 0));

        sendPacket(new packets.play.server.ChunkBatchStartPacket);

        const ChunkPos pos = Config.ct_spawnPos.toChunkPos;
        const uint dist = Config.ct_chunkViewDistance;

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

    private pure nothrow @nogc
    void switchState(const State state)
    {
        m_state = state;
        debug m_log.dbg!"Switched to state %s"(m_state);
    }

    private pure
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

    private pure
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
}
