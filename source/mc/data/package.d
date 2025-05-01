module mc.data;

import std.conv : to;
import std.exception : enforce;
import std.format : f = format;
import std.json : JSONValue, parseJSON;


import std.file : readText;
// import std.path;

import mc.world.block.block : Block;
import mc.world.block.property : BoolProperty, EnumProperty, Property, UIntProperty;

@safe:

struct McVersion
{
    string platform;
    string version_;
}

shared
class McData
{
    private
    {
        static McData g_instance = new McData;

        string[string][McVersion] m_dataPathsByMcVersion;
    }

    private
    this()
    {
    }

    static nothrow
    McData instance()
        => g_instance;

    private synchronized
    void ensureDataPathsAreLoaded()
    {
        if (m_dataPathsByMcVersion is null)
            reloadDataPaths;
    }

    void reloadDataPaths()
    {
        shared string[string][McVersion] result;
        const JSONValue byPlatformJson = "mc-data/data/dataPaths.json".readText.parseJSON;
        foreach (const string platform, const JSONValue byVersionJson; byPlatformJson.objectNoRef)
            foreach (const string version_, const JSONValue dataPathsJson; byVersionJson.objectNoRef)
            {
                const McVersion mcVersion = {
                    platform: platform,
                    version_: version_,
                };
                shared string[string] dataPaths;
                foreach (const string dataType, const JSONValue dataPath; dataPathsJson.objectNoRef)
                    dataPaths[dataType] = dataPath.str;
                result[mcVersion] = dataPaths;
            }
        synchronized
        {
            m_dataPathsByMcVersion = result;
        }
    }

    synchronized
    string getDataPath(McVersion mcVersion, string dataType)
    {
        ensureDataPathsAreLoaded;

        enforce(mcVersion in m_dataPathsByMcVersion, f!"Unknown version %s"(mcVersion));
        const dataPaths = m_dataPathsByMcVersion[mcVersion];

        enforce(dataType in dataPaths, f!`Unknown dataType "%s" in version %s`(dataType, mcVersion));
        return "mc-data/data/" ~ m_dataPathsByMcVersion[mcVersion][dataType] ~ "/" ~ dataType ~ ".json";
    }

    JSONValue getData(McVersion mcVersion, string dataType)
        => getDataPath(mcVersion, dataType).readText.parseJSON;
}

// enum JSONValue[] blocksJson = import("blocks.json").parseJSON.arrayNoRef;
// import std.algorithm, std.range;
// static foreach(g; blocksJson.map!(j => j.objectNoRef.keys).joiner.array.sort.group)
//     pragma(msg, g[1], "\t", g[0]);

// Property[string] properties;

// static
// typeof(this) deserializeJson(in JSONValue[string] jsonObject)
// {
//     // Only optional field is harvestTools
//     return {
//         m_id: json["id"];
//         m_name: json["name"];
//         m_minStateId: json["minStateId"];
//         m_maxStateId: json["maxStateId"];
//         m_harvestTools: "harvestTools" in json ? json["harvestTools"] : null;
//     };
// }

// struct Blocks
// {
//     (Block)[] m_byId;
// }