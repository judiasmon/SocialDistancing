# Social Distancing

Social Distancing is a World of Warcraft addon that displays spell-range checks
for your target and focus, and range estimates for members of your party. It
also highlights party healers who are out of range.

## Features

- Check whether your target and focus are in range of a selected hostile or
  friendly spell.
- Estimate party-member distance outdoors and use the game's 40-yard range
  check indoors when available.
- Select a healing-range preset per party member or synchronize one preset
  across the party.
- Optionally play an alert when a tracked unit changes from in range to out of
  range.
- Identify party specializations, including healer roles, when inspect data is
  available.
- Keep the range overlay movable and toggle it from the minimap icon or slash
  command.

## Installation

1. Copy the `SocialDistancing` folder into your World of Warcraft
   `_retail_/Interface/AddOns/` directory (or the equivalent AddOns directory
   for your game client).
2. Ensure `SocialDistancing.toc` is directly inside the `SocialDistancing`
   folder.
3. Enable **Social Distancing** from the AddOns list, then reload the UI or
   log in.

The addon includes the libraries it uses; no separate library installation is
needed.

## Using the addon

- Enter `/sd` or `/socialdistancing` to show or hide the range overlay.
- Left-click the minimap icon to toggle the overlay.
- Right-click the minimap icon to open settings.
- In settings, select range spells for hostile and friendly targets/focuses.
  Party range presets can be assigned to an individual member or synchronized
  across the party. Enable an **Alert** checkbox to hear a sound when that
  tracked range changes from in range to out of range.
- Drag the overlay by its title bar to reposition it.

## Range-check notes

- Spell checks depend on the range information exposed by the game client and
  may report an unknown result.
- Exact party distances are available outdoors when the game provides unit
  positions. Indoors, the game's 40-yard check is used where supported; other
  distances may be unavailable.
- Party range presets are healing spells selected for the classes in your
  current party. Specialization labels depend on inspect data being available.
- Party yard checks are not shown while in a raid.

## Files

- `Core.lua` initializes saved settings and shared range-spell data.
- `SocialDistancing.lua` updates and displays target, focus, and party ranges.
- `Settings.lua` builds the settings panel.
- `Minimap.lua` registers the minimap button.
- `SocialDistancing.toc` declares addon metadata, libraries, and module load
  order.

## License

This project is distributed under the BSD 2-Clause License. See [LICENSE](LICENSE)
for the full terms.
