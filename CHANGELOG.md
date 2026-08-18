# Changelog

## 0.1.5 — Loader entry-point repair

This release fixes a boot failure in the published package: the entry script accessed `mod` as a global even though Gen1Recomp supplies the live mod API as an initializer argument. The error appeared as `attempt to index global 'mod' (a nil value)` and prevented all Shedinja content from loading.

`main.lua` now returns the loader-compatible initializer function and receives the API explicitly. The corrected entry registers Shedinja #152, Wonder Guard, the wild encounters, and the unused Gen 1 `$43` cry through that live API. Gameplay content is otherwise unchanged.

## 0.1.4 — Index installation fix

This corrective release changes the package ID to `gen1_shedinja` and aligns its internal module paths with that installed folder name. It resolves the case-sensitive index-import error that previously reported the ZIP as `GEN1_SHEDINJA` when the index expected `gen1_shedinja`.

Gameplay content, encounter tables, sprites, Wonder Guard behavior, and the isolated unused Gen 1 `$43` cry are unchanged.

## 0.1.3 — Unused Gen 1 `$43` cry

Shedinja no longer borrows Kabuto’s cry. It now uses its own species-scoped cry record that reproduces the unused Generation I CryData row `$43` exactly:

| Raw CryData field | Value |
|---|---:|
| Base cry | `0` |
| Pitch | `128` (`$80`) |
| Length | `16` (`$10`) |

The new record derives from the imported base-0 cry header used by Nidoran♂ and applies the `$43` pitch and length only to Shedinja. It does **not** patch Nidoran♂, any other Pokémon’s cry, or the global cry-header table.

Shedinja remains fully standalone. Its Pokédex #152 registration, Wonder Guard inventory grant, and Route 1, Route 4, and Victory Road wild encounters do not need Starter Picker, Item Randomizer, Gym Leader Shuffle, Randomized Gym Challenge, Sound Effect Replacer, or any other mod to be installed.
