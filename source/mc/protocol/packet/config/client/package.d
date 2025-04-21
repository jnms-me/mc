module mc.protocol.packet.config.client;

import std.meta : AliasSeq;

public import mc.protocol.packet.config.client.ack_finish_config : AckFinishConfigPacket;
public import mc.protocol.packet.config.client.client_info : ClientInfoPacket;
public import mc.protocol.packet.config.client.plugin_message : PluginMessagePacket;

@safe:

enum Protocol : int
{
    @ClientInfoPacket      clientInfo      = 0x00,
                           cookieResponse  = 0x01,
    @PluginMessagePacket   pluginMessage   = 0x02,
    @AckFinishConfigPacket ackFinishConfig = 0x03,
}
