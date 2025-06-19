module mc.server.player_connection.task.reader;

import std.algorithm : map;
import std.conv : ConvException, hexString, to;
import std.format : f = format;

import eventcore.core : IOMode;

import vibe.core.net : TCPConnection;

import mc.config : Config;
import mc.protocol.enums : State;
import mc.protocol.packet.traits : getPacketImplForProtocolMember;
import mc.protocol.stream : EOFException, InputStream;
import mc.server.player_connection : PlayerConnection;
import mc.server.player_connection.task : PlayerConnectionTask, WriterTask;
import mc.util.meta : enumSwitch;
import packets = mc.protocol.packet.packets;

package(mc.server.player_connection):
@safe:

final
class ReaderTask : PlayerConnectionTask
{
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
        => "ReaderTask";

    protected override
    void entrypoint()
    {
        ref TCPConnection tcpConn() => m_playerConn.getTcpConn;

        ubyte[] buf = new ubyte[](Config.ct_packetBufSize);
        immutable(ubyte)[] readData;

        while (tcpConn.waitForData)
        {
            size_t read = tcpConn.read(buf, IOMode.once);
            readData ~= buf[0 .. read];

            immutable(ubyte)[][] readPackets;
            while (readData.length)
            {
                // Setup temp InputStream for readVar
                InputStream input = InputStream(readData);

                // Call readVar
                size_t lengthPrefix;
                try
                    lengthPrefix = input.readVar!uint.to!size_t;
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
                const uint protocolUint = input.readVar!uint;
                handleRawPacket(protocolUint, input);
            }
        }
    }

    private
    void handleRawPacket(in uint protocolUint, scope ref InputStream input)
    {
        const state = m_playerConn.getState;
        mixin enumSwitch!(state, handleRawPacketBodyInState, protocolUint, input);
        sw();
    }

    private
    void handleRawPacketBodyInState(alias ct_state)(in uint protocolUint, scope ref InputStream input)
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
                m_log.diag!"Dropping packet for unknown protocol %02x in state %s"(protocol, m_playerConn.getState);
                return;
            }

            mixin enumSwitch!(protocol, handleRawPacketBodyForStateProtocolMember, input);
            sw();
        }
        else
        {
            throw new Exception(f!"Entered invalid state %s"(m_playerConn.getState));
        }
    }

    private
    void handleRawPacketBodyForStateProtocolMember(alias protocolMember)(scope ref InputStream input)
    {
        static if (is(getPacketImplForProtocolMember!protocolMember Packet))
        {
            debug m_log.dbg!"Got a %s"(Packet.stringof);
            Packet packet = Packet.deserialize(input);
            this.handlePacket(packet);
        }
        else
        {
            m_log.diag!"Dropping packet for unimplemented protocol %s in state %s"(
                protocolMember.stringof, m_playerConn.getState
            );
        }
    }

    // Handshake state
    private pure
    void handlePacket(packets.handshake.client.HandshakePacket packet)
    {
        m_playerConn.switchState(packet.getNextState.to!State);
    }

    // Status state
    private
    void handlePacket(packets.status.client.StatusRequestPacket)
    {
        writer.sendStatusResponse;
    }

    private pure nothrow
    void handlePacket(packets.status.client.PingRequestPacket packet)
    {
        writer.sendPacket(new packets.status.server.PongResponsePacket(packet.getPayload));
    }

    // Login state
    private
    void handlePacket(packets.login.client.LoginStartPacket packet)
    {
        m_log = m_log.derive(f!" %s"(packet.getUserName));
        m_playerConn.createPlayer(packet.getUuid, packet.getUserName);

        writer.sendPacket(new packets.login.server.LoginSuccessPacket(packet.getUuid, packet.getUserName));
    }

    private pure
    void handlePacket(packets.login.client.AckLoginSuccessPacket)
    {
        m_playerConn.switchState(State.config);

        writer.sendRegistryData;
        writer.sendPacket(new packets.config.server.FinishConfigPacket);
    }

    private pure nothrow @nogc void handlePacket(packets.login.client.PluginMessagePacket) const {}

    // Config state
    private pure nothrow @nogc void handlePacket(packets.config.client.ClientInfoPacket) const {}
    private pure nothrow @nogc void handlePacket(packets.config.client.PluginMessagePacket) const {}

    private
    void handlePacket(packets.config.client.AckFinishConfigPacket)
    {
        m_playerConn.switchState(State.play);

        m_playerConn.getPlayer.register;

        writer.sendPacket(new packets.play.server.LoginPacket);

        // Abilities
        writer.sendHexPacket(0x3a, hexString!("0f" ~ "3d4ccccd" ~ "3dcccccd"));

        // Player entity status
        writer.sendHexPacket(0x1f, hexString!("00000000" ~ "18")); // op level 0

        const pos = m_playerConn.getPlayer.getPos;
        writer.sendPacket(new packets.play.server.SetPlayerPositionPacket(pos));

        writer.sendWorldTime;

        // World spawn pos?
        writer.sendHexPacket(0x5b, hexString!"0000020000008fc100000000");

        writer.sendAllChunks;

        m_playerConn.getKeepAliveTask.startSending;
    }

    // Play state
    private
    void handlePacket(packets.play.client.KeepAlivePacket packet)
    {
        m_playerConn.getKeepAliveTask.onReceived(packet.getId);
    }

    private
    void handlePacket(packets.play.client.UseItemOnPacket packet)
    {
        m_log.diag!"useItemOnPacket: pos = %s"(packet.getPos);

        import mc.config : onChangeLever;
        import mc.data.blocks : BlocksByVersion, BlockSet;
        import mc.data.mc_version : McVersion;
        import mc.world.block.property : PropertyValue;
        import mc.world.position : BlockPos;
        import mc.world.world : g_world;

        const leverPos = BlockPos(24, 16, 28);
        if (packet.getPos == leverPos)
        {
            m_log.info!"lever hit";

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
            writer.sendAllChunks;
        }
    }

    private pure nothrow @nogc void handlePacket(packets.play.client.ClientTickEndPacket) const {}
    private pure nothrow @nogc void handlePacket(packets.play.client.PlayerCommandPacket) const {}
    private pure nothrow @nogc void handlePacket(packets.play.client.PlayerInputPacket) const {}
    private pure nothrow @nogc void handlePacket(packets.play.client.SetPlayerPositionPacket) const {}
    private pure nothrow @nogc void handlePacket(packets.play.client.SetPlayerPositionRotationPacket) const {}
    private pure nothrow @nogc void handlePacket(packets.play.client.SetPlayerRotationPacket) const {}

    private pure nothrow @nogc
    WriterTask writer()
        => m_playerConn.getWriterTask;
}
