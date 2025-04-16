module mc.protocol.packet.config.server.registry_data;

import std.algorithm : move;

import mc.protocol.nbt : Nbt;
import mc.protocol.packet.config.server : PacketType;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class RegistryDataPacket
{
    static assert(isServerPacket!(typeof(this)));

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

    void serialize(ref OutputStream output) const
    {
        output.writePrefixedString(m_registryId);
        output.writeVar!int(cast(int) m_entries.length); // Prefixed array length
        foreach (id, ref nbt; m_entries)
        {
            output.writePrefixedString(id);
            const bool hasNbt = nbt != Nbt.init;
            output.write!bool(hasNbt); // Whether optional nbt is attached
            if (hasNbt)
                output.writeNbt(nbt);
        }
    }
}
