module mc.protocol.packet.play.server;

public import mc.protocol.packet.play.server.chunk_batch_finished : ChunkBatchFinishedPacket;
public import mc.protocol.packet.play.server.chunk_batch_start : ChunkBatchStartPacket;
public import mc.protocol.packet.play.server.chunk_data : ChunkDataPacket;
public import mc.protocol.packet.play.server.game_event : GameEventPacket;
public import mc.protocol.packet.play.server.keep_alive : KeepAlivePacket;
public import mc.protocol.packet.play.server.login : LoginPacket;
public import mc.protocol.packet.play.server.set_center_chunk : SetCenterChunkPacket;
public import mc.protocol.packet.play.server.set_player_position : SetPlayerPositionPacket;
public import mc.protocol.packet.play.server.update_time : UpdateTimePacket;

@safe:

enum Protocol : int
{
    chunkBatchFinished = 0x0C,
    chunkBatchStart    = 0x0D,
    teleportEntity     = 0x20,
    gameEvent          = 0x23,
    keepAlive          = 0x27,
    chunkData          = 0x28,
    login              = 0x2C,
    setPlayerPosition  = 0x42,
    setCenterChunk     = 0x58,
    updateTime         = 0x6B,
}
