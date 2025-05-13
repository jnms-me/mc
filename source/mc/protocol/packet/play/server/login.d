module mc.protocol.packet.play.server.login;

import std.algorithm : each;
import std.conv : to;
import std.exception : assumeWontThrow;
import std.uuid : UUID;

import mc.protocol.enums : GameMode;
import mc.protocol.packet.play.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class LoginPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.login;

    private
    {
        int m_entityId;
        bool m_isHardCore;
        string[] m_dimensionIds;
        int m_maxPlayers;
        int m_viewDistance;
        int m_simulationDistance;
        bool m_reducedDebugInfo;
        bool m_enableRespawnScreen;
        bool m_limitedCrafting;
        int m_dimensionType;
        string m_dimensionId;
        ubyte[8] m_seedHash;
        GameMode m_gameMode;
        GameMode m_lastGameMode;
        bool m_isDebugWorld;
        bool m_isSuperflatWorld;
        int m_portalCooldownTicks;
        int m_seaLevel;
        bool m_enforcesSecureChat;
    }

scope:
pure:
    nothrow
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
        m_viewDistance = 15;
        m_simulationDistance = 15;
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
        m_seaLevel = 0;
        m_enforcesSecureChat = false;
    }

    nothrow
    void serialize(scope ref OutputStream output) const
    {
        output.write!int(m_entityId);
        output.write!bool(m_isHardCore);
        output.writeVar!int(m_dimensionIds.length.to!int.assumeWontThrow); // Prefixed array length
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
