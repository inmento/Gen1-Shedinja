# Changelog


## 0.3.0 — Package spelling and repository migration

The package identity has been corrected from the misspelled **`shedninja`** to **`shedinja`**, matching the official Pokémon spelling. The public repository has also moved from `inmento/Gen1-Shedinja` to **`inmento/Shedinja`**. GitHub keeps the former repository URL as a redirect, but manifests, release assets, optional integrations, the compatibility bridge, and both mod indexes now use the corrected URL directly.

Because Gen1Recomp identifies installed mods by manifest ID, this is a one-time **package migration**, not a normal in-place launcher update. Remove the old `shedninja` install, then import or install `shedinja-0.3.0.zip`. The gameplay content from 0.2.3—including the Electric Tera Orb and Air Balloon—remains intact; this release corrects identity, module paths, archive naming, and integration metadata.

## 0.2.3 — Electric Tera Orb and Air Balloon battle options

This release adds two permanent, reusable **battle-only** items inspired by the Electric Tera + Air Balloon Shedinja interaction. They are deliberately bounded to reproduce a specific defensive choice without creating free generic item use.

### The two items

`ELEC TERA ORB` and `AIR BALLOON` are automatically added to new and existing saves and restored if missing on a later load. In Red, Blue, and Yellow they appear as non-tossable Bag items. In Gold they appear as non-tossable Key Items, while Gold’s existing `WONDER_GUARD` item remains a separate normal Bag item that can be held, given, or removed exactly as before.

Both new items work only while the **player’s currently active Pokémon is Shedinja** and only during a battle. A valid activation is free: it closes the item screen, displays its result, and returns to the battle command menu without consuming the player’s turn. This allows the player to activate the Orb, the Balloon, or both, then still select a move, switch, or run. Trying to use an item on another species, outside battle, or a second time during the same field entry does not apply an effect.

`ELEC TERA ORB` temporarily makes the player’s active Shedinja use **Electric** as its defensive type. In Gen 1 this is a real active-battler type replacement. In Gold it is a scoped defensive type overlay because Gold’s native formula reads the base species type first. In both games the effect is used by the normal type-effectiveness and Wonder Guard checks. The Orb does not change an enemy, wild, benched, or boxed Shedinja.

`AIR BALLOON` temporarily makes Ground-type moves miss the player’s active Shedinja before damage is applied. It does not replace Gold’s held `WONDER_GUARD`, it does not grant effects to another Pokémon, and it has no separate pop mechanic: a Ground move prevented before connecting cannot pop it.

Both temporary effects are cleared when the player’s Shedinja leaves the field, including an ordinary switch, a forced replacement, or a faint-driven replacement. They are also cleared at battle end. Sending Shedinja out again permits a fresh one-time activation of each item. The effects are battle-local rather than save data, so they cannot persist through battle completion or a save reload.

### Generation-specific Wonder Guard behavior

Red, Blue, and Yellow retain the persistent `WONDER_GUARD` Bag-token rule for every active Shedinja on either side. Electric Tera and Air Balloon are restricted to the player’s active Shedinja only.

Gold retains its deliberate held-item rule for the player: the player’s active Shedinja must still hold `WONDER_GUARD` for Wonder Guard to activate. Electric Tera changes the defensive matchup used by that existing protection; it does not bypass the held-item requirement or enable the conditional route encounters by itself. Enemy Shedinja retains its intrinsic ordinary-damage Wonder Guard behavior.

Indirect and typeless damage remains intentionally outside Wonder Guard. Gen 1 still permits poison, Toxic, burn, Leech Seed, and confusion self-damage; Gold also has its native indirect counterplay such as Sandstorm and Spikes.

The release was validated with the complete Shedinja suite: core registration, encounters, Gen 1 Wonder Guard, the new free-item and reset lifecycle harness, Gold Electric-overlay and fixed-damage coverage, Gold progression and encounter gates, Crystal 251 compatibility, cry schema, manifest validation against Gen1Recomp 0.2.10, and Lua syntax checks.

## 0.2.2 — Cross-side Wonder Guard and Gold rift progression

This update makes Wonder Guard a complete **Shedinja battle rule** rather than a player-only effect, while keeping the item system as the activation mechanism appropriate to each generation.

### Red, Blue, and Yellow

`WONDER_GUARD` remains the mod’s persistent Gen 1 Bag token. While that key item is present, **every active Shedinja** receives Wonder Guard: the player’s active Shedinja, wild Shedinja, and trainer-owned Shedinja. The rule still applies only to Shedinja in battle; it does not affect another species, a benched Pokémon, or typeless self-damage such as confusion. Removing or not carrying the token leaves all sides without the protection, so the item remains the single clear Gen 1 switch.

The fixed-damage coverage introduced during the reliability pass now uses this same cross-side rule. SonicBoom, Dragon Rage, Seismic Toss, Night Shade, Psywave, and Super Fang are blocked before HP loss when their type is not super-effective against a protected Shedinja. A genuinely super-effective typed fixed-damage move remains allowed.

### Gold

Gold no longer places `WONDER_GUARD` in the Bag automatically at startup. After the player returns the Mystery Egg to Professor Elm, Elm’s assistant still gives the native five Poké Balls first. Once that normal reward succeeds, a short new scene explains that a rift opened while Elm was dealing with the robbery. The assistant then gives the player a level-5 **Shedinja already holding WONDER GUARD**. The gift uses the normal party-first and PC-box fallback path, receives its mandatory 1 HP normalization, and is recorded only after delivery succeeds so it cannot duplicate on reload.

Gold’s Route 29, Route 34, and Victory Road Shedinja replacements are now conditional. They activate only while **any Shedinja in the player’s party or PC boxes is holding `WONDER_GUARD`**. A Shedinja without the item does not activate route encounters; neither does a different species holding it. Moving the item away from every owned Shedinja immediately returns those routes to their native encounter tables, without removing any Shedinja already caught. This gives the item a meaningful progression role and ensures the player receives a legitimate first Shedinja rather than relying on an unconditional early wild roll.

Enemy Shedinja in Gold now receives the ordinary-damage Wonder Guard rule intrinsically and does not need a fake held item. The player’s active Shedinja still requires the actual held item. Gold’s normal-accuracy fixed-damage paths share the same protection gate; the engine’s sure-hit fixed-damage branch remains the only known limitation until Gen1Recomp exposes a pre-application fixed-damage hook.

All new behavior was regression-tested with the Shedinja core suite, Gen 1/Gold battle coverage, conditional Gold encounter coverage, Elm reward flow, Crystal 251 compatibility, every unified bridge mode, v0.2.10 manifest validation, and Lua syntax checks.

## 0.2.1 — Unified compatibility bridge

Shedinja now declares one optional **Shedinja Compatibility Bridge** relationship for both generations. In Gold, that bridge activates only when Expanded Species is present and preserves Shedinja’s framework-aware #292 identity. In Red, Blue, or Yellow, it activates only when Crystal 251 is present and supplies the Crystal-safe index, split-stat, and genderless integration.

This replaces the separate Crystal 251-specific companion. Core Shedinja remains standalone: the bridge is optional, its two external frameworks are optional, and no hard circular dependency is introduced.

## 0.2.0 — Shedinja package identity and index repair

The mod package and manifest ID are now **`shedinja`**, and the release archive is named `shedinja-0.2.0.zip`. This replaces the legacy `gen1_shedinja` package identity so the manifest, installed folder, internal module paths, bridge requirements, and personal-index entry all use one consistent name.

The personal index now points at this current release asset instead of an outdated listing. Because Gen1Recomp treats a changed manifest ID as a distinct installed mod, remove the retired `gen1_shedinja` copy and install this `shedinja` package once; future updates will use the corrected repository metadata and package identity.

## 0.1.12 — Crystal 251 coexistence

Core Shedinja is no longer blocked when **Crystal 251** is active in Red, Blue, or Yellow. It recognizes Crystal 251 as a Gen 1-only optional ordering source and selects internal species index **252** instead of the standalone index 152 that Crystal uses for Chikorita. Shedinja remains National Dex **#292**.

For Crystal’s split-stat battle and summary systems, install the separate **Shedinja Crystal 251 Bridge**. That companion supplies Shedinja’s Crystal-era split stats and genderless metadata, retains the non-conflicting index and sparse #292 Dex range, and hard-requires both compatible core Shedinja and Crystal 251. Gold’s separate Expanded Species bridge remains unchanged.

## 0.1.11 — Launcher update metadata repair

This small release restores one missing manifest field: the core mod now declares its own public GitHub repository. Gen1Recomp’s **Update** and **Versions** flow reads the installed mod manifest to locate release updates; the personal index already knew the repository, but the installed Shedinja manifest did not. This correction allows launcher-driven updates from the index without changing gameplay, sprites, encounters, Wonder Guard, or the Expanded Species bridge behavior.

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
