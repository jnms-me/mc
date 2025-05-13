module mc.world.chunk.container.base;

import mc.protocol.stream : OutputStream;

@safe:

abstract shared
class Container
{
scope:
pure:
    abstract nothrow
    void serialize(scope ref OutputStream output) const;
}
