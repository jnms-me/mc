module mc.main;

import vibe.core.core : runEventLoopOnce;

import mc.config : Config;
import mc.kelder : Kelder;
import mc.server : Server;

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
    Server server = new Server(Config.ct_listenAddresses, Config.ct_listenPort);
    server.runAsync;

    Kelder.instance.generateWorld(server.getWorld);

    while (true)
    {
        runEventLoopOnce;
    }
}
