# Changelog

## 0.1.10 — Current-API bridge relationship

After validation against Gen1Recomp **0.2.10**, core Shedinja now declares the public Shedinja Expanded Bridge as a **Gold-only optional dependency** with a direct GitHub source. Shedinja remains independently installable and fully functional in Red, Blue, Yellow, and standalone Gold. When the bridge is installed and active in Gold, the loader orders it after core Shedinja without creating a circular hard-dependency block.

## 0.1.9 — Gen 1 party and PC icon fix

Gen 1 party, PC, and selection menus use a dedicated two-frame icon sheet rather than the front battle sprite. Shedinja now registers a 16×32 static icon derived from its credited Gen 1 front artwork and maps that icon directly to the Shedinja species record. Oak, Pokédex, summary, battle, encounter, Wonder Guard, and starter behavior are otherwise unchanged.

## 0.1.8 — Gold presentation and one-HP fixes; Gen 1 Oak preview repair

Gold now supplies a native party-menu icon, mounted static portrait paths for Elm’s choice preview and the summary screen, and a lifecycle repair that enforces Shedinja’s defining **1 maximum HP** after catches, scripted gifts, transfers, level-up refreshes, and save loading. The battle animation remains unchanged.

Gen 1 Oak and Pokédex preview screens now use mounted portrait paths, fixing the missing Shedinja image. Their category now displays **BUG/GHOST** rather than the incorrect `SHED` label. Starter Picker’s Gen 1 rival projection was also regression-tested with Shedinja: when neither remaining starter is super-effective against Bug/Ghost, it correctly selects one of the two remaining safe candidates without mutating the native rival party.

For Expanded Species users, install the separate Gold-only **Shedinja Expanded Bridge**. Core Shedinja remains standalone; the bridge is the only component that requires both mods and preserves framework-aware virtual and visible #292 identity.

## 0.1.7 — Gold support, animated Crystal-style sprites, and held-item Wonder Guard

Shedinja now supports **Pokémon Gold** while preserving the established Red/Blue/Yellow implementation unchanged. Gold uses a distinct Gen 2 species record at internal slot `252`, displays Shedinja as National Dex #292, uses Gen 2 split Special stats and the Erratic experience curve, and adds Route 29, Route 34, and Victory Road land encounters without replacing any native encounter table.

Gold includes a credited three-frame Crystal-style front battle animation and static back sprite adapted from **nuukiie / Nuuk**. The original normal palette and included shiny palette are registered through Gold’s Pokémon palette system, so shiny coloring follows Shedinja’s actual shiny state. A two-page Gold Pokédex entry is inserted only when the custom entry is absent, avoiding a blank #292 page without replacing a native entry.

Wonder Guard is now generation-specific. Red/Blue/Yellow retain the persistent non-tossable Bag token. Gold receives an equipable, non-usable Bag item that can be given through the normal **GIVE** flow; it protects only the player’s active Shedinja while that Shedinja actually holds `WONDER_GUARD`. It is intentionally tossable because Gold does not permit Give on non-tossable/key-item-style records.

## 0.1.6 — National Dex entry and text layout

Shedinja now displays as its official **National Dex #292** while retaining internal species slot `152`, which remains the safe Gen 1 content identity used by encounters, battle data, and saves. The mod’s merged `dexSize` is now `292`; the Pokédex lists only registered species, so this does not create blank entries between Mew and Shedinja.

Its Gen 1 Pokédex description is now an explicitly wrapped, single four-line page based on Bulbapedia’s Ruby-era lore summary. Each line fits the entry page’s 18-character text field, preventing clipping or an unintended second page.

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
