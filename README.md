# SerialWarcraft

Minimal World of Warcraft: Forever addon. The minimap button invites a community character or toggles group loot, and glows while that character is online and not in the group. Defaults are the SerialWarcraft community and Ailene Wuornoz. Dragging the button saves its angle.

## Client

- Game: World of Warcraft: Forever (Camelot)
- Interface: 16001 (client 1.60.1)
- TOC: `SerialWarcraft_Forever.toc`

## Install

The repository root is the addon. Clone or copy it to:

`World of Warcraft/_forever_/Interface/AddOns/SerialWarcraft`

## Minimap

The button starts on the upper-left edge of the minimap, at 10 o'clock. Drag it around the minimap edge to move it.

Right-click shows or hides the settings panel. It shows the addon name, and edits the community name, character name, glow texture, glow size, and glow opacity. Those values are saved and apply immediately. Escape or the panel close button hides the panel.

Left-click invites the saved character when they are not in your group. When they are in the group, the group leader toggles loot between group loot and free for all. The button glows while that character is online and not in the group.

## Slash commands

- `/swc`
- `/serialwarcraft`

Either command prints a one-line loaded message.
