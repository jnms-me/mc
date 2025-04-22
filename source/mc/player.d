module mc.player;

import core.atomic : atomicStore;

import std.algorithm : map;
import std.conv : hexString, to;
import std.format : f = format;
import std.json : JSONValue;
import std.range.primitives : empty, front, popFront;
import std.traits : EnumMembers;
import std.uuid : UUID;

import eventcore.core : IOMode;

import vibe.core.core : runTask, yield;
import vibe.core.net : NetworkAddress, TCPConnection;
import vibe.core.task : InterruptException, Task;

import mc.config : Config;
import mc.log : Logger;
import mc.protocol.enums : GameMode;
import mc.protocol.nbt : Nbt;
import mc.protocol.packet.traits : getPacketImplForProtocolMember, isClientPacket, isPacket, isServerPacket;
import mc.protocol.state : State;
import mc.protocol.stream : EOFException, InputStream, OutputStream;
import mc.protocol.sub_chunk : SubChunk;
import mc.util.meta : getMember, members, stringof;
import packets = mc.protocol.packet.packets;

@safe:

immutable log = Logger.moduleLogger;

Player[] players;

final
class Player
{
    private Logger m_log;

    private NetworkAddress m_remoteAddress;
    private State m_state;
    private UUID m_uuid;
    private string m_userName;

    private OutputStream[] m_outgoingPacketQueue;
    private Object m_outgoingPacketQueueMutex = new Object;

    void rederiveLogger()
    {
        string prefix = "Player";
        if (!m_uuid.empty && m_userName.length)
            prefix ~= f!" (%s) %s"(m_uuid, m_userName);
        else if (m_remoteAddress != m_remoteAddress.init)
            prefix ~= f!" %s"(m_remoteAddress);

        m_log.atomicStore(log.derive(prefix));
    }

    void handleConnection(scope TCPConnection conn)
    {
        m_remoteAddress = conn.remoteAddress;
        rederiveLogger;
        
        players ~= this;

        Task reader = runTask(&readerTask, conn);
        Task writer = runTask(&writerTask, conn);

        while (reader.running && writer.running)
            yield;
        reader.interrupt;
        writer.interrupt;
    }

    private nothrow
    void readerTask(scope TCPConnection conn)
    {
        try
        {
            ubyte[] buf = new ubyte[](Config.ct_packetBufSize);
            immutable(ubyte)[] readData;

            while (conn.waitForData)
            {
                size_t read = conn.read(buf, IOMode.once);
                readData ~= buf[0 .. read];

                immutable(ubyte)[][] readPackets;
                while (readData.length)
                {
                    // Setup temp InputStream for readVar
                    InputStream input = InputStream(readData);

                    // Call readVar
                    size_t lengthPrefix;
                    try
                        lengthPrefix = input.readVar!int.to!size_t;
                    catch (EOFException e)
                        break;

                    // Determine how many bytes readVar advanced
                    ptrdiff_t lengthPrefixLength = readData.length - input.data.length;
                    assert(lengthPrefixLength > 0);

                    // Add this packet
                    immutable(ubyte)[] packet = readData[lengthPrefixLength .. lengthPrefixLength + lengthPrefix];
                    readData = readData[lengthPrefixLength + lengthPrefix .. $];
                    readPackets ~= packet;
                }

                foreach (InputStream input; readPackets.map!InputStream)
                    handleRawPacket(input);
            }
        }
        catch (InterruptException)
            m_log.diag!"Reader task interrupted";
        catch (Exception e)
            m_log.error!"Exception in reader task: %s"((() @trusted => e.toString)());
        m_log.info!"Client disconnected";
    }

    private nothrow
    void writerTask(scope TCPConnection conn)
    {
        try
            while (conn.connected)
            {
                synchronized (m_outgoingPacketQueueMutex)
                    while (!m_outgoingPacketQueue.empty)
                    {
                        const OutputStream packet = m_outgoingPacketQueue.front;
                        m_outgoingPacketQueue.popFront;

                        conn.write(packet.data, IOMode.all);
                        conn.flush;
                    }
                yield;
            }
        catch (InterruptException)
            m_log.diag!"Writer task interrupted";
        catch (Exception e)
            m_log.error!"Exception in writer task: %s"((() @trusted => e.toString)());
    }

    private
    void handleRawPacket(InputStream input)
    {
        const int protocol = input.readVar!int;

        void throwInvalidState()
            => throw new Exception(f!"Entered invalid state %s"(m_state));

        void warnUnimplementedProtocol(alias ct_protocol)()
        {
           m_log.diag!"Dropping packet for unimplemented protocol %s in state %s"(
                ct_protocol.stringof, m_state,
            );
        }

        void warnUnknownProtocol()
        {
           m_log.diag!"Dropping packet for unknown protocol %02x in state %s"(
                protocol, m_state,
            );
        }

        void handleProtocol(alias ct_protocol)()
        {
            static if (is(getPacketImplForProtocolMember!ct_protocol Packet))
            {
                Packet packet = Packet.deserialize(input);
                m_log.dbg!"Got a %s"(packet.stringof);
                handlePacket(packet);
            }
            else
                warnUnimplementedProtocol!ct_protocol;
        }

        void handleState(alias ct_state)()
        {
            static if (is(mixin(f!"packets.%s.client"(ct_state.stringof)) client == module))
            {
                static assert (is(client.Protocol baseType == enum) && is(baseType == int));
                sw: switch (protocol)
                {
                    static foreach (ct_protocol; EnumMembers!(client.Protocol))
                    {
                case ct_protocol:
                        handleProtocol!ct_protocol;
                        break sw;
                    }
                default:
                    warnUnknownProtocol;
                    break;
                }
            }
            else
                throwInvalidState;
        }

        sw: switch (m_state)
        {
            static foreach (ct_state; EnumMembers!State)
            {
        case ct_state:
                handleState!ct_state;
                break sw;
            }
        default:
            throwInvalidState;
        }
    }

    private
    void handlePacket(packets.handshake.client.HandshakePacket packet)
    {
        m_log.dbg!"  protocolVersion = %s"(packet.getProtocolVersion);
        m_log.dbg!"  serverAddress = %s, port = %s"(packet.getServerAddress, packet.getPort);
        m_log.dbg!"  nextState = %s"(packet.getNextState);

        switchState(packet.getNextState.to!State);
    }

    private
    void handlePacket(packets.status.client.StatusRequestPacket)
    {
        m_log.dbg!"Sending status response";
        sendStatusResponse;
    }

    private
    void handlePacket(packets.status.client.PingRequestPacket packet)
    {
        m_log.dbg!"Sending pong response";
        sendPacket(new packets.status.server.PongResponsePacket(packet.getPayload));
    }

    private
    void handlePacket(packets.login.client.LoginStartPacket packet)
    {
        m_log.diag!"  userName = %s"(packet.getUserName);
        m_log.diag!"  uuid = %s"(packet.getUuid);

        m_userName = packet.getUserName;
        m_uuid = packet.getUuid;
        rederiveLogger;

        m_log.dbg!"Sending login success";
        sendPacket(new packets.login.server.LoginSuccessPacket(packet.getUuid, packet.getUserName));
    }

    private
    void handlePacket(packets.login.client.AckLoginSuccessPacket)
    {
        switchState(State.config);

        m_log.dbg!"Sending registry data";
        sendRegistryData;
        m_log.dbg!"Sending finish config";
        sendPacket(new packets.config.server.FinishConfigPacket);
    }

    private
    void handlePacket(packets.login.client.PluginMessagePacket packet)
    {
        m_log.dbg!"  channel = %s"(packet.getChannel);
        m_log.dbg!"  data = %s"(packet.getData);
    }

    private
    void handlePacket(packets.config.client.ClientInfoPacket packet)
    {
        m_log.dbg!"  packet = %s"((() @trusted => packet.toString)());
    }

    private
    void handlePacket(packets.config.client.PluginMessagePacket packet)
    {
        m_log.dbg!"  channel = %s"(packet.getChannel);
        m_log.dbg!"  data = %s"(packet.getData);
    }

    private
    void handlePacket(packets.config.client.AckFinishConfigPacket)
    {
        switchState(State.play);

        m_log.dbg!"Sending login to world";
        sendPacket(new packets.play.server.LoginPacket);

        m_log.dbg!"abilities";
        sendHexPacket(0x3a, hexString!("0f" ~ "3d4ccccd" ~ "3dcccccd"));

        m_log.dbg!"entity_status";
        sendHexPacket(0x1f, hexString!("00000000" ~ "18")); // op level 0

        m_log.dbg!"position";
        sendHexPacket(0x42, hexString!"014021000000000000c04f8000000000004021000000000000000000000000000000000000000000000000000000000000000000000000000000000000");

        m_log.dbg!"Sending world time";

        m_log.dbg!"spawn_position";
        sendHexPacket(0x5b, hexString!"0000020000008fc100000000");

        m_log.dbg!"game_state_change";
        sendHexPacket(0x23, hexString!("0d" ~ "00000000")); // Start waiting for chunks

        sendAllChunks;
    }

    private
    void sendStatusResponse()
    in (m_state == State.status)
    {
        enum ct_jsonStatusTemplate = JSONValue([
            "version": JSONValue([
                "name": JSONValue("1.21.4"),
                "protocol": JSONValue(769),
            ]),
            "description": JSONValue([
                "text": JSONValue("Vage 12ul minecraft"),
            ]),
            "players": JSONValue([
                "online": JSONValue(0),
                "max": JSONValue(0),
            ]),
            "favicon": JSONValue("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAGYktHRAD/AP8A/6C9p5MAAAAHdElNRQfpBAIALB8WL+j6AAAX+UlEQVR42s2b+5MkV5XfP+dmZj27nt1V3dPdMxr1zEgjzUsI2AUhQCxhMKxjbWzH2htB7LIEG178g8OOcITDv/k/8A/rX/YHIyBswsEujoVYwI/lKYHEy0LzEKPRvLt7uru6u97vzHuPf6jqnhFSV5cQYN+IjMyqypt5z/eee88533NKmKKdP/9FPM8zYRjOqep7gRnATdFVRaQDvKTKmiox4LiIvlNElkREVZ0RwQOMqhgQTxVPUIOoUcWIiDe+R1SxoBFIBBKOrgmBCDQUMRHo+DMhaKQqVpV1iK4CDcBdufIZAPxpALA2wtowJWIeE5FPDiN/wVovOqyfiOJ7NjRGv+IZ/Zpzrg08qWr+ILLeKeuMFVExoiKiIiBiVAQVBDGiiEFEnIioEcCpqHPirIqzTtQ5zzlnnKroeFL2DkVwoM6IimfcauDzLdCvgLTPnfsCly79yXQAgACSU5XzxuiHL5y4UVguV1CVicIPhjFu3Ftkt5FLdfuJlqo853n8bjbd+cDRcmVxZfEeRhQRHb1h7/rNPouOVEoF5wxOBTs+O2dQldFv4/ODn+vtGTZ2Z3vrO6USai4GgV6ylmhqDQBBVXLGuIcTsSGfeP9z/P5TP8Ra78AennFUWxn++rvP8L9/+q73tbrJm0a4CZxaLm3P/KP3P8c/+71vY0QnAjlNU0CdGQHiDFYFaz3s+Ltb9xb52xffk/z6D5965zAKPhJGpmZEb58//8XpABAB60w+EQxXFmd3Y/PFKtlMFxcdPHAjSiwI+ejv/JhX7x7j5r3Fkue7RwU9VcrXMwvFKkYUhP3Z/VWbAIjF8+y+luwBgwqFR65Rb89w5dbDuVsbi5/s9hOXxLO3RQ7RgDNnnt2/ds7kA8+eXC5XgvxMG2Qk5KRRxYKQhWKVdLIHMCuGxxEtlgs1WShW70/fr7ntAToCRsGHhxY2Ob9yM3ZvZ+5kq5uaMxJijIeZ7oGCUyl6nl1eLm0HmVT38IGPf/c9uwdUUeAxkMRCscr8HgC/jeYgm+7w0MImgR8lVCWbTscCEaYDwFo7A5R9z2aXS9uSnQaAvXeP1VFEcyJuJeaHQSlfp5ht/fYAAGJ+RDbdwYgqaGY4jDKqbto9QBaBxcCzLJW2mZkGAAF1wmAYI3IGVDKecX65UPPzM23wGFnq30bT0XLMpjsY41AlG0U2C1QnAmDMeBUpS75nl1KJPkfLFdKp/lQa4Jyh1U0RhgEKMd+zwVJp26QTfVwo9AZxIuu94XDj3VwfMHUPmrjIeswke8wXq2SSPcTooePxjCPwo739wQf1QabTAEWOBr49BshqpUwm1SWb6pKMDyb2i6xHpVagO4hjRK1Tsc3OTPz7L1/g+voSwzAgHAttHwBgX+ixSdMHbP2e/Z9J9njk6CofvPAyc/n65A0ZCCOfbj+BOoMI3ZGHeggAuvdMZdYYl2t1U4OvPv90bKtalHefvsqJpfWDOwuE1uNupUyrmwqN0bVhGFt75fZDx39x51iCPW/tjQdvcv3gGVURIHN8YbO4NLdDJtUlmRgcrAUC3X6CSrVI5IwDduJxvxpFOhmAfXMi2nEqd2utjHvxyplTUeQn5nINVpbWOdATEIgin9VKmXYvWVPlb0CeVeXdzkkWCEVkqKpDRYYCQxEdqJpQIULVKmqNEQtiUawikapzIpqOrP9P273kv9nYnZVHj90lmZwMQGcQp1LPY63XB6r9vhv4/nRLQIFvq/Lq0PqnQ+v9B2PcwmHqv68BW/O0uql7xrhXVZNXRLoV0JgITgSr6qyqsSJYz7PWOXHOec66SFV7LpFMquf56nk5t7Pzl7qw8Ec8//xFOXHq3AXrDLVWhv4wdqgQ3X6CSj0fWWcqItqS8cxN6Qrr9deuffP6yol/EHqeG5YLNcqFGhMdWAfdXpKtWkFb3eSaiLsncsXBw1sHvkVBdRTTGAMQEEWKtRGqVRKJP2Rnp8f73ndKt7axqqLDMJBJLvneZHT7CbZrhcg6c09EOwAvv3xIMHTp0p8CcObM5zh56mNlVX0UiJXydeZyjYkvHA4Cths5Wt0UgzC2Hg+Ga6rHAeXKlU9Nh/vr4eH8+S8SjwvttlcQoWiMI5PqEgvCw7rS6qao1AphZL11I9re+2lKP8CgSlaE475xwWy2SSHbmrjmWr0kq5UyYeQDrHmeXX/bQY+CqifAGSPuTDI+kMcfvsVstjnRDPZ7MTZrBbZqhTCywXXf05qM18BUnuDIHns533MPzeYaQTbdGTkyByIGzU56BMBo09kIgpMVVQ9Vb5pXvq4988x3OH363+F5EbFYXSMrZ/Mz7QvHFzZloVAjiEUTAbixvsS11aMMw6Bjnbwo4jb2OkzUgHe+8y8BGAwU50w28KPjR2Z3R7HApCbQ7KZYq5Qja70tEXai6FXOn/8SAJcvj247c+bLADgXEARtwOGcY292VBURYXf3LsacxvNmvX4/diGM/PcXs82VCyduMJPsceBmJIDClVsPc/XOQ32FG6ruFyKJVhQ1DwfAmPskhELO9+xDi3M7wUyyd6jn1eykWd0uDUPrXTfi6tbG+NKXvgPA+fOfG42MNqoGz+tiTF5Unc9IK729Q1WMU/GQuPQHraMi7s+z6fYzJ5bWZ951+irx2PBAck4V+v0EV1ePcvPe4j3geSNSd66PiDkcAOdG0LZaWWKJXsH37JEjs7v+oRowBmBtuxQOw+C6EVfXNwVMASSK5ozvDzJACSg8eIhowRPNq7p54Ljn2TMfuPBy/h8+/TznVm4SD8I3nwyB4TDg6upRVrfmafeSd2NB9B1EO8J9J28iAMPh6OdcbrfQG6TKnmdji7O7HKYBvW6M3WaWTi85dE5ueJ6rgXL27LNjYA2XLv0pFy58blFV3uV08K7+0KyoellVEkAcSPieTcwke/FsqptIJ3vpQqY1c3JpPfHMO17iiZPXScSHB4/DwDAM+OnV02xWi0NVuQH83IgOVIWpSNE9DQBZVFjajwYPAWC7nmerVsA5E6qa6yKuDpBMNOn1M1lr/Ycffey/PAo87nv2XeVC7Z2z2eZCNt0hHoTEg5BYEJKIDUkn+swke8ykusxmWpw6usrxhc2R53cQLy1ghx6rlTI/vnqa7Ub+Nc9zPxfRqnPmdQzUIWZwj1ORpcCzS8n4gIVilURiOJEU36oWqdQKINq1ztz51rf+uPn3P/qf6PZyReA9gR99Ih2Ev5dODB7OzrTl8eO3uXDiBiuL98ilO+TSnZF/Hx+8IcjZH/whpPy93Vl+cPks1+4e69dbM9+PBdELqoKIcunSp6YDYBwOY51Zzqa6S/PF6igCnGDOVYWtapGdej5EZVNEax/5yLM4xyzIh0T4t9l057HHHrqTeursZXnykWvMF6uk4gMCP8IzDmPciC02v6RmU5IwYejz8vWTfPW59w9a3dQlI/o/h8O5n3te8w33HgjA6dNfQFUJAtWwL0szqe7S8tyOxPwJLIaMRrlZK1Cp5xsKN0W071w4Y13io7Eg+ux8ofbER3/nx/H3n7/I0XKFcqGG57s3Cqi8db5QAAM/vfIo3/o/T7K2M7djrf8FY/hxLLZhY7HO9ACoCtnskGo1FnMqR9KJ/vzRcgXfn+B0KLgxB1Cp52uqch1V64g/HY+F/3y+UHv6o+/+CX/w9POcPLZ+X8hpckyThB7b+/4gxo31Jb7x4nt46bVTVWu97yjmf1y58tmNc+ee5Sc/+cy4078+HABjHNVqYES0qCrlmWQvOFquEIyp54NAa/cTVBs5Gq1MLR4b3jZG56zzP1HMtD781Jkr/NGHv8WR0g4c/JjDBR6DrYCLPELr0eymuLG+xN/+8Cl98crjw0qt8ILv2S8K0ca5c3+ByIA3W7sTAFCAGPCwWsnNpLosT9IAgTDyWNsu0eymUKiqyraIfsKIvuf0sbupf/LMd5mdFEQdBCzAXhyxtweq0B/GqLUy3N44wgtXzvDcxfNup5HrdPvx/yXofwV+KOJ6k9zvCQAIqsREOGFE89lUl8XZ3ZEGHADAHgHS6qYQ0a6qqIh87LHjtx9579nLnFxaH0Vuk9a2AB7YoaFSLbJZK1Bvz9Dupmj1krQ6aZq9JO1uik4/wWAYo95JU6kWW/d2Z38cWe+boC96xl4FOntm7+LFT741AEZgSyDoiUyqmy9mWmRS3YkEZBj5rG7N0+knekbUgR43oo+84+T1xHsef4VEbDhZcIV2N8nNe4u8trbMaqXMZrVIq5ui20/0271kr9VN9ZvdVK/VTfV6g3gX0Z4R7RqjN31jv+95w79Tl9+F5r4fc/nyp96aBjzxxLNEEaiTmBo9US7U8uVCbXIK6wEOsN1Lrok48Tz7vkyqFz/z8C1OLa9Nwhp1QqOT5uXrJ/mb595vf/SLx7rtXrKN0kNoglRRdhSpgu4AO4nYYFuEbWBjfFTBqpgK4HP58p9xWDtEA4gJrMzl67lyoTZKM03gAMLIZ61S1mYntQZIIhY+9fjxW6nFuZ1RaGMP7ltvzfDiK4/z7Dc/prc2jmwOhrHnI2u+rsolQRqIRKBWEIuoFXRcJ4BllGGIRkP2eSs77IEAPPFER156KVNEtFTKNYJyoTb5SRE0Oml2Gjk6/WSkKql4EC4/ceq6v3BIGkydcOX2cb7yvQ/aG+tL6+1u6gu+H33NiL39jif/8c7Fi19D1Y4DmPFa4QHW+nXNcPnyZ98eAM7B5cvJGUSPgqRL+TrzkzhAgW4vwWa1SHcQF+dMxjOOdLIXP7dyk1K+PtHW31hf4gcXz/PStUdqw8j/aiyI/ptz8goi/OxnX2Zj4xJzc6e4fv1fTS3Y2wJAFayVPOgJERdMwwE2uylWt+aJrKciOpdM9OVIscrKkQ2SqcGBWumc4YeXz/LClTP9MPJ/AfL5eFyuRZHi+6NNs17/C+r1X7vsBwOwVxDhiVtJxoaxUq5BJtOduIZb3RSr2yWNIj9UKJXzde/CyeukEv0DX64qdAdxXltb5tbmkduKfB3kbq+nUSz2G8ibHw7A3tr6ApE1+VRiuLJQrAbZmfaIp5kAQLOT5u7WvAwj33POzJTydXnykWsj0+fevM8w9HltbZl7u7P0BvH1RCz8HtDyvBE4P/vZv/jtAvDxj38agLW1p3FhkPM9u7JcrsSmSYe37i8BLx4bcmR2l9PH7h7s+AgMhjEu3TjBbjMbCXpbRF41xgydc7z88h//xoV/AwA3bnwcgGRyB6fJgu/Z5aW5Hf/QgggL9fYMW7UCkfWYzTY5Wq5QytcPdpwEBmHA1bvHqLcya8a4G865unNOjZmKrP71AxCPj+Jl1SALLPieTS6XK3IYAPXWDDuNHMNRDoCluR2WSttT+Q2rlbI2u+lVz+iqvL20wdsHwLlR0CDCEZAjvmfN0dI2hy2ByijpsF+ctFCssjCl31BrZej242u+Z9f27PqlS4er/4hSN4zSaD1U9QEKD1555U/eOgB7FJhz44KIMQWWShxcEKHAVq3AVrW4/918oUa5WJ3oN3R6CTZ3Z+kNY0TWW/dHmaP9tzz66H/ev93zZJwrMIjsvbULKMY0gGJCVWOqEgWB7TonnD37+YkxwBsAeOaZ77Czc2cklJrFZLy/VMy0yM20R3cdRASNKbCtWgEYVY6Vi1XK+frBb92zGpUykfWcCPdU/Q1jhoDh7NnPjwbnG9rtgfE844P4gO9UfFQCBV9VArGltIibRyQrRrvWyTWBTeBg+3uIBuDULObS3cXlckX8g8Lfvdt1pAGVWgEB4rEhs9nmVH7D+nZJI+u1QSueN2irmn2lCQKPXi/0PM8UQBaARWDRiC4iuiiwiHAEollGNLqnKj3g58B/BH7wlgBYWfldVlcvcfz4k7K6fmcpnewuHi1XCA6hwMLIZ6eeZ6eRw/csC8XqSGsO8Rta3RRr26Uosl7F91xG1XtClSWnpuRU5oYRc2h8VpWsjSSjKmnPszO5dGemmGnNFDKtmVy6k86mO95crkGlludn1x61tXZmJwz9pDHTOVL7APz0p39NJlOQ7e2bOVWvlE70E8t7ABwghLWGaiszKlIYxCmMzd+hZlNGG+CtjSPS7ScSkTV/zzrzZOCHC5lUdy6d6JUSscFcIhbmk/EByfiAVKJPOtEnl+5QmGlTyDYpZFoUMi3m83VeuHKGl66f6gmsKdKelmjcB8DaEGsJQB5S9QszyR7LpW0mLYE9AqTZTcGoMpzlaQDQcf2gqD+Xaxz1jFsO/IhUok8p16BUqEkpX6eUr1PO1ykXapTydYqZFr4f3d9c9wqonUGBWjM7iKz5hedFu9Na1Af2AAMjDnBFlXwm1WW5tD2ZArtfBAVA4EccLVcONZs4OLW8xp/9/tcRUYrZppTydTLpDoFn8T2LZ9zo7Fl84/DG3z1Iij64B22OCqCGTrlq0Oq0kcQ+ACIGhZgRPZFJ9XLFTIvcuLDwTdt9R2YfAN+zHJsGAIWFQo0PPPFzjCiJ2JBkfIAEel+4g86/nDtglAXa2J0FpKdqXlO0LlN6VT7Ae9/7ZdrtHs5JgOhKKd/Il/L10foXDhQmGhdBNTtpfM+SHvsNyfjgUADi8SHxxPD1gr3VytGxjBu7s2zVChGqWyAVEWudW5zqEQbA8zycc6hKDOXhcr6Wmy9WR57dpNKTYYz1nTlavSTJ2JDZXGO0/qetPbv/345fSXDnhMEwYLVSZqtarClcE9wAPETaUz3KAFhr6XT6GCNphKOzuUZqfo8DPGAANjTsNrM0OmmGYUAm3WH5MLP5NpvC/qSEkU+1meXqnYe4evcYm9ViVVWuAgPV6YMpH6Dd7pDNxhORtUuIZkrjnXfSKhrbcQZhgFMhk+qynzn6VQCQNzkUooHHbjPLdj3Pdj2/l3Zjt5Eb5Qt6KW6sLzIMg6qIXBFhAHD58h9OD4BzCpBH9QQQ26sDnDTYZifNnc0FonEEmB0D4B+aPH1AwL3rCHr9OK1x8uPBJEitPYo095yt3Wa2tV3PN6rNbKPTTzSAZuDblmfciyJcBiYkHw4AYEyB5UV0JRaM6vlzmc7EAoRGJ83tzYW9Mrj7GvDLS2Avo+WEKHp9VXhoPaLIp9VNsVUrsL5dYn1njo3d2XB9Zy7c2J0Nm530MLJeKKIDkAbKXYTbwK1kfHhL1d02xru7sHC6sbn5mmu3d0mnC28VAIN1Xi4VH5yYL9Ri2XRnL9KcqAF3t+YJIx8RZc9v2HOc9vN5YzDao6pRNnbmuLc7Ozp25tjYmdN6e4b+KCrUyHq9yJp7kfNuRda/FUXmtlO5BeauMVJRp31EQyOEIjpU1VDEhK+99gOdmZljZmYW1enTzf7581/EWodzkvf9aGW5tB1kDyuC0pEGrG2XCK1HLt2hnK+TSvSpNnJsN3LsNHJs1/P7qltvz9Dqpmj3E3RHR73TT2y0uunN3iC2EVmzIcImsAXUjHFN33MNI7Zh0AZ4rUE/jOJxw+sJI0HV8aEP/Tk3b/4IgO9+90PTAyAiqCqK5HzPHl2a27kPwIMb0l6zUK1nWNsu0eqmcCr4nuVupcx//94H2W1m2ann2W1mqTazg51GtrHTyDdb3VTDqTQFbYhQE9GKiG4aYcP37GbghxueZzdFwqa1MZzzMOZ+8kNEOXcuzenTSa5f7/NXf/X6Te7ixekIkDcAoKokkwkzbGnR92xxcXbXpBN9NBT6YUAU+ftrdhgGNLspXr17jEs3V0AlBDZ7g3jsB5fOxZ+/eN660Xch0FZlA+UOIrdjQXRHVW+L6B3QLUj0YCijGRzplarQ789x4sQ3+MY3PvdLyN8vsPx1Nl9VGQ6H8xAs+J4188UqiHJ3a57V7RIbO3Os78yxvl1io1rUajNLbxCn20+Iwiqq/946OQLmpKpUEW6rclsdm4i0UQ3FEBphDIyGIq1obKt/O+T/hCZnz35egCetM/9yJtn79DtOvUY62WMwjNEa5+C7g0S700tutrrJe91+YsOpbPie2wx8e8M5+20wKYSCQM8YmmAbIqmBtYP9ctfRTO/9BVbHM/rp/9fy46uioH3PuJv9YfyFH73yeGYQBr0w8ppGtCFCQ4xuG9FNQTdjQbihKhvgb965s9mYm8uRSiWqwH7+W9UQRe39mt/Llz/zq47vNw9AFFlUdTUI/L8TkaZTczTwox3fi66pch2COyKxjkhbH3AxFRyPP/4wQWCIIscLL0znef3/1v4vRUnqWoLiw8sAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMDJUMDA6NDM6MjYrMDA6MDBTxkN1AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTAyVDAwOjQzOjI2KzAwOjAwIpv7yQAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNS0wNC0wMlQwMDo0NDozMSswMDowMJ5f/38AAAAASUVORK5CYII="),
            "enforcesSecureChat": JSONValue(false),
            "preventsChatReports": JSONValue(true),
        ]);
        JSONValue json = ct_jsonStatusTemplate;
        json["players"]["online"] = players.length;
        sendPacket(new packets.status.server.StatusResponsePacket(json));
    }

    private
    void sendRegistryData()
    in (m_state == State.config)
    {
        m_log.dbg!"minecraft:painting_variant";
        {
            auto registryDataPacket = new packets.config.server.RegistryDataPacket("minecraft:painting_variant");
            auto entryNbt = Nbt([
                "asset_id": Nbt("minecraft:alban"),
                "width": Nbt(int(1)),
                "height": Nbt(int(1)),
                "title": Nbt([
                  "color": Nbt("yellow"),
                  "translate": Nbt("painting.minecraft.alban.title"),
                ]),
                "author": Nbt([
                    "color": Nbt("gray"),
                    "translate": Nbt("painting.minecraft.alban.author"),
                ]),
            ]);
            registryDataPacket.addEntry("minecraft:alban", entryNbt);
            sendPacket(registryDataPacket);
        }
        m_log.dbg!"minecraft:wolf_variant";
        {
            auto registryDataPacket = new packets.config.server.RegistryDataPacket("minecraft:wolf_variant");
            auto entryNbt = Nbt([
                "wild_texture": Nbt("minecraft:entity/wolf/wolf_ashen"),
                "angry_texture": Nbt("minecraft:entity/wolf/wolf_ashen_angry"),
                "tame_texture": Nbt("minecraft:entity/wolf/wolf_ashen_tame"),
                "biomes": Nbt.emptyList,
            ]);
            registryDataPacket.addEntry("minecraft:ashen", entryNbt);
            sendPacket(registryDataPacket);
        }
        m_log.dbg!"minecraft:dimension_type";
        {
            auto registryDataPacket = new packets.config.server.RegistryDataPacket("minecraft:dimension_type");
            foreach (dimension; ["overworld", "the_nether", "the_end"])
            {
                auto entryNbt = Nbt([
                    "ultrawarm": Nbt(byte(0)),
                    "natural": Nbt(byte(0)),
                    "coordinate_scale": Nbt(double(1.0)),
                    "has_skylight": Nbt(byte(1)),
                    "has_ceiling": Nbt(byte(0)),
                    "ambient_light": Nbt(float(1.0)),
                    "fixed_time": Nbt(long(0)),
                    "monster_spawn_light_level": Nbt([
                        "type": Nbt("minecraft:constant"),
                        "value": Nbt(int(0)),
                    ]),
                    "monster_spawn_block_light_limit": Nbt(int(0)),
                    "piglin_safe": Nbt(byte(0)),
                    "bed_works": Nbt(byte(0)),
                    "respawn_anchor_works": Nbt(byte(0)),
                    "has_raids": Nbt(byte(0)),
                    "logical_height": Nbt(int(384)),
                    "min_y": Nbt(int(-64)),
                    "height": Nbt(int(384)),
                    "infiniburn": Nbt("#minecraft:infiniburn_overworld.json"),
                    "effects": Nbt("minecraft:overworld"),
                ]);
                registryDataPacket.addEntry("minecraft:" ~ dimension, entryNbt);
            }
            sendPacket(registryDataPacket);
        }
        m_log.dbg!"minecraft:damage_type";
        {
            auto registryDataPacket = new packets.config.server.RegistryDataPacket("minecraft:damage_type");
            foreach (damageType; ["arrow", "bad_respawn_point", "cactus", "campfire", "cramming", "dragon_breath", "drown", "dry_out", "ender_pearl", "explosion", "fall", "falling_anvil", "falling_block", "falling_stalactite", "fireball", "fireworks", "fly_into_wall", "freeze", "generic", "generic_kill", "hot_floor", "in_fire", "in_wall", "indirect_magic", "lava", "lightning_bolt", "mace_smash", "magic", "mob_attack", "mob_attack_no_aggro", "mob_projectile", "on_fire", "out_of_world", "outside_border", "player_attack", "player_explosion", "sonic_boom", "spit", "stalagmite", "starve", "sting", "sweet_berry_bush", "thorns", "thrown", "trident", "unattributed_fireball", "wind_charge", "wither", "wither_skull"])
            {
                auto entryNbt = Nbt([
                    "message_id": Nbt("generic"),
                    "exhaustion": Nbt(float(0.0)),
                    "scaling": Nbt("never"),
                ]);
                registryDataPacket.addEntry("minecraft:" ~ damageType, entryNbt);
            }
            sendPacket(registryDataPacket);
        }
        m_log.dbg!"minecraft:worldgen/biome";
        {
            auto registryDataPacket = new packets.config.server.RegistryDataPacket("minecraft:worldgen/biome");
            foreach (biome; ["void", "plains"])
            {
                auto entryNbt = Nbt([
                    "has_precipitation": Nbt(byte(1)),
                    "temperature": Nbt(float(0.8)),
                    "downfall": Nbt(float(0.4)),
                    "carvers": Nbt.emptyList,
                    "effects": Nbt([
                      "fog_color": Nbt(int(12_638_463)),
                      "sky_color": Nbt(int(7_907_327)),
                      "water_color": Nbt(int(4_159_204)),
                      "water_fog_color": Nbt(int(329_011)),
                    //   "music_volume": Nbt(float(1.0)),
                    ]),
                    "features": Nbt.emptyList,
                    "spawners": Nbt.emptyCompound,
                    // "spawners": Nbt([
                    //     "ambient": Nbt.emptyList,
                    //     "axolotls": Nbt.emptyList,
                    //     "creature": Nbt.emptyList,
                    //     "misc": Nbt.emptyList,
                    //     "monster": Nbt.emptyList,
                    //     "underground_water_creature": Nbt.emptyList,
                    //     "water_ambient": Nbt.emptyList,
                    //     "water_creature": Nbt.emptyList,
                    // ]),
                    "spawn_costs": Nbt.emptyCompound,
                ]);
                registryDataPacket.addEntry("minecraft:" ~ biome, entryNbt);
            }
            sendPacket(registryDataPacket);
        }
    }

    private
    void sendWorldTime()
    in (m_state == State.play)
    {
        sendPacket(new packets.play.server.UpdateTimePacket(0, 0, false));
    }

    private
    void sendAllChunks()
    in (m_state == State.play)
    {
        m_log.dbg!"Sending set center chunk";
        sendPacket(new packets.play.server.SetCenterChunkPacket(0, 0));

        m_log.dbg!"Sending chunk batch start";
        sendPacket(new packets.play.server.ChunkBatchStartPacket);

        m_log.dbg!"Sending chunk data";
        int chunksSent;
        foreach (int x; 0 .. 3)
            foreach (int z; 0 .. 3)
            {
                Nbt heightMaps = Nbt([
                    "MOTION_BLOCKING": Nbt(new long[](37)),
                    "WORLD_SURFACE": Nbt(new long[](37)),
                ]);
                const(SubChunk)[] subChunks;
                foreach (y; 0 .. 24)
                    subChunks ~= SubChunk.emptySubChunk;
                sendPacket(new packets.play.server.ChunkDataPacket(x, z, heightMaps, subChunks));
                chunksSent++;
            }
        m_log.dbg!"Sent %d chunks"(chunksSent);

        m_log.dbg!"Sending chunk batch finished";
        sendPacket(new packets.play.server.ChunkBatchFinishedPacket(chunksSent));
    }

    private
    void switchState(const State state)
    {
        m_state = state;
        m_log.dbg!"Switched to state %s"(m_state);
    }

    private
    void sendPacket(Packet)(const Packet packet)
    if (isServerPacket!Packet)
    {
        OutputStream output;
        output.writeVar!int(packet.ct_protocol);
        packet.serialize(output);

        OutputStream lengthPrefixedOutput;
        lengthPrefixedOutput.writeVar!int(output.data.length.to!int);
        lengthPrefixedOutput.writeBytes(output.data);

        // TODO: synchronize
        m_outgoingPacketQueue ~= lengthPrefixedOutput;
    }

    private
    void sendHexPacket(int protocol, string hexString)
    {
        OutputStream output;
        output.writeVar!int(protocol);
        output.writeBytes(cast(immutable(ubyte)[]) hexString);

        OutputStream lengthPrefixedOutput;
        lengthPrefixedOutput.writeVar!int(output.data.length.to!int);
        lengthPrefixedOutput.writeBytes(output.data);

        // TODO: synchronize
        m_outgoingPacketQueue ~= lengthPrefixedOutput;
    }
}