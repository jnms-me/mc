module mc.data.mc_json_data;

import std.exception : enforce;
import std.file : readText;
import std.format : f = format;
import std.json : JSONValue, parseJSON;
import std.path : buildPath;

import mc.config : Config;
import mc.data.mc_version : McVersion;

@safe:

final shared
class McJsonData
{
    // Singleton
    private static McJsonData g_instance = new McJsonData;
    private pure nothrow @nogc this() scope {}
    static nothrow @nogc McJsonData instance() => g_instance;

    private
    {
        string[string][McVersion] m_dataPathsByMcVersion;
    }

scope:
    private synchronized
    void ensureDataPathsAreLoaded()
    {
        if (m_dataPathsByMcVersion is null)
            reloadDataPaths;
    }

    private
    void reloadDataPaths()
    {
        shared string[string][McVersion] result;

        string jsonFilePath = buildPath(Config.ct_mcDataRootPath, "data", "dataPaths.json");
        const JSONValue byPlatformJson = jsonFilePath.readText.parseJSON;
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

        synchronized (this)
            m_dataPathsByMcVersion = result;
    }

    synchronized
    string getDataFilePath(const McVersion mcVersion, const string dataType)
    {
        ensureDataPathsAreLoaded;

        enforce(mcVersion in m_dataPathsByMcVersion, f!"Unknown version %s"(mcVersion));
        const dataPaths = m_dataPathsByMcVersion[mcVersion];

        enforce(dataType in dataPaths, f!`Unknown dataType "%s" in version %s`(dataType, mcVersion));
        const dataPath = m_dataPathsByMcVersion[mcVersion][dataType];

        return buildPath(Config.ct_mcDataRootPath, "data", dataPath, dataType ~ ".json");
    }
}
