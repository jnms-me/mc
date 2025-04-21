module mc.protocol.packet.config.server;

public import mc.protocol.packet.config.server.finish_config : FinishConfigPacket;
public import mc.protocol.packet.config.server.registry_data : RegistryDataPacket;

@safe:

enum Protocol : int
{
    @FinishConfigPacket finishConfig = 0x03,
    @RegistryDataPacket registryData = 0x07,
}
