module mc.data.blocks;

import core.atomic : atomicOp, atomicStore;

import std.algorithm : map;
import std.array : array;
import std.checkedint : checked;
import std.conv : to;
import std.exception : assumeUnique, enforce;
import std.file : readText;
import std.format : f = format;
import std.json : JSONValue, parseJSON;
import std.typecons : Tuple, tuple;

import mc.data.mc_json_data : McJsonData;
import mc.data.mc_version : McVersion;
import mc.world.block.block : Block;
import mc.world.block.property : BoolProperty, EnumProperty, Property, UIntProperty;

@safe:

final shared
class BlocksByVersion
{
    // Singleton
    private static BlocksByVersion g_instance = new BlocksByVersion;
    private pure nothrow @nogc this()() scope {}
    static nothrow @nogc BlocksByVersion instance() => g_instance;

    private
    {
        enum string ct_dataType = "blocks";

        BlockSet[] m_blockSets;
        size_t[McVersion] m_blockSetIndexByMcVersion;
        size_t[string] m_blockSetIndexByDataFilePath;
    }

scope:
    private synchronized
    void ensureMcVersionIsLoaded(const McVersion mcVersion)
    {
        if (mcVersion !in m_blockSetIndexByMcVersion)
            loadMcVersion(mcVersion);
    }

    private synchronized
    void loadMcVersion(const McVersion mcVersion)
    {
        const dataFilePath = McJsonData.instance.getDataFilePath(mcVersion, ct_dataType);
        if (dataFilePath in m_blockSetIndexByDataFilePath)
        {
            const index = m_blockSetIndexByDataFilePath[dataFilePath];
            m_blockSetIndexByMcVersion[mcVersion] = index;
            return;
        }

        alias PropertyKey = Tuple!(string, "name", string, "type", uint, "valueCount");

        Block[] blocks;
        Property[] properties;
        size_t[PropertyKey] propertyIndexByKey;

        Property propertyFromJson(const JSONValue propertyJson)
        {
            const JSONValue[string] obj = propertyJson.objectNoRef;

            const name = obj["name"].get!string;
            const type = obj["type"].get!string;
            const valueCount = obj["num_values"].get!uint;
            const key = PropertyKey(name, type, valueCount);

            if (key in propertyIndexByKey)
                return properties[propertyIndexByKey[key]];

            immutable property = delegate Property() {
                switch (type)
                {
                case "bool":
                    return new BoolProperty(name);
                case "int":
                    const minValue = obj["values"][0].get!string.to!uint;
                    return new UIntProperty(name, minValue, valueCount);
                case "enum":
                    const values = obj["values"].arrayNoRef.map!(el => el.get!(immutable string)).array;
                    return new EnumProperty(name, values);
                default:
                    throw new Exception(f!`Unknown property type "%s"`(type));
                }
            }();

            const index = properties.length;
            properties ~= property;
            propertyIndexByKey[key] = index;

            return property;
        }

        const JSONValue jsonRoot = dataFilePath.readText.parseJSON;
        const JSONValue[] blocksJson = jsonRoot.arrayNoRef;
        foreach(const JSONValue blockJson; blocksJson)
        {
            const name = blockJson["name"].get!string;
            const globalStateIdOffset = blockJson["minStateId"].get!uint;
            const stateProperties = blockJson["states"].arrayNoRef.map!propertyFromJson.array;
            const defaultStateId = (blockJson["defaultState"].get!uint - globalStateIdOffset.checked).get;
            blocks ~= new Block(
                name: name,
                globalStateIdOffset: globalStateIdOffset,
                stateProperties: stateProperties,
                defaultStateId: defaultStateId,
            );
        }

        immutable blockSet = new BlockSet(blocks, properties);

        const index = m_blockSets.length;
        m_blockSets ~= blockSet;
        m_blockSetIndexByMcVersion[mcVersion] = index;
        m_blockSetIndexByDataFilePath[dataFilePath] = index;
    }

    synchronized
    ref BlockSet opIndex(const McVersion mcVersion)
    {
        ensureMcVersionIsLoaded(mcVersion);
        return m_blockSets[m_blockSetIndexByMcVersion[mcVersion]];
    }
}

immutable
class BlockSet
{
    private
    {
        Block[] m_blocks;
        Property[] m_properties;

        size_t[string] m_blockIndexByName;
    }

scope:
pure:
    private nothrow
    this(
        in Block[] blocks,
        in Property[] properties,
    )
    {
        m_blocks = blocks;
        m_properties = properties;

        m_blockIndexByName = {
            size_t[string] aa;
            foreach (const i, Block block; blocks)
                aa[block.getName] = i;
            (() @trusted => aa.rehash)();
            return (() @trusted => aa.assumeUnique)();
        }();
    }

    Block getBlock(in string name)
    {
        const size_t* indexPtr = name in m_blockIndexByName;
        enforce(indexPtr !is null, f!`Unknown block "%s"`(name));
        return m_blocks[*indexPtr];
    }

    auto getBlockNames(in string name)
        => m_blockIndexByName.keys;

    alias opIndex = getBlock;
}
