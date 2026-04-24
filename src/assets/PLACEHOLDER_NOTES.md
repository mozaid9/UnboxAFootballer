# Asset Placeholders — Phase 1

All asset IDs in the code are set to `rbxassetid://0` (invisible).
Replace these once you have real assets uploaded to Roblox.

## Sounds (add to SoundService or individual parts)
| Sound             | Where to use                        | Suggested search term on Roblox     |
|-------------------|-------------------------------------|-------------------------------------|
| Card flip         | Each card reveal (flip animation)   | "card flip" / "paper swoosh"        |
| Rare pull         | When a Rare Gold card flips open    | "golden fanfare" / "rare item"      |
| Fans received     | When fans are added (sell/reward)   | "crowd cheer" / "cha-ching"         |
| Pack open         | When the reveal screen appears      | "pack rip" / "envelope open"        |
| Button click      | All button presses                  | "UI click" / "button press"         |

## Card art
Cards currently show text only (name, rating, position, nation).
To add art: upload player images to Roblox, note the asset ID, and add an
ImageLabel inside the card's Front frame positioned in the upper half.

## Pack images
PackConfig.lua has an `iconId` field on each pack definition.
Upload pack artwork and paste the asset ID there.

## Nation flags
Each card has a `nation` string. You can map nations to flag decals
uploaded to Roblox and show them as small ImageLabels on the card face.
