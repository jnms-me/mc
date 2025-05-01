module mc.world.world;

import mc.protocol.chunk : Chunk;
import mc.world.block.block : Block;
import mc.world.position : BlockPos, ChunkPos, ChunkRelativeBlockPos, Vec3;

class World
{
    private Chunk[ChunkPos] m_chunks;

    private
    void ensureChunkExists(ChunkPos pos)
    {
        if (pos !in m_chunks)
            m_chunks[pos] = Chunk.createEmpty;
    }
    
    void setBlock(in BlockPos blockPos, in Block block)
    {
        immutable chunkPos = blockPos.chunkPos;
        immutable chunkRelativeBlockPos = blockPos.chunkRelativePos;

        ensureChunkExists(chunkPos);
        m_chunks[chunkPos].setBlock(chunkRelativeBlockPos, block);
    }
}