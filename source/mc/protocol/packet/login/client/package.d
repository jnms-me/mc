module mc.protocol.packet.login.client;

public import mc.protocol.packet.login.client.ack_login_success : AckLoginSuccessPacket;
public import mc.protocol.packet.login.client.login_start : LoginStartPacket;
public import mc.protocol.packet.login.client.plugin_message : PluginMessagePacket;

@safe:

enum Protocol : int
{
    @LoginStartPacket      loginStart         = 0x00,
                           encryptionResponse = 0x01,
    @PluginMessagePacket   pluginMessage      = 0x02,
    @AckLoginSuccessPacket ackLoginSuccess    = 0x03,
                           cookieResponse     = 0x04,
}
