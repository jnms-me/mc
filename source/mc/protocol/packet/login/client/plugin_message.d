module mc.protocol.packet.login.client.plugin_message;

import mc.protocol.packet.common.client.plugin_message : CommonPluginMessagePacket;
import mc.protocol.packet.login.client : Protocol;

@safe:

final
class PluginMessagePacket
{
    mixin CommonPluginMessagePacket!Protocol;
}
