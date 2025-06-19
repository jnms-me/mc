module mc.protocol.packet.play.client;

public import mc.protocol.packet.play.client.client_tick_end : ClientTickEndPacket;
public import mc.protocol.packet.play.client.keep_alive : KeepAlivePacket;
public import mc.protocol.packet.play.client.player_command : PlayerCommandPacket;
public import mc.protocol.packet.play.client.player_input : PlayerInputPacket;
public import mc.protocol.packet.play.client.set_player_position : SetPlayerPositionPacket;
public import mc.protocol.packet.play.client.set_player_position_rotation : SetPlayerPositionRotationPacket;
public import mc.protocol.packet.play.client.set_player_rotation : SetPlayerRotationPacket;
public import mc.protocol.packet.play.client.use_item_on : UseItemOnPacket;

@safe:

enum Protocol : int
{
                                     confirmTeleportation        = 0x00,
                                     queryBlockEntityTag         = 0x01,
                                     bundleItemSelected          = 0x02,
                                     changeDifficulty            = 0x03,
                                     acknowledgeMessage          = 0x04,
                                     chatCommand                 = 0x05,
                                     signedChatCommand           = 0x06,
                                     chatMessage                 = 0x07,
                                     playerSession               = 0x08,
                                     chunkBatchReceived          = 0x09,
                                     clientStatus                = 0x0A,
    @ClientTickEndPacket             clientTickEnd               = 0x0B,
                                     clientInformation           = 0x0C,
                                     commandSuggestionsRequest   = 0x0D,
                                     acknowledgeConfiguration    = 0x0E,
                                     clickContainerButton        = 0x0F,
                                     clickContainer              = 0x10,
                                     closeContainer              = 0x11,
                                     changeContainerSlotState    = 0x12,
                                     cookieResponse              = 0x13,
                                     serverboundPluginMessage    = 0x14,
                                     debugSampleSubscription     = 0x15,
                                     editBook                    = 0x16,
                                     queryEntityTag              = 0x17,
                                     interact                    = 0x18,
                                     jigsawGenerate              = 0x19,
    @KeepAlivePacket                 keepAlive                   = 0x1A,
                                     lockDifficulty              = 0x1B,
    @SetPlayerPositionPacket         setPlayerPosition           = 0x1C,
    @SetPlayerPositionRotationPacket setPlayerPositionRotation   = 0x1D,
    @SetPlayerRotationPacket         setPlayerRotation           = 0x1E,
                                     setPlayerMovementFlags      = 0x1F,
                                     moveVehicle                 = 0x20,
                                     paddleBoat                  = 0x21,
                                     pickItemFromBlock           = 0x22,
                                     pickItemFromEntity          = 0x23,
                                     pingRequest                 = 0x24,
                                     placeRecipe                 = 0x25,
                                     playerAbilities             = 0x26,
                                     playerAction                = 0x27,
    @PlayerCommandPacket             playerCommand               = 0x28,
    @PlayerInputPacket               playerInput                 = 0x29,
                                     playerLoaded                = 0x2A,
                                     pong                        = 0x2B,
                                     changeRecipeBookSettings    = 0x2C,
                                     setSeenRecipe               = 0x2D,
                                     renameItem                  = 0x2E,
                                     resourcePackResponse        = 0x2F,
                                     seenAdvancements            = 0x30,
                                     selectTrade                 = 0x31,
                                     setBeaconEffect             = 0x32,
                                     setHeldItem                 = 0x33,
                                     programCommandBlock         = 0x34,
                                     programCommandBlockMinecart = 0x35,
                                     setCreativeModeSlot         = 0x36,
                                     programJigsawBlock          = 0x37,
                                     programStructureBlock       = 0x38,
                                     updateSign                  = 0x39,
                                     swingArm                    = 0x3A,
                                     teleportToEntity            = 0x3B,
    @UseItemOnPacket                 useItemOn                   = 0x3C,
                                     useItem                     = 0x3D,
}
