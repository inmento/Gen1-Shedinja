# Gen 1 Shedinja

**Gen 1 Shedinja** is a standalone, Gen 1-only Gen1Recomp mod that adds Shedinja as Pokédex species **#152**. Version 0.1.2 provides normal Kanto wild encounters, transparent battle sprites, and a scoped Wonder Guard mechanic while keeping the rest of the base game intact.

## Included in 0.1.2

| Feature | Behavior |
|---|---|
| Species | `SHEDINJA`, Pokédex #152, species index 152 |
| Typing | Bug/Ghost |
| Base HP | 1 |
| Battle art | Transparent front and back battle sprites |
| Wonder Guard | A persistent `WONDER GUARD` Bag item is restored on game startup/load if it is missing. |
| Damage rule | The item blocks non-super-effective direct move damage only for the player’s active Shedinja. Super-effective damage remains unchanged. |

The mod uses the engine’s normal Gen 1 type-effectiveness calculation. As Shedinja is Bug/Ghost, any move the engine considers **super-effective against that dual type** can damage it. Wonder Guard does not protect other Pokémon, an opposing Shedinja, or typeless self-damage such as confusion damage.

## Wild encounter locations

The mod transforms only a small percentage of otherwise valid native wild encounters. It does not change map encounter rates, non-Shedinja encounter slots, fishing, or water encounters.

| Location | Encounter path | Chance | Level range |
|---|---|---:|---:|
| Route 1 | Grass | 5% | 3–5 |
| Route 4 | Grass | 7% | 10–12 |
| Victory Road 1F, 2F, and 3F | Cave / indoor | 10% | 36–38 |

## Compatibility

This mod is designed to coexist with the user’s non-dex gameplay mods, including Starter Picker, Item Randomizer, Gym Leader Shuffle, Randomized Gym Challenge, and Sound Effect Replacer. For example, the non-tossable `WONDER GUARD` token is excluded from Item Randomizer’s safe random-item pools, and Gym-related mods do not overwrite the species registry or the Wonder Guard damage seam.

> **Required exception:** Gym Leader Shuffle and Randomized Gym Challenge are mutually exclusive with each other because both alter the same gym scripts, trainer parties, leaders, and map/NPC state. Each remains compatible with Gen 1 Shedinja and the rest of the non-conflicting suite.

## Important Pokédex-expansion rule

This is a **standalone species expansion**. Do **not** enable it with Crystal 251, Kanto Reforged, or any other mod that changes the Pokémon roster, Pokédex, dex data, or species indices.

Crystal 251 specifically owns Pokédex/index **#152** for Chikorita. This mod must retain Shedinja at the user-required #152 index, so those two data providers cannot safely coexist. The manifest blocks the known incompatible expansion mods, but it cannot anticipate every future dex expansion.

| Supported game | Status |
|---|---|
| Pokémon Red / Blue / Yellow | Supported |
| Pokémon Gold / Gen 2 | Not supported |
| Crystal 251 and same-slot roster expansions | Incompatible |

## Suggested test checklist

First confirm that the mod loads and that `WONDER GUARD` appears in the Bag. On Route 1, Route 4, and Victory Road, verify that Shedinja can appear at the stated approximate rarity and level range while native wild encounters still occur.

Then check Shedinja’s name, #152 Pokédex identity, Bug/Ghost typing, front sprite, back sprite, HP behavior, and one save/continue cycle. For Wonder Guard, test a neutral damaging move, a resisted damaging move, a super-effective damaging move, a status move, and confusion self-damage. Only direct damaging moves that are not super-effective should be blocked. Test in both wild and trainer battles.

## Artwork attribution and license

The included front and back battle sprites are adaptations of **“G1SP 0292 – Shedinja”** by **BouncingPiplup**. The artist notes that the source artwork was influenced by SharkGuy’s version, with personal adjustments.

The modifications for this mod remove the background, prepare transparent PNGs, and resize/crop them for the 56×56 front and 48×48 Gen1Recomp battle-sprite targets. The adapted sprite files in `assets/sprites/` are released under [Creative Commons Attribution-ShareAlike 3.0 Unported](https://creativecommons.org/licenses/by-sa/3.0/). Attribution, the license link, and an indication of any further changes must be retained when those assets are shared or adapted. This credit does not imply artist endorsement of the mod.

See [CREDITS.md](CREDITS.md) for the complete attribution record and original source link.

## Scope and status

This is a public **0.1.2 test release**. Please report reproducible loading, save, rendering, encounter, and battle-behavior results before further species or progression mechanics are added.
