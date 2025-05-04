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

import mc.data.mc_json_data : McJsonData;
import mc.data.mc_version : McVersion;
import mc.world.block.block : Block;
import mc.world.block.property : BoolProperty, EnumProperty, Property, UIntProperty;

@safe:

shared
class BlocksByVersion
{
    // Singleton
    private static BlocksByVersion g_instance = new BlocksByVersion;
    private pure nothrow this()() scope {}
    static nothrow BlocksByVersion instance() => g_instance;

    private
    {
        enum string ct_dataType = "blocks";

        BlockSet[] m_blockSets;
        size_t[McVersion] m_blockSetIndexByMcVersion;
        size_t[string] m_blockSetIndexByDataFilePath;
    }

    private synchronized
    void ensureMcVersionIsLoaded(const McVersion mcVersion) scope
    {
        if (mcVersion !in m_blockSetIndexByMcVersion)
            loadMcVersion(mcVersion);
    }

    private synchronized
    void loadMcVersion(const McVersion mcVersion) scope
    {
        const dataFilePath = McJsonData.instance.getDataFilePath(mcVersion, ct_dataType);
        if (dataFilePath in m_blockSetIndexByDataFilePath)
        {
            const index = m_blockSetIndexByDataFilePath[dataFilePath];
            m_blockSetIndexByMcVersion[mcVersion] = index;
            return;
        }

        Block[] blocks;
        Property[] properties;
        size_t[string] propertyIndexByName;

        Property propertyFromJson(const JSONValue propertyJson)
        {
            const JSONValue[string] obj = propertyJson.objectNoRef;

            const name = obj["name"].get!string;
            const type = obj["type"].get!string;

            if (name in propertyIndexByName)
                return properties[propertyIndexByName[name]];

            immutable property = delegate Property() {
                switch (type)
                {
                case "bool":
                    return new BoolProperty(name);
                case "int":
                    immutable uint minValue = obj["values"][0].get!string.to!uint;
                    immutable uint valueCount = obj["num_values"].get!uint;
                    return new UIntProperty(name, minValue, valueCount);
                case "enum":
                    immutable string[] values = obj["values"].arrayNoRef.map!(el => el.get!(immutable string)).array;
                    return new EnumProperty(name, values);
                default:
                    throw new Exception(f!`Unknown property type "%s"`(type));
                }
            }();

            const index = properties.length;
            properties ~= property;
            propertyIndexByName[name] = index;

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
    ref BlockSet opIndex(const McVersion mcVersion) scope
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
        size_t[string] m_propertyIndexByName;
    }

scope:
    private
    this(
        Block[] blocks,
        Property[] properties,
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

        m_propertyIndexByName = {
            size_t[string] aa;
            foreach (const i, Property property; properties)
                aa[property.getName] = i;
            (() @trusted => aa.rehash)();
            return (() @trusted => aa.assumeUnique)();
        }();
    }

    private
    immutable(T) get(T, K)(in immutable(T)[] arr, in size_t[K] indexByKey, in K key)
    {
        const size_t* indexPtr = key in indexByKey;
        enforce(indexPtr !is null, f!`Unknown %s "%s"`(T.stringof, key));
        return arr[*indexPtr];
    }

    Block getBlock(const string name)
        => get(m_blocks, m_blockIndexByName, name);

    Property getProperty(const string name)
        => get(m_properties, m_propertyIndexByName, name);
}