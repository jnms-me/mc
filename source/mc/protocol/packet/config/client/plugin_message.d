module mc.protocol.packet.config.client.plugin_message;

import mc.protocol.packet.common.client.plugin_message : CommonPluginMessagePacket;
import mc.protocol.packet.config.client : Protocol;

@safe:

final
class PluginMessagePacket
{
    mixin CommonPluginMessagePacket!Protocol;
}
