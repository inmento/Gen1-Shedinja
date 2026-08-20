# Shedinja for Gen1Recomp

**Shedinja** is a standalone Gen1Recomp species expansion for **Pokémon Red, Blue, Yellow, and Gold**. It adds Shedinja as **National Dex #292** with Bug/Ghost typing, strict one-HP behavior across every lifecycle path, generation-appropriate wild encounters, a deliberately scoped Wonder Guard implementation, and two optional temporary battle mechanics for the player’s active Shedinja. Version **0.3.3** uses the consistent package ID **`shedinja`** and provides one optional compatibility bridge for Crystal 251 in R/B/Y or Expanded Species in Gold, while preserving standalone behavior in every supported game.

## Version 0.3.3 Potato Voxel orientation compatibility

Potato Voxel’s staged 3D renderer mirrors the player Pokémon card after its own battle hook requests front art for the player side. Shedinja now detects that exact downstream staged-battle path. It keeps the normal credited back sprite in ordinary battles, but supplies a mechanically pre-mirrored copy only for Potato Voxel’s staged player card; Potato Voxel’s own mirror then restores the credited back art in the correct orientation. Oak, Pokédex, summary, and other portrait contexts remain front-facing, and other species are unaffected.

## Version 0.3.2 corrective update

Gen 1 wild Shedinja is now normalized to exactly 1 current HP and 1 maximum HP inside the wild-battle factory, before its first opponent HUD and sprite are created. This also ensures a caught wild Shedinja begins life with the correct HP record. Shedinja’s unique post-level-up repair then resets its current and maximum HP to 1 after every ordinary stat recalculation, while leaving every other species unchanged.

The Gen 1 opponent/wild front art now uses a Shedinja-only 0.6× battle scale so the tightly framed credited 56×56 artwork fits the normal opponent slot. The player back remains at its intended 1× scale. The Gen 1 party/PC/selection icon is now registered directly to Shedinja’s species ID, repairing the blank PKMN-screen image.

## Version 0.3.1 corrective update

This release repairs the API 2 core export that the compatibility bridge verifies at boot and removes the core’s unnecessary reverse bridge ordering edge. The bridge remains optional, but when installed it now receives the active core’s published `SHEDINJA` handle in both generations.

For Red, Blue, and Yellow, Shedinja’s player-side battle art now explicitly uses the back sprite at normal one-times scale instead of the engine’s default doubled back-picture scale. Front-facing Oak, Pokédex, and summary callers are explicitly pinned to the front sprite. Any scripted Shedinja gift, including a Starter Picker Oak gift, immediately grants `WONDER_GUARD`, `ELEC TERA ORB`, and `AIR BALLOON` before control returns to the player.

Shedinja now also receives mandatory Gen 1 HP normalization. A living Shedinja is stored and battled at exactly **1 current HP and 1 maximum HP**; a fainted Shedinja remains at 0 current HP with a maximum of 1. The repair runs on save load, scripted gifts, battle start, replacement, battle end, and level-up handling.

## Version 0.3.1 at a glance

| Game | Internal species slot | National Dex number | Battle art | Wonder Guard model |
|---|---:|---:|---|---|
| Red / Blue / Yellow | 152 standalone; 252 with active Crystal 251 | 292 | Transparent Gen 1-style front and back sprites | The Bag token activates Wonder Guard for every active Shedinja on either side of battle. |
| Gold | 252 | 292 | Credited Crystal-style three-frame front animation, static back sprite, normal palette, and shiny palette | Enemy Shedinja receives the species behavior intrinsically; the player’s active Shedinja needs to hold `WONDER_GUARD`. |

Both games also grant `ELEC TERA ORB` and `AIR BALLOON` as permanent battle-only options for the player’s active Shedinja. They do not grant Wonder Guard by themselves in Gold.

> **Important:** Gold’s `WONDER_GUARD` is a normal non-usable Bag item so that Gold’s native **GIVE** action can equip it. It is no longer granted at boot. After the Mystery Egg return, Elm’s assistant gives the native five Poké Balls and then a level-5 Shedinja already holding the item.

## Core behavior

Shedinja is Bug/Ghost with base stats of HP 1, Attack 90, Defense 45, Speed 40, Special Attack 30, and Special Defense 30 in Gold. Gold uses the Erratic experience curve, an `EGG_MINERAL` breeding group, and the following level-up moves: Scratch, Harden, Leech Life, Sand Attack, Fury Swipes, Mind Reader, Spite, Confuse Ray, Shadow Ball, and Grudge.

Wonder Guard uses the game’s normal type-effectiveness result and blocks direct, non-super-effective move damage. In Red, Blue, and Yellow, the persistent `WONDER_GUARD` Bag token activates it for **every active Shedinja**, including the player’s, wild Shedinja, and trainer-owned Shedinja. In Gold, enemy Shedinja receives the ordinary-damage protection intrinsically, while the player’s active Shedinja additionally requires the actual held `WONDER_GUARD` item. In both games it never protects another species, an inactive party member, or typeless self-damage such as confusion.

Gen 1 preserves Shedinja’s isolated recreation of unused Gen 1 cry `$43`: base cry `0`, pitch `128`, and length `16`. The cry is species-scoped and does not change Nidoran♂ or any global cry data.

## Electric Tera Orb and Air Balloon

`ELEC TERA ORB` and `AIR BALLOON` are permanent, non-tossable items automatically added to every save and restored if missing on a later load. In Red, Blue, and Yellow they are Bag items; in Gold they are Key Items. They can be selected only during battle and only while the player’s active Pokémon is Shedinja. A successful activation is free: it returns to the battle command menu without consuming the turn, so the player can activate one or both items and then choose a normal action.

The Orb temporarily applies **Electric** as the active player Shedinja’s defensive type. The Balloon causes Ground-type moves to miss before they deal damage. Each item can activate once per time that Shedinja is on the field. Both effects clear on switch-out, forced replacement, faint-driven replacement, and battle end; switching the same Shedinja back in permits a new activation. Enemy, wild, benched, and boxed Shedinja never receive either effect.

> **Gold boundary:** The Orb changes the defensive typing used by the player’s existing held-item Wonder Guard. It does **not** bypass the requirement that the player’s active Shedinja hold `WONDER_GUARD`, and it does not activate Gold’s conditional wild encounter routes. Gold’s enemy Shedinja behavior remains intrinsic and separate.

Indirect and typeless damage remains dangerous. Poison, Toxic, burn, Leech Seed, and confusion self-damage still matter in Gen 1; Gold additionally retains its own indirect counterplay, including Sandstorm and Spikes.

## Wild encounter locations

The mod locally transforms only a small percentage of valid native land encounters. It does not replace native encounter rates, non-Shedinja slots, fishing, or water encounters. In Gold, the listed Shedinja replacements are active only while at least one owned Shedinja—either in the party or in a PC box—is holding `WONDER_GUARD`.

| Game | Location | Encounter path | Chance | Level range |
|---|---|---|---:|---:|
| Red / Blue / Yellow | Route 1 | Grass | 5% | 3–5 |
| Red / Blue / Yellow | Route 4 | Grass | 7% | 10–12 |
| Red / Blue / Yellow | Victory Road 1F, 2F, and 3F | Cave / indoor | 10% | 36–38 |
| Gold | Route 29 | Land | 5% | 3–5 |
| Gold | Route 34 | Land | 7% | 10–12 |
| Gold | Victory Road | Land / cave | 10% | 36–38 |

## Gold rift reward and encounter progression

After the player returns the Mystery Egg to Professor Elm, the assistant’s normal five Poké Ball reward is left intact. Once that native reward completes, the assistant explains that a rift opened while Elm was dealing with the robbery and gives a level-5 Shedinja already holding `WONDER_GUARD`.

Gold’s wild Shedinja replacements are deliberately tied to that held item. The route gate is on only while a Shedinja in the party or any PC box is holding it. Taking the item away from every owned Shedinja restores the normal encounter tables immediately; giving the item to a non-Shedinja does not activate the routes. Already-caught Shedinja are never removed.

## Gold sprite, shiny, and Pokédex support

Gold’s front sprite plays the three supplied Crystal animation frames once when Shedinja appears in battle, using the original 6/32/10-tick timing and then holding the final frame. Its back sprite remains static, matching the supplied Crystal source data. The art is stored as four palette-indexed grayscale shades; Gen1Recomp automatically selects the included normal or shiny palette from the Pokémon’s actual shiny state.

Gold also inserts a Shedinja entry into its `gen2Pokedex` data at game-ready time, allowing National Dex #292, height, weight, and a correctly fitted two-page entry to appear without replacing a native species entry.

## Installation and package migration

Install the current `shedinja-0.3.3.zip` release through your index or from GitHub Releases. The retired package identity was the misspelled `shedninja`; because Gen1Recomp treats the corrected `shedinja` package as a distinct mod, remove the old `shedninja` install and then install `shedinja` once. Future releases update normally through the launcher.

## Compatibility

This mod is designed to coexist with the user’s non-roster gameplay mods, including Starter Picker, Item Randomizer, Gym Leader Shuffle, Randomized Gym Challenge, and Sound Effect Replacer. It is standalone: none of those mods is required for Shedinja to load, appear, receive Wonder Guard, or display its Dex content.

> **Roster-expansion guidance:** Use the single [Shedinja Compatibility Bridge](https://github.com/inmento/Shedinja-Expanded-Bridge/releases) with core Shedinja 0.3.0+ when either supported framework is active. In Red, Blue, or Yellow with Crystal 251, it moves Shedinja to internal index `252`, retains National Dex #292, and supplies Crystal split-stat metadata. In Gold with Expanded Species, it preserves Shedinja’s framework-aware #292 identity and presentation. **Kanto Reforged** and unrelated roster/Dex/index-overhaul mods remain unsupported unless they provide their own dedicated compatibility bridge.

Gym Leader Shuffle and Randomized Gym Challenge remain mutually exclusive with each other because they edit the same gym content, but either may be used with Shedinja when enabled alone.

## Suggested test checklist

Confirm that the mod boots, Shedinja appears at the stated locations, and native encounters still occur. Check its name, National Dex #292 presentation, Bug/Ghost typing, base HP, sprite art, and one save/continue cycle in each supported game.

For Gen 1, confirm that `WONDER_GUARD`, `ELEC TERA ORB`, and `AIR BALLOON` appear in the Bag. With player Shedinja active, activate the Orb, Balloon, and both in either order; confirm no activation consumes the turn, duplicate use refuses, Ground moves miss while the Balloon is active, and both temporary effects clear after switching out and return only when reactivated. Test neutral, resisted, super-effective, status, fixed-damage, and confusion damage against both player and enemy Shedinja.

For Gold, confirm the two new items appear in Key Items while `WONDER_GUARD` remains a normal Bag item. Return the Mystery Egg to Elm, confirm the assistant’s native five Poké Balls are retained, then confirm the rift scene gives a level-5 Shedinja holding `WONDER_GUARD`. Test the Orb and Balloon on that active held-item Shedinja, then repeat after taking `WONDER_GUARD` away to confirm the Orb does not bypass the held-item rule. Move `WONDER_GUARD` between a party Shedinja, a boxed Shedinja, and another species to verify the Route 29, Route 34, and Victory Road encounter gate responds immediately. Also check normal and shiny art if a shiny Shedinja is available, the one-pass front animation, the static back art, and the two-page Gold Pokédex entry.

## Artwork attribution and licenses

The Gen 1 front and back sprites are adaptations of **“G1SP 0292 – Shedinja”** by **BouncingPiplup**, distributed under [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/). The Gen 2 front animation and back sprite are adapted from **“GSC Shedinja”** by **nuukiie** (Nuuk), used and edited for non-commercial purposes with credit under the artist’s stated terms.

See [CREDITS.md](CREDITS.md) for the complete source links, attribution details, and the modifications made to both asset sets. Neither artist’s credit implies endorsement of this mod.

## Scope and status

This is a public **0.3.3** release. Please report reproducible loading, save, rendering, compatibility-bridge, encounter, Pokédex, starter, and battle-behavior results before further species or progression mechanics are added.
