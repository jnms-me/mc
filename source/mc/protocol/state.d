module mc.protocol.state;

@safe nothrow @nogc:

enum State : int
{
    handshake = 0,
    status    = 1,
    login     = 2,
    transfer  = 3,
    config    = 4,
    play      = 5,
}