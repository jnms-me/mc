module mc.protocol.packet.common.client.client_info;

@safe:

final
mixin template CommonClientInfoPacket(Protocol)
if (is(Protocol baseType == enum) && is(baseType == int))
{
    import mc.protocol.packet.traits : isClientPacket;
    import mc.protocol.stream : InputStream;

    static assert(isClientPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.clientInfo;

    private
    {
        string m_locale;
        ubyte m_renderDistance;
        int m_chatMode;
        bool m_chatColors;
        ubyte m_displayedSkinParts;
        int m_mainHand;
        bool m_textFiltering;
        bool m_showInOnlinePlayers;
        int m_particleLevel;
    }

scope:
pure:
    private nothrow @nogc
    this()
    {
    }

    nothrow @nogc
    string getLocale() const
        => m_locale;

    nothrow @nogc
    ubyte getRenderDistance() const
        => m_renderDistance;

    nothrow @nogc
    int getChatMode() const
        => m_chatMode;

    nothrow @nogc
    bool getChatColors() const
        => m_chatColors;

    nothrow @nogc
    ubyte getDisplayedSkinParts() const
        => m_displayedSkinParts;

    nothrow @nogc
    int getMainHand() const
        => m_mainHand;

    nothrow @nogc
    bool getTextFiltering() const
        => m_textFiltering;

    nothrow @nogc
    bool getShowInOnlinePlayers() const
        => m_showInOnlinePlayers;

    nothrow @nogc
    int getParticleLevel() const
        => m_particleLevel;

    static
    typeof(this) deserialize(scope ref InputStream input)
    {
        typeof(this) instance = new typeof(this);

        instance.m_locale = input.readPrefixedString;
        instance.m_renderDistance = input.read!ubyte;
        instance.m_chatMode = input.readVar!int;
        instance.m_chatColors = input.read!bool;
        instance.m_displayedSkinParts = input.read!ubyte;
        instance.m_mainHand = input.readVar!int;
        instance.m_textFiltering = input.read!bool;
        instance.m_showInOnlinePlayers = input.read!bool;
        instance.m_particleLevel = input.readVar!int;

        return instance;
    }
}
