module mc.world.world;

import std.uuid : UUID;

import mc.server.player : Player;
import mc.util.log : Logger;
import mc.world.block.block : Block;
import mc.world.block.block_state : BlockState;
import mc.world.chunk.chunk : Chunk;
import mc.world.position : BlockPos, ChunkPos, ChunkRelativeBlockPos, Vec3;

@safe:

private immutable log = Logger.moduleLogger;

shared
class World
{
    private
    {
        Chunk[ChunkPos] m_chunks;
        Player[UUID] m_players;
    }

scope:
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
        const chunkPos = blockPos.toChunkPos;
        const chunkRelativeBlockPos = blockPos.toChunkRelativePos;

        ensureChunkExists(chunkPos);
        return m_chunks[chunkPos].getBlock(chunkRelativeBlockPos);
    }

    synchronized
    void setBlock(in BlockPos blockPos, in BlockState blockState)
    {
        const chunkPos = blockPos.toChunkPos;
        const chunkRelativeBlockPos = blockPos.toChunkRelativePos;
        const id = blockState.getGlobalId;

        ensureChunkExists(chunkPos);
        m_chunks[chunkPos].setBlock(chunkRelativeBlockPos, id);
    }

    synchronized
    void playerJoin(Player player)
    in (player.getUuid !in m_players)
    {
        m_players[player.getUuid] = player;
        log.info!"Player %s joined"(player.getUserName);
    }

    synchronized
    void playerLeave(in Player player)
    {
        if (player.getUuid !in m_players)
        {
            m_players.remove(player.getUuid);
            log.info!"Player %s left"(player.getUserName);
        }
        else
        {
            log.warn!"playerLeave: Player %s already left"(player.getUserName);
        }
    }

    synchronized pure nothrow @nogc
    size_t playerCount()
        => m_players.length;
}
