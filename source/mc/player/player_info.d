module mc.player.player_info;

import std.uuid : UUID;

@safe:

shared
class PlayerInfo
{
    private
    {
        UUID m_uuid;
        string m_userName;
    }

    package(mc.player)
    this(const UUID uuid, const string userName)
    {
        m_uuid.data = uuid.data;
        m_userName = userName;
    }

    UUID getUuid() const
        => m_uuid;

    string getUserName() const
        => m_userName;
}
