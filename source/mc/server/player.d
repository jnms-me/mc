module mc.server.player;

import std.exception : assumeWontThrow;
import std.format : f = format;
import std.uuid : UUID;

import mc.util.log : Logger;
import mc.world.position : ContinuousPos;
import mc.world.world : World;

@safe:

immutable log = Logger.moduleLogger;

final shared
class Player
{
    private
    {
        immutable Logger m_log;
        immutable UUID m_uuid;
        immutable string m_userName;
        World m_world;
        ContinuousPos m_pos;
    }

scope:
    pure nothrow @nogc
    invariant
    {
        assert(m_uuid != UUID.init);
        assert(m_userName.length);
    }

    package(mc.server) synchronized pure nothrow
    this(in UUID uuid, in string userName, in ContinuousPos pos)
    {
        m_log = log.derive(f!"Player %s"(userName).assumeWontThrow);
        m_uuid.data = uuid.data;
        m_userName = userName;
        m_pos = pos;
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
