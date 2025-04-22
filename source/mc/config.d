module mc.config;

import vibe.core.net : TCPListenOptions;
import mc.log;

struct Config
{
    enum LogLevel ct_logLevel = LogLevel.debug_;

    enum ushort ct_listenPort = 25_565;
    enum TCPListenOptions ct_listenOptions = TCPListenOptions.defaults | TCPListenOptions.reusePort;

    enum size_t ct_packetBufSize = 64 * 1024 * 1024;

    @disable this();
    @disable this(this);
}
