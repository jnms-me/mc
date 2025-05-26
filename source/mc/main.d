module mc.main;

import etc.linux.memoryerror : registerMemoryAssertHandler;

import vibe.core.core : runEventLoopOnce;

import mc.server.server : runServerTask;
import mc.util.log : Logger;

@safe:

immutable log = Logger.moduleLogger;


@trusted shared static
this()
{
    registerMemoryAssertHandler;
}

void main()
{
    runServerTask;

    while (true)
    {
        runEventLoopOnce;
    }
}
