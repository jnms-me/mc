module mc.protocol.packet.play.server.login;

import std.algorithm : each;
import std.conv : to;
import std.uuid : UUID;

import mc.protocol.enums : GameMode;
import mc.protocol.packet.play.server : PacketType;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class LoginPacket
{
    static assert(isServerPacket!(typeof(this)));

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
        m_dimensionIds = [
            "minecraft:overworld",
            "minecraft:the_nether",
            "minecraft:the_end"
        ];
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

    void serialize(ref OutputStream output) const
    {
        output.write!int(m_entityId);
        output.write!bool(m_isHardCore);
        output.writeVar!int(m_dimensionIds.length.to!int); // Prefixed array length
        m_dimensionIds.each!(s => output.writePrefixedString(s)); // Prefixed array contents
        output.writeVar!int(m_maxPlayers);
        output.writeVar!int(m_viewDistance);
        output.writeVar!int(m_simulationDistance);
        output.write!bool(m_reducedDebugInfo);
        output.write!bool(m_enableRespawnScreen);
        output.write!bool(m_limitedCrafting);
        output.writeVar!int(m_dimensionType);
        output.writePrefixedString(m_dimensionId);
        output.write(m_seedHash);
        output.write!ubyte(m_gameMode);
        output.write!ubyte(m_lastGameMode);
        output.write!bool(m_isDebugWorld);
        output.write!bool(m_isSuperflatWorld);
        output.write!bool(false); // Don't pass a death location
        output.writeVar!int(m_portalCooldownTicks);
        output.writeVar!int(m_seaLevel);
        output.write!bool(m_enforcesSecureChat);
    }
}
