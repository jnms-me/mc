module mc.main;

import vibe.core.core : runEventLoopOnce;

import mc.server.server : runServerTask;

@safe:

@trusted
shared static this()
{
    import memoryerror = etc.linux.memoryerror;
    static if (is(typeof(memoryerror.registerMemoryAssertHandler)))
        memoryerror.registerMemoryAssertHandler;
}

void main()
{
    runServerTask;

    while (true)
    {
        runEventLoopOnce;
    }
}
