# Shedinja for Gen1Recomp

**Shedinja** is a standalone Gen1Recomp species expansion for **Pokémon Red, Blue, Yellow, and Gold**. It adds Shedinja as **National Dex #292** with Bug/Ghost typing, base HP 1, generation-appropriate wild encounters, and a deliberately scoped Wonder Guard implementation. Version **0.2.0** uses the consistent package ID **`shedninja`** and provides optional bridge paths for Crystal 251 in R/B/Y and Expanded Species in Gold, while preserving standalone behavior in every supported game.

## Version 0.2.0 at a glance

| Game | Internal species slot | National Dex number | Battle art | Wonder Guard model |
|---|---:|---:|---|---|
| Red / Blue / Yellow | 152 standalone; 252 with active Crystal 251 | 292 | Transparent Gen 1-style front and back sprites | Persistent Bag token; protects the player’s active Shedinja while the token is in the Bag. |
| Gold | 252 | 292 | Credited Crystal-style three-frame front animation, static back sprite, normal palette, and shiny palette | Equipable held item; protects the player’s active Shedinja only while it holds `WONDER GUARD`. |

> **Important:** Gold’s `WONDER GUARD` is a normal non-usable Bag item so that Gold’s native **GIVE** action can equip it. The item may therefore be taken or discarded normally. It is granted again only when it is missing from the Bag on a later startup or load.

## Core behavior

Shedinja is Bug/Ghost with base stats of HP 1, Attack 90, Defense 45, Speed 40, Special Attack 30, and Special Defense 30 in Gold. Gold uses the Erratic experience curve, an `EGG_MINERAL` breeding group, and the following level-up moves: Scratch, Harden, Leech Life, Sand Attack, Fury Swipes, Mind Reader, Spite, Confuse Ray, Shadow Ball, and Grudge.

Wonder Guard uses the game’s normal type-effectiveness result. It blocks only direct, non-super-effective move damage and only for the **player’s active Shedinja**. It does not protect an opposing Shedinja, another species, an inactive party member, or typeless self-damage such as confusion. In Gold, the protection additionally requires Shedinja to be holding the `WONDER GUARD` item.

Gen 1 preserves Shedinja’s isolated recreation of unused Gen 1 cry `$43`: base cry `0`, pitch `128`, and length `16`. The cry is species-scoped and does not change Nidoran♂ or any global cry data.

## Wild encounter locations

The mod locally transforms only a small percentage of valid native land encounters. It does not replace native encounter rates, non-Shedinja slots, fishing, or water encounters.

| Game | Location | Encounter path | Chance | Level range |
|---|---|---|---:|---:|
| Red / Blue / Yellow | Route 1 | Grass | 5% | 3–5 |
| Red / Blue / Yellow | Route 4 | Grass | 7% | 10–12 |
| Red / Blue / Yellow | Victory Road 1F, 2F, and 3F | Cave / indoor | 10% | 36–38 |
| Gold | Route 29 | Land | 5% | 3–5 |
| Gold | Route 34 | Land | 7% | 10–12 |
| Gold | Victory Road | Land / cave | 10% | 36–38 |

## Gold sprite, shiny, and Pokédex support

Gold’s front sprite plays the three supplied Crystal animation frames once when Shedinja appears in battle, using the original 6/32/10-tick timing and then holding the final frame. Its back sprite remains static, matching the supplied Crystal source data. The art is stored as four palette-indexed grayscale shades; Gen1Recomp automatically selects the included normal or shiny palette from the Pokémon’s actual shiny state.

Gold also inserts a Shedinja entry into its `gen2Pokedex` data at game-ready time, allowing National Dex #292, height, weight, and a correctly fitted two-page entry to appear without replacing a native species entry.

## Installation and package migration

Install the current `shedninja-0.2.0.zip` release through your index or from GitHub Releases. The retired releases used the manifest ID `gen1_shedinja`; because Gen1Recomp treats the renamed `shedninja` package as a distinct mod, remove the old `gen1_shedinja` install and then install `shedninja` once. Future releases will update normally through the launcher.

## Compatibility

This mod is designed to coexist with the user’s non-roster gameplay mods, including Starter Picker, Item Randomizer, Gym Leader Shuffle, Randomized Gym Challenge, and Sound Effect Replacer. It is standalone: none of those mods is required for Shedinja to load, appear, receive Wonder Guard, or display its Dex content.

> **Roster-expansion guidance:** Crystal 251 is supported in Red, Blue, and Yellow with core Shedinja 0.2.0+ and the separate [Shedinja Crystal 251 Bridge](https://github.com/inmento/Shedinja-Crystal-251-Bridge/releases). The bridge moves Shedinja to internal index `252`, retains National Dex #292, and supplies Crystal-specific split-stat metadata. In Gold, use the separate [Shedinja Expanded Bridge](https://github.com/inmento/Shedinja-Expanded-Bridge/releases) only with Expanded Species. **Kanto Reforged** and unrelated roster/Dex/index-overhaul mods remain unsupported unless they provide their own dedicated compatibility bridge.

Gym Leader Shuffle and Randomized Gym Challenge remain mutually exclusive with each other because they edit the same gym content, but either may be used with Shedinja when enabled alone.

## Suggested test checklist

Confirm that the mod boots, Shedinja appears at the stated locations, and native encounters still occur. Check its name, National Dex #292 presentation, Bug/Ghost typing, base HP, sprite art, and one save/continue cycle in each supported game.

For Gen 1, confirm that `WONDER GUARD` appears in the Bag and test neutral, resisted, super-effective, status, and confusion damage in wild and trainer battles. For Gold, give `WONDER GUARD` to Shedinja through the Bag’s **GIVE** action, then repeat those battle checks both before and after taking the item away. Also check normal and shiny art if a shiny Shedinja is available, the one-pass front animation, the static back art, and the two-page Gold Pokédex entry.

## Artwork attribution and licenses

The Gen 1 front and back sprites are adaptations of **“G1SP 0292 – Shedinja”** by **BouncingPiplup**, distributed under [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/). The Gen 2 front animation and back sprite are adapted from **“GSC Shedinja”** by **nuukiie** (Nuuk), used and edited for non-commercial purposes with credit under the artist’s stated terms.

See [CREDITS.md](CREDITS.md) for the complete source links, attribution details, and the modifications made to both asset sets. Neither artist’s credit implies endorsement of this mod.

## Scope and status

This is a public **0.2.0** release. Please report reproducible loading, save, rendering, compatibility-bridge, encounter, Pokédex, and battle-behavior results before further species or progression mechanics are added.
