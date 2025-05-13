module mc.protocol.packet.config.server.registry_data;

import std.algorithm : move;

import mc.protocol.nbt : Nbt;
import mc.protocol.packet.config.server : Protocol;
import mc.protocol.packet.traits : isServerPacket;
import mc.protocol.stream : OutputStream;

@safe:

final
class RegistryDataPacket
{
    static assert(isServerPacket!(typeof(this)));

    enum Protocol ct_protocol = Protocol.registryData;

    private
    {
        string m_registryId;
        Nbt[string] m_entries;
    }

scope:
pure:
    nothrow @nogc
    this(in string registryId)
    {
        m_registryId = registryId;
    }

    nothrow
    void addEntry(in string entryId, ref Nbt nbt)
    in (entryId !in m_entries)
    {
        m_entries[entryId] = nbt.move;
    }

    nothrow
    void addEntry(string entryId)
    in (entryId !in m_entries)
    {
        m_entries[entryId] = Nbt.init;
    }

    nothrow @nogc
    string getRegistryId() const
        => m_registryId;

    void serialize(scope ref OutputStream output) const
    {
        output.writePrefixedString(m_registryId);
        output.writeVar!int(cast(int) m_entries.length); // Prefixed array length
        foreach (id, ref nbt; m_entries)
        {
            output.writePrefixedString(id);
            const bool hasNbt = nbt != Nbt.init;
            output.write!bool(hasNbt); // Whether optional nbt is attached
            if (hasNbt)
                nbt.serialize(output);
        }
    }
}
