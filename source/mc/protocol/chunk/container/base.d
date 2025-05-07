module mc.protocol.chunk.container.base;

import mc.protocol.stream : OutputStream;

@safe:

abstract shared
class Container
{
    abstract
    void serialize(ref OutputStream output) const;
}
