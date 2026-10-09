# Social Distancing

Social Distancing is a World of Warcraft addon that displays spell-range checks
for your target and focus, and range estimates for members of your party. It
also highlights party healers who are out of range.

## Features

- Check whether your target and focus are in range of a selected hostile or
  friendly spell.
- Estimate party-member distance outdoors when unit positions are available.
- Select a healing-range preset per party member or synchronize one preset
  across the party.
- Optionally play an alert when a tracked unit changes from in range to out of
  range.
- Mark out-of-range healers when inspect data is available.
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
- Left-click the minimap icon to toggle the overlay. Closing the overlay also
  disables it until you open it again or re-enable it in settings.
- Right-click the minimap icon to open settings.
- In settings, select range spells for hostile and friendly targets/focuses.
  Party range presets can be assigned to an individual member or synchronized
  across the party. Enable an **Alert** checkbox to hear a sound when that
  tracked range changes from in range to out of range.
- Enable **Only show overlay while grouped** to hide the range overlay while
  solo. This setting also applies in raids.
- Drag the overlay by its title bar to reposition it.

## Range-check notes

- Spell checks depend on the range information exposed by the game client and
  may report an unknown result.
- Party-member distance is only available when the game provides unit positions,
  typically outdoors.
- Party range presets are healing spells selected for the classes in your
  current party. Specialization labels depend on inspect data being available.
- Party-member distances are not listed while in a raid.

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
