module mc.world.world;

import mc.protocol.chunk.chunk : Chunk;
import mc.world.block.block : Block;
import mc.world.position : BlockPos, ChunkPos, ChunkRelativeBlockPos, Vec3;

@safe:

World g_world = new World;

shared
class World
{
    private Chunk[ChunkPos] m_chunks;

    private synchronized
    void ensureChunkExists(ChunkPos pos)
    {
        if (pos !in m_chunks)
            m_chunks[pos] = new Chunk;
    }

    synchronized
    Chunk getChunk(in ChunkPos pos)
    {
        ensureChunkExists(pos);
        return m_chunks[pos];
    }

    synchronized
    uint getBlock(in BlockPos blockPos)
    {
        immutable chunkPos = blockPos.chunkPos;
        immutable chunkRelativeBlockPos = blockPos.chunkRelativePos;

        ensureChunkExists(chunkPos);
        return m_chunks[chunkPos].getBlock(chunkRelativeBlockPos);
    }

    synchronized
    void setBlock(in BlockPos blockPos, in uint blockId)
    {
        immutable chunkPos = blockPos.chunkPos;
        immutable chunkRelativeBlockPos = blockPos.chunkRelativePos;

        ensureChunkExists(chunkPos);
        m_chunks[chunkPos].setBlock(chunkRelativeBlockPos, blockId);
    }
}
