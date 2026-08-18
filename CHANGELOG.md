# Changelog

## 0.1.2 — Wild encounters and suite compatibility

Shedinja now has normal wild encounter placements in three Kanto areas without changing the base encounter rate or overwriting the other native encounter slots.

| Location | Encounter path | Chance | Level range |
|---|---|---:|---:|
| Route 1 | Grass | 5% of eligible wild rolls | 3–5 |
| Route 4 | Grass | 7% of eligible wild rolls | 10–12 |
| Victory Road 1F, 2F, and 3F | Cave / indoor | 10% of eligible wild rolls | 36–38 |

This release also verifies coexistence with the user’s non-dex gameplay mods. Starter Picker can expose a valid expanded-dex species only when a compatible content provider has registered it; Item Randomizer continues to exclude the non-tossable `WONDER GUARD` token from random item pools; and Gym Leader Shuffle, Randomized Gym Challenge, and Sound Effect Replacer do not overwrite Shedinja’s registry or Wonder Guard behavior.

Shedinja remains intentionally incompatible with Crystal 251, Kanto Reforged, and any other mod that claims the same Pokédex/index space or independently changes the Pokémon roster. In particular, Crystal 251 owns index #152 for Chikorita, while this standalone mod must retain Shedinja at its required #152 index.

The included Shedinja sprite adaptations are credited to BouncingPiplup’s *G1SP 0292 – Shedinja*. They are distributed under [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/), with the required attribution and modification notice in `CREDITS.md` and `assets/sprites/LICENSE.md`.
