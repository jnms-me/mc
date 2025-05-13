module mc.protocol.packet.common.client.plugin_message;

@safe:

mixin template CommonPluginMessagePacket(Protocol)
if (is(Protocol baseType == enum) && is(baseType == int))
{
    import mc.protocol.packet.traits : isClientPacket;
    import mc.protocol.stream : InputStream;

    static assert(isClientPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.pluginMessage;

    private
    {
        string m_channel;
        const(ubyte)[] m_data;
    }

scope:
pure:
    private nothrow @nogc
    this()
    {
    }

    nothrow @nogc
    string getChannel() const
        => m_channel;

    nothrow @nogc
    const(ubyte[]) getData() const
        => m_data;

    static
    typeof(this) deserialize(scope ref InputStream input)
    {
        typeof(this) instance = new typeof(this);

        instance.m_channel = input.readPrefixedString;
        instance.m_data = input.readBytes(input.bytesLength);

        return instance;
    }
}
