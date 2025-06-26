module mc.config;

import core.time : Duration, seconds;

import vibe.core.net : TCPListenOptions;

import mc.util.log : LogLevel;
import mc.world.position : ContinuousPos;

@safe:

struct Config
{
    enum LogLevel ct_logLevel = LogLevel.diagnostic;

    enum string ct_mcDataRootPath = "./mc-data";

    enum string[] ct_listenAddresses = ["0.0.0.0", "::"];
    enum ushort ct_listenPort = 25_565;
    enum TCPListenOptions ct_listenOptions = TCPListenOptions.defaults | TCPListenOptions.reusePort;

    enum size_t ct_packetBufSize = 64 * 1024 * 1024;

    enum Duration ct_keepAliveTimeout = 15.seconds;
    enum Duration ct_keepAliveInterval = 2.seconds;

    enum ContinuousPos ct_spawnPos = ContinuousPos(16 + 8, 16, 16 + 8);
    enum uint ct_chunkViewDistance = 8;

    @disable this();
    @disable this(this);
}
