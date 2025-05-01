module mc.config;

import vibe.core.net : TCPListenOptions;
import mc.log;

struct Config
{
    enum LogLevel ct_logLevel = LogLevel.diagnostic;

    enum ushort ct_listenPort = 25_565;
    enum TCPListenOptions ct_listenOptions = TCPListenOptions.defaults | TCPListenOptions.reusePort;

    enum size_t ct_packetBufSize = 64 * 1024 * 1024;

    enum int ct_chunkXMin = 0;
    enum int ct_chunkXMax = 2;

    enum int ct_chunkYMin = 0;
    enum int ct_chunkYMax = 3;

    enum int ct_chunkZMin = 0;
    enum int ct_chunkZMax = 2;

    @disable this();
    @disable this(this);
}
