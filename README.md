# Gen 1 Shedinja

**Gen 1 Shedinja** is a standalone, Gen 1-only Gen1Recomp test mod that adds Shedinja as Pokédex species **#152**. It is an early public release intended to validate a species expansion, battle sprites, and a scoped Wonder Guard mechanic before encounter placement or other progression changes are considered.

## Included in 0.1.0

| Feature | Behavior |
|---|---|
| Species | `SHEDINJA`, Pokédex #152, species index 152 |
| Typing | Bug/Ghost |
| Base HP | 1 |
| Battle art | Transparent front and back battle sprites |
| Wonder Guard | A persistent `WONDER GUARD` Bag item is restored on game startup/load if it is missing. |
| Damage rule | The item blocks non-super-effective direct move damage only for the player’s active Shedinja. Super-effective damage remains unchanged. |

The mod uses the engine’s normal Gen 1 type-effectiveness calculation. As Shedinja is Bug/Ghost, any move the engine considers **super-effective against that dual type** can damage it. Wonder Guard does not protect other Pokémon, an opposing Shedinja, or typeless self-damage such as confusion damage.

## Important compatibility rule

This is a **standalone species expansion**. Do **not** enable it with Crystal 251, Kanto Reforged, or any other mod that changes the Pokémon roster, Pokédex, dex data, or species indices. The manifest blocks the known incompatible expansion mods, but it cannot anticipate every future dex expansion.

| Supported game | Status |
|---|---|
| Pokémon Red / Blue / Yellow | Intended test target |
| Pokémon Gold / Gen 2 | Not supported |
| Crystal 251 and other roster expansions | Incompatible |

## Getting Shedinja into a party

This first release intentionally does **not** change wild encounters, starters, gifts, maps, or story scripts. Add `SHEDINJA` through a compatible party/content editing tool while testing. Future encounter placement should be decided only after the species data, sprites, and Wonder Guard behavior are confirmed stable.

## Suggested test checklist

First confirm that the mod loads and that `WONDER GUARD` appears in the Bag. Then add Shedinja to the party and verify its name, #152 Pokédex identity, Bug/Ghost typing, front sprite, back sprite, HP behavior, and one save/continue cycle.

For Wonder Guard, test a neutral damaging move, a resisted damaging move, a super-effective damaging move, a status move, and confusion self-damage. Only direct damaging moves that are not super-effective should be blocked. Test in both wild and trainer battles.

## Artwork attribution and license

The included front and back battle sprites are adaptations of **“G1SP 0292 – Shedinja”** by **BouncingPiplup**. The artist notes that the source artwork was influenced by SharkGuy’s version, with personal adjustments.

The modifications for this mod remove the background, prepare transparent PNGs, and resize/crop them for the 56×56 front and 48×48 Gen1Recomp battle-sprite targets. The adapted sprite files in `assets/sprites/` are released under [Creative Commons Attribution-ShareAlike 3.0 Unported](https://creativecommons.org/licenses/by-sa/3.0/). Attribution, the license link, and an indication of any further changes must be retained when those assets are shared or adapted. This credit does not imply artist endorsement of the mod.

See [CREDITS.md](CREDITS.md) for the complete attribution record and original source link.

## Scope and status

This is a public **0.1.0 test release**, not a completed content mod. Please report reproducible loading, save, rendering, party-editing, and battle-behavior results before additional mechanics are added.
