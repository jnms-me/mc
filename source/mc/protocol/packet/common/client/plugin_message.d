module mc.protocol.packet.common.client.plugin_message;

import mc.protocol.packet.base : Packet;
import mc.protocol.packet.config.client : PacketType;
import mc.protocol.stream_utils : read, readBytes, readString, readVar;

@safe:

class PluginMessagePacket : Packet
{
    enum PacketType ct_packetType = PacketType.pluginMessage;

    private string m_channel;
    private const(ubyte)[] m_data;

    private
    this()
    {
    }

    string getChannel() const
        => m_channel;

    const(ubyte[]) getData() const
        => m_data;

    static
    typeof(this) deserialize(ref const(ubyte)[] input)
    {
        typeof(this) instance = new typeof(this);

        instance.m_channel = input.readString;
        instance.m_data = input.readBytes(input.length);

        return instance;
    }
}
