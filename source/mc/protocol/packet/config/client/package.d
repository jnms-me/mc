module mc.protocol.packet.config.client;

public import mc.protocol.packet.config.client.ack_finish_config : AckFinishConfigPacket;
public import mc.protocol.packet.config.client.client_info : ClientInfoPacket;
public import mc.protocol.packet.config.client.plugin_message : PluginMessagePacket;

@safe:

enum PacketType : int
{
    clientInfo      = 0x00,
    cookieResponse  = 0x01,
    pluginMessage   = 0x02,
    ackFinishConfig = 0x03,
}
