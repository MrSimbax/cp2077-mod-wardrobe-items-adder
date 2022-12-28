# Wardrobe Items Adder

Small utility mod for Cyberpunk 2077. Published also on [NexusMods](https://www.nexusmods.com/cyberpunk2077/mods/5742).

Add all or only specific clothes to the wardrobe without cluttering the inventory and without any other gameplay side effects.

## Why?

1. The script calls the wardrobe system directly which means your inventory isn't cluttered with clothing items and you don't get any new crafting recipes which some items automatically give, like you would by using `Game.AddToInventory(...)`.
2. Convenience. It's arguably easier and faster to install this mod and click a button than to find an updated list of items, use the aforementioned command, and then clearing out the inventory from excessive items.
3. It kind of removes "style" progression because you can look like an end-game character early (not that there is much difference), makes clothing rewards from quests less attractive, and gives even less motivation to check out clothing vendors (and potentially saves some eddies that would be used for buying clothes). But if you care more about style than these things then this mod is for you.

If you don't care about adding every cloth or don't want to install this mod, here's a CET console one-liner for adding an item to the wardrobe.

```plain
Game.GetWardrobeSystem():StoreUniqueItemIDAndMarkNew(ItemID.new(TweakDBID.new("ITEM_ID_HERE")))
```

## Features

* Ability to add all available clothes in the game to the wardrobe
  * The mod tries not to add false-positives (broken/duplicated items) by using a few filters (e.g. a blacklist)
* Ability to add only specific clothes by providing a list of item IDs or `Game.AddToInventory(...)` commands
* Simple UI in Cyber Engine Tweaks overlay
* Option to automatically add all clothes when player spawns

There are also advanced settings which are useful for debugging, for developing the mod, and if you want to change something about its behaviour without diving into the code (for example, disabling specific item filters).

## Limitations

* Although I think the mod was tested quite thoroughly at this point (patch 1.61), there's still a possibility of false-positives and therefore adding a broken item to your wardrobe, especially in future game updates if they add new (broken) clothes. False-negatives are also possible but they're less of an issue since it's far easier to add items than remove them. For those situations, you can use Advanced Settings to investigate and work around the issue, but please also report it so I can improve the mod by adding a new filter or modifying the default blacklist.
* **This mod cannot remove items from the wardrobe.** I haven't found a way to do that and start to think it's impossible, at least in the current patch. The database of clothes in the wardrobe is not easily accessible and the game only provides a function for adding new items. Therefore it is wise to check if there aren't any broken clothes in the wardrobe after using the mod, as the only way to go back to the original wardrobe state is by reloading the save. That said, modded items actually seem to disappear by themselves from the wardrobe after uninstalling them (not sure if they reappear after installing mods back).
* This mod's blacklist is not the same as the game's internal blacklist, and it does not give UI for changing the game's internal wardrobe blacklist, since it's already modifiable from the TweakDB Editor included with Cyber Engine Tweaks. For the interested, the record is `gamedataItemList_Record.Items.WardrobeBlacklist.items` (`<TDBID:957B8071:17>`). The game's internal blacklist can actually be ignored (see Advanced Settings) but keep in mind that it probably exists for a reason.

## Requirements

* Game version *>=1.6*
* [Cyber Engine Tweaks](https://www.nexusmods.com/cyberpunk2077/mods/107) *version working with with your game's version*

## Installation

1. Install the requirements listed above.
2. Download the archive with the mod.
3. Extract it to the Cyberpunk 2077 installation folder.

The final directory structure should be `{Cyberpunk 2077 installation folder}/bin/x64/plugins/cyber_engine_tweaks/mods/wardrobe_items_adder`, and this folder should contain `.lua` files.

## Basic Usage

1. Load a save.
2. Open the Cyber Engine Tweaks overlay/console.
3. The *"Wardrobe Items Adder"* window should appear.

![https://i.imgur.com/0hO68i2.png](https://i.imgur.com/0hO68i2.png)

Adding all clothes is as simple as clicking the button. Note, however, that this might result in adding broken clothes (read the limitations section above).

To add only specific clothes their IDs have to be provided, with or without the `Item.` prefix, one per line. There are several sources where one can find the IDs, for example the [wiki](https://cyberpunk.fandom.com/wiki/Cyberpunk_2077_Clothing) or the [spreadsheet](https://docs.google.com/spreadsheets/d/1iuq4Srh_661PdY_17bnrU15UbtCLieO_0ZhQ0uqQ0_Y/edit#gid=0), or a clothing mod description page. Specific commands like `Game.AddToInventory("Items.item_id", 1)` are often provided, so for convenience such commands can be copy-pasted directly into the text area and the script should be able to extract the item IDs by itself.

In the settings tab you can find an option to automatically add all clothes on player spawn. With this option you won't have to click the button manually after starting a new save or installing a new clothing mod.

![https://i.imgur.com/1VbMKw1.png](https://i.imgur.com/1VbMKw1.png)

The mod prints specific warnings/errors in the console, so **in case of issues please check the console window before reporting a bug**.

## Advanced Usage

### How the Mod Works

The script iterates through the game's internal TweakDB database records to find all the clothes. Unfortunately, this means there might be false-positives, but the mod is written to work around that.

Some obvious symptoms of broken items: they are invisible, or without an icon, or without description, or add the cyberpunky glitch effect to V, or otherwise seem to not be intended for gameplay use. The script tries to filter out such items e.g. by checking if the `displayName` property of an item is empty. This does mean it might filter out too many or too few, but it seems to be working well at least with vanilla clothes. There is an option in the advanced settings to enable/disable any specific filters, in case the need arises.

One may ask, why not just hardcode the list of clothes into the mod instead of trying to workaround the issue with random filters? Firstly, I don't like hardcoding things by principle. Secondly, the script may now automatically work with Archive XL mods adding new clothing items, which is very convenient. Thirdly, it might also work automatically on new versions of the game without any changes from my side, so that's less of maintenance burden on me. There's of course a risk of new broken clothes or any backwards-incompatible change, in which case the mod will have to be updated anyway, but I have no control over these things.

That said, there's some hardcoding, as the mod has its own (user-editable) blacklist. Do not mix it up with the built-in wardrobe's blacklist. It exists because some specific broken items still get through the more general filters, and there's basically no other easy automatic way to filter out duplicated items. Currently, the blacklist contains items which are not be obtainable in the game without cheating or mods anyway, at least as far as I'm aware, and the list is fairly short so it's a lot more manageable than whitelist.

### Advanced Settings

Checking the *"Show Advanced Settings"* option will show more settings to tinker with if you want/need to. They're most useful if something is not working as intended (or for me when I'm developing this mod), otherwise I do not recommend touching them.

In the advanced settings you can, for example, enable or disable item filters provided by the mod. The mod's blacklist can be edited in a separate tab. The amount of console logs can also be increased/reduced by changing the log level.

![https://i.imgur.com/jgQS2f7.png](https://i.imgur.com/jgQS2f7.png)

From version 1.2.0 it is possible to detect duplicated items, in case of future updates. To do that, turn on debug (all) logs and then add all clothes. The mod will print TweakDBIDs of items which were refused by the wardrobe system, meaning they have a duplicate. Right now it won't print anything because the duplicates are already on the default blacklist, but this functionality might come in handy after future updates. Unfortunately, the items will have to be verified by hand to choose which duplicate should be blacklisted.

## Uninstall

Delete the `{Cyberpunk 2077 installation folder}/bin/x64/plugins/cyber_engine_tweaks/mods/wardrobe_items_adder` directory.
