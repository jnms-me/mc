module mc.server.player;

import std.uuid : UUID;
import std.format : f = format;

import mc.util.log : Logger;
import mc.world.position : ContinuousPos;

@safe:

immutable log = Logger.moduleLogger;

shared Player[UUID] g_players;

final shared
class Player
{
    private
    {
        immutable Logger m_log;
        immutable UUID m_uuid;
        immutable string m_userName;
        ContinuousPos m_pos;
    }

scope:
    package(mc.server) synchronized pure
    this(in UUID uuid, in string userName, in ContinuousPos pos)
    {
        m_log = log.derive(f!"Player %s"(userName));
        m_uuid.data = uuid.data;
        m_userName = userName;
        m_pos = pos;
    }

    package(mc.server) synchronized
    ~this()
    {
        unregister;
    }

    package(mc.server) synchronized
    void register()
    {
        g_players[m_uuid] = this;
        m_log.info!"Joined the world";
    }

    package(mc.server) synchronized
    void unregister()
    {
        g_players.remove(m_uuid);
        m_log.info!"Left the world";
    }

    pure nothrow @nogc
    UUID getUuid() const
        => m_uuid;

    pure nothrow @nogc
    string getUserName() const
        => m_userName;
    
    pure nothrow @nogc
    ContinuousPos getPos() const
        => m_pos;
}