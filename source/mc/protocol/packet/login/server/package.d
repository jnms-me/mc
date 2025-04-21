module mc.protocol.packet.login.server;

public import mc.protocol.packet.login.server.login_success : LoginSuccessPacket;

@safe:

enum Protocol : int
{
    loginSuccess = 0x02,
}
