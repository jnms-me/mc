module mc.protocol.packet.play.server;

public import mc.protocol.packet.play.server.chunk_batch_finished : ChunkBatchFinishedPacket;
public import mc.protocol.packet.play.server.chunk_batch_start : ChunkBatchStartPacket;
public import mc.protocol.packet.play.server.chunk_data : ChunkDataPacket;
public import mc.protocol.packet.play.server.login : LoginPacket;
public import mc.protocol.packet.play.server.set_center_chunk : SetCenterChunkPacket;

@safe:

enum Protocol : int
{
    chunkBatchFinished = 0x0C,
    chunkBatchStart    = 0x0D,
    teleportEntity     = 0x20,
    chunkData          = 0x28,
    login              = 0x2C,
    setCenterChunk     = 0x58,
}
