module mc.protocol.packet.common.client.client_info;

import mc.protocol.packet.config.client : PacketType;
import mc.protocol.packet.traits : isClientPacket;
import mc.protocol.stream : InputStream;

@safe:

final
class ClientInfoPacket
{
    static assert(isClientPacket!(typeof(this)));

    enum PacketType ct_packetType = PacketType.pluginMessage;

    private string m_locale;
    private ubyte m_renderDistance;
    private int m_chatMode;
    private bool m_chatColors;
    private ubyte m_displayedSkinParts;
    private int m_mainHand;
    private bool m_textFiltering;
    private bool m_showInOnlinePlayers;
    private int m_particleLevel;

    private
    this()
    {
    }

    string getLocale() const
        => m_locale;

    ubyte getRenderDistance() const
        => m_renderDistance;

    int getChatMode() const
        => m_chatMode;

    bool getChatColors() const
        => m_chatColors;

    ubyte getDisplayedSkinParts() const
        => m_displayedSkinParts;

    int getMainHand() const
        => m_mainHand;

    bool getTextFiltering() const
        => m_textFiltering;

    bool getShowInOnlinePlayers() const
        => m_showInOnlinePlayers;

    int getParticleLevel() const
        => m_particleLevel;

    static
    typeof(this) deserialize(ref InputStream input)
    {
        typeof(this) instance = new typeof(this);

        instance.m_locale              = input.readPrefixedString;
        instance.m_renderDistance      = input.read!ubyte;
        instance.m_chatMode            = input.readVar!int;
        instance.m_chatColors          = input.read!bool;
        instance.m_displayedSkinParts  = input.read!ubyte;
        instance.m_mainHand            = input.readVar!int;
        instance.m_textFiltering       = input.read!bool;
        instance.m_showInOnlinePlayers = input.read!bool;
        instance.m_particleLevel       = input.readVar!int;

        return instance;
    }
}
