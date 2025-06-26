module mc.world.chunk.chunk;

import core.atomic : atomicOp;

import std.conv : to;
import std.range.primitives : isInputRange;

import mc.protocol.stream : OutputStream;
import mc.util.math : ceilDiv;
import mc.util.traits : bitSize;
import mc.world.block.block : Block;
import mc.world.position : ChunkRelativeBlockPos;

import mc.world.chunk.container.base : Container;
import mc.world.chunk.container.direct : DirectContainer;
import mc.world.chunk.container.single_value : SingleValueContainer;
import mc.world.block.block_state : BlockState;

@safe:

enum uint ct_chunkBlockLength = 16;
enum uint ct_blocksPerChunk = ct_chunkBlockLength ^^ 3;

enum uint ct_chunkBiomeLength = 4;
enum uint ct_biomesPerChunk = ct_chunkBiomeLength ^^ 3;

final shared
class Chunk
{
    private
    {
        Container m_blocks;
        Container m_biomes;
        ushort m_nonAirBlockCount;
    }

scope:
pure:
    nothrow @nogc
    invariant
    {
        assert(m_blocks !is null);
        assert(m_biomes !is null);
        assert(m_nonAirBlockCount <= ct_blocksPerChunk);
    }

    /// Empty chunk ctor
    nothrow
    this()
    {
        m_blocks = new SingleValueContainer(0);
        m_biomes = new SingleValueContainer(1);
        m_nonAirBlockCount = 0;
    }

    synchronized nothrow
    uint getBlock(const ChunkRelativeBlockPos pos) const
    {
        if (cast(const SingleValueContainer) m_blocks)
        {
            const singleValue = cast(const SingleValueContainer) m_blocks;
            return singleValue.getValue;
        }
        else if (cast(const DirectContainer) m_blocks)
        {
            const direct = cast(const DirectContainer) m_blocks;
            const size_t index = pos.toIndex;
            return direct[index];
        }
        else
            assert(false);
    }

    synchronized nothrow
    void fillBlock(in BlockState blockState)
    {
        const id = blockState.getGlobalId;
        if (cast(SingleValueContainer) m_blocks)
        {
            auto singleValue = cast(SingleValueContainer) m_blocks;
            singleValue.setValue(id);
        }
        else
        {
            m_blocks = new SingleValueContainer(id);
        }

        m_nonAirBlockCount = id == 0 ? 0 : ct_blocksPerChunk;
    }

    synchronized nothrow
    void setBlock(in ChunkRelativeBlockPos pos, in uint blockId)
    {
        DirectContainer direct = cast(DirectContainer) m_blocks;
        if (direct is null)
        {
            const singleValue = cast(SingleValueContainer) m_blocks;
            if (singleValue.getValue == blockId)
                return;
            direct = new DirectContainer(ct_blocksPerChunk, 15, singleValue.getValue);
            m_blocks = direct;
        }

        const size_t index = pos.toIndex;

        if (direct[index] == 0 && blockId != 0)
            m_nonAirBlockCount.atomicOp!"+="(1);
        else if (direct[index] != 0 && blockId == 0)
            m_nonAirBlockCount.atomicOp!"-="(1);

        direct[index] = blockId;
    }

    nothrow
    void serialize(scope ref OutputStream output) const
    {
        output.write!short(m_nonAirBlockCount);
        m_blocks.serialize(output);
        m_biomes.serialize(output);
    }
}
