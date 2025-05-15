module mc.main;

import vibe.core.core : runEventLoopOnce;

import mc.util.log : Logger;
import mc.server.server : runServerTask;

@safe:

immutable log = Logger.moduleLogger;

void main()
{
    runServerTask;

    while (true)
    {
        runEventLoopOnce;
    }
}
