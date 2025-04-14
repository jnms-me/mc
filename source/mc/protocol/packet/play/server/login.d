module mc.protocol.packet.play.server.login;

import std.algorithm : each;
import std.conv : to;
import std.uuid : UUID;

import mc.protocol.enums : GameMode;
import mc.protocol.packet.base : Packet;
import mc.protocol.packet.play.server : PacketType;
import mc.protocol.stream_utils : write, writeBytes, writeString, writeVar;

@safe:

class LoginPacket : Packet
{
    enum PacketType ct_packetType = PacketType.login;

    private int m_entityId;
    private bool m_isHardCore;
    private string[] m_dimensionIds;
    private int m_maxPlayers;
    private int m_viewDistance;
    private int m_simulationDistance;
    private bool m_reducedDebugInfo;
    private bool m_enableRespawnScreen;
    private bool m_limitedCrafting;
    private int m_dimensionType;
    private string m_dimensionId;
    private ubyte[8] m_seedHash;
    private GameMode m_gameMode;
    private GameMode m_lastGameMode;
    private bool m_isDebugWorld;
    private bool m_isSuperflatWorld;
    private int m_portalCooldownTicks;
    private int m_seaLevel;
    private bool m_enforcesSecureChat;

    this()
    {
        m_entityId = 0;
        m_isHardCore = false;
        m_dimensionIds = ["minecraft:overworld", "minecraft:the_nether", "minecraft:the_end"];
        m_maxPlayers = 20;
        m_viewDistance = 10;
        m_simulationDistance = 10;
        m_reducedDebugInfo = false;
        m_enableRespawnScreen = true;
        m_limitedCrafting = false;
        m_dimensionType = 0;
        m_dimensionId = "minecraft:overworld";
        m_seedHash = [0x8b, 0xa8, 0x41, 0xfb, 0x1c, 0xc1, 0xa6, 0x04];
        m_gameMode = GameMode.creative;
        m_lastGameMode = GameMode.unset;
        m_isDebugWorld = false;
        m_isSuperflatWorld = false;
        m_portalCooldownTicks = 0;
        m_seaLevel = 63;
        m_enforcesSecureChat = false;
    }

    override
    void serialize(ref const(ubyte)[] output) const
    {
        const(ubyte)[] content;
        content.writeVar!int(ct_packetType);
        content.write!int(m_entityId);
        content.write!bool(m_isHardCore);
        content.writeVar!int(cast(int) m_dimensionIds.length); // Prefixed array length
        m_dimensionIds.each!(s => content.writeString(s));// Prefixed array contents
        content.writeVar!int(m_maxPlayers);
        content.writeVar!int(m_viewDistance);
        content.writeVar!int(m_simulationDistance);
        content.write!bool(m_reducedDebugInfo);
        content.write!bool(m_enableRespawnScreen);
        content.write!bool(m_limitedCrafting);
        content.writeVar!int(m_dimensionType);
        content.writeString(m_dimensionId);
        content.write!(ubyte[8])(m_seedHash);
        content.write!ubyte(m_gameMode);
        content.write!ubyte(m_lastGameMode);
        content.write!bool(m_isDebugWorld);
        content.write!bool(m_isSuperflatWorld);
        content.write!bool(false); // Don't pass a death location
        content.writeVar!int(m_portalCooldownTicks);
        content.writeVar!int(m_seaLevel);
        content.write!bool(m_enforcesSecureChat);

        output.writeVar!int(content.length.to!int);
        output.writeBytes(content);
    }
}
