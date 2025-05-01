module mc.data;

import std.json : JSONValue, parseJSON;
import std.path;
import std.file;

import mc.world.block.block : Block;
import mc.world.block.property : BoolProperty, EnumProperty, Property, UIntProperty;

@safe:

class McData
{
    @disable this();

    static
    void opIndex(size_t index)
    {
        
    }
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
//     immutable(Block)[] m_byId;
// }