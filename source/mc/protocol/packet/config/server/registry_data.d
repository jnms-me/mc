module mc.protocol.packet.config.server.registry_data;

import std.algorithm : move;

import mc.protocol.nbt : Nbt;
import mc.protocol.packet.base : Packet;
import mc.protocol.packet.config.server : PacketType;
import mc.protocol.stream_utils : write, writeBytes, writeNbt, writeString, writeVar;

@safe:

class RegistryDataPacket : Packet
{
    enum PacketType ct_packetType = PacketType.registryData;

    private string m_registryId;
    private Nbt[string] m_entries;

    this(string registryId)
    {
        m_registryId = registryId;
    }

    void addEntry(string entryId, ref Nbt nbt)
    in (entryId !in m_entries)
    {
        m_entries[entryId] = nbt.move;
    }

    void addEntry(string entryId)
    in (entryId !in m_entries)
    {
        m_entries[entryId] = Nbt.init;
    }

    string getRegistryId() const
        => m_registryId;

    override
    void serialize(ref const(ubyte)[] output)
    {
        const(ubyte)[] content;
        content.writeVar!int(ct_packetType);
        content.writeString(m_registryId);
        content.writeVar!int(cast(int) m_entries.length); // Prefixed array length
        foreach (id, ref nbt; m_entries)
        {
            content.writeString(id);
            const bool hasNbt = nbt != Nbt.init;
            content.write!bool(hasNbt); // Whether optional nbt is attached
            if (hasNbt)
                content.writeNbt(nbt);
        }

        output.writeVar!int(cast(int) content.length);
        output.writeBytes(content);
    }
}
