# Changelog

## 0.1.3 — Unused Gen 1 `$43` cry

Shedinja no longer borrows Kabuto’s cry. It now uses its own species-scoped cry record that reproduces the unused Generation I CryData row `$43` exactly:

| Raw CryData field | Value |
|---|---:|
| Base cry | `0` |
| Pitch | `128` (`$80`) |
| Length | `16` (`$10`) |

The new record derives from the imported base-0 cry header used by Nidoran♂ and applies the `$43` pitch and length only to Shedinja. It does **not** patch Nidoran♂, any other Pokémon’s cry, or the global cry-header table.

Shedinja remains fully standalone. Its Pokédex #152 registration, Wonder Guard inventory grant, and Route 1, Route 4, and Victory Road wild encounters do not need Starter Picker, Item Randomizer, Gym Leader Shuffle, Randomized Gym Challenge, Sound Effect Replacer, or any other mod to be installed.
