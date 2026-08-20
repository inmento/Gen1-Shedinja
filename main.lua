-- Gen 1 Shedinja
-- Standalone species-expansion test build. Do not combine with other mods that
-- alter the species roster, Pokédex range, or dex-backed content.

return function(mod)
-- API 2 supplies this table in game. Keep a defensive fallback for minimal
-- harnesses and alternate loaders so the bridge-facing export contract remains
-- explicit rather than depending on a returned initializer value.
mod.exports = mod.exports or {}
local GameVersion = require("src.core.GameVersion")

local SHEDINJA = "SHEDINJA"
local WONDER_GUARD = "WONDER_GUARD"
local ELEC_TERA_ORB = "ELEC_TERA_ORB"
local AIR_BALLOON = "AIR_BALLOON"
local SHEDINJA_UNUSED_CRY_43 = "SHEDINJA_UNUSED_CRY_43"

local function registerContent()
  -- Standalone Gen 1 uses the first post-Kanto slot (152). Crystal 251 fills
  -- every internal slot through Celebi at 251, so its active optional bridge
  -- moves Shedinja to the first non-conflicting slot, 252. Both paths retain
  -- the official visible National Dex number #292.
  local crystal251 = mod.find("CRYSTAL_251")
  local speciesIndex = crystal251 and 252 or 152
  mod.content.constants:patch("dexSize", 292)

  mod.content.items:register(WONDER_GUARD, {
    id = WONDER_GUARD,
    name = "WONDER GUARD",
    price = 0,
    tossable = false,
  })

  -- Compact labels fit beside the Bag quantity column. The full mechanic is
  -- explained when the player activates either permanent battle-only item.
  mod.content.items:register(ELEC_TERA_ORB, {
    id = ELEC_TERA_ORB,
    name = "ELEC TERA ORB",
    price = 0,
    tossable = false,
  })
  mod.content.items:register(AIR_BALLOON, {
    id = AIR_BALLOON,
    name = "AIR BALLOON",
    price = 0,
    tossable = false,
  })

  -- The Gen 1 Dex page has an 18-character-wide description field. Explicit
  -- line breaks keep this Bulbapedia-derived summary inside its four-line page.
  -- DexEntryMenu supplies the final full stop to the last line.
  mod.content.text:register("GEN1_SHEDINJA_DEX",
    "HOLLOW BUG SHELL.\nLEGEND SAYS IT\nSTEALS THE SPIRIT\nOF THOSE WHO PEEK")

  -- Raw Gen 1 CryData index $43 is base cry 0, pitch $80, length $10.
  -- Derive a new record from Nidoran♂'s imported base-0 header rather than
  -- patching that native cry or the shared global cry-header table.
  mod.content.cries:register(SHEDINJA_UNUSED_CRY_43, {
    base = "NIDORAN_M",
    pitch = 128,
    length = 16,
  })

  -- Party/PC menus use a dedicated two-frame 16×32 icon sheet; they do not
  -- use spriteFront. In Gen 1 the registry value must be the image record on
  -- the species ID itself. Mapping the species to an arbitrary sheet label is
  -- a Gold-only form and leaves the Gen 1 PKMN screen with no image.
  mod.content.icons:register(SHEDINJA, {
    image = mod.path .. "/assets/sprites/shedinja_icon.png",
    frames = 2,
  })

  mod.content.pokemon:register(SHEDINJA, {
    id = SHEDINJA,
    index = speciesIndex,
    dex = 292,
    name = "SHEDINJA",
    types = { "BUG", "GHOST" },
    baseStats = {
      hp = 1,
      attack = 90,
      defense = 45,
      speed = 40,
      special = 30,
    },
    baseExp = 95,
    catchRate = 45,
    growthRate = "MEDIUM_FAST",
    frontSize = 5,
    -- Gen 1 draws a player back pic at 2x unless the species overrides that
    -- default. This art is already a full 48×48 back sprite, so 1x keeps it
    -- inside the normal player-side battle space rather than doubling it.
    battleScaleBack = 1,
    -- The credited front art fills its 56×56 source canvas more tightly than
    -- native front sprites. Scale only Shedinja's enemy/wild art down to keep
    -- it in the ordinary opponent slot without altering any other Pokémon.
    battleScaleFront = 0.6,
    -- Oak's starter Dex preview, the Gen 1 Dex menu, and battle all resolve
    -- these mounted paths. The sprite hook below repeats this mapping at the
    -- final resolver seam so a late UI/battle path override cannot swap sides.
    spriteFront = mod.path .. "/assets/sprites/shedinja_front.png",
    spriteBack = mod.path .. "/assets/sprites/shedinja_back.png",
    trueColor = true,
    cry = SHEDINJA_UNUSED_CRY_43,
    level1Moves = { "SCRATCH", "HARDEN", "LEECH_LIFE" },
    learnset = {
      { level = 5, move = "SAND_ATTACK" },
      { level = 13, move = "FURY_SWIPES" },
      { level = 25, move = "SPITE" },
      { level = 37, move = "CONFUSE_RAY" },
    },
    tmhm = {
      "TOXIC", "TAKE_DOWN", "DOUBLE_TEAM", "REST", "SUBSTITUTE",
    },
    evolutions = {},
    dexEntry = {
      kind = "BUG/GHOST",
      heightFt = 2,
      heightIn = 7,
      weight = 26,
      text = "GEN1_SHEDINJA_DEX",
    },
  })
end

local function grantWonderGuard(game)
  local save = game and game.save
  if not save then return end
  save.inventory = save.inventory or {}

  -- The three tokens are persistent and are granted once to both new and
  -- existing saves. The post-gift hook below calls this same helper, so a
  -- Shedinja selected as the initial starter receives WONDER GUARD before the
  -- player can regain overworld control.
  if not save.inventory[WONDER_GUARD] then
    save.inventory[WONDER_GUARD] = 1
  end
  if not save.inventory[ELEC_TERA_ORB] then
    save.inventory[ELEC_TERA_ORB] = 1
  end
  if not save.inventory[AIR_BALLOON] then
    save.inventory[AIR_BALLOON] = 1
  end
end

-- Gen 1's ordinary HP formula adds level + 10, so a base-HP-one species is
-- still created with a normal multi-HP total. Shedinja is the deliberate
-- exception: preserve a fainted mon at 0, but otherwise make both its current
-- and maximum HP exactly 1 wherever that record is used.
local function normalizeShedinjaHp(mon, data)
  if type(mon) ~= "table" or mon.species ~= SHEDINJA then return false end
  local definition = data and data.pokemon and data.pokemon[SHEDINJA]
  if type(mon.stats) ~= "table" and definition then
    local Stats = require("src.pokemon.Stats")
    mon.stats = Stats.calc(definition, mon.level or 1, mon.dvs or {}, mon.statExp)
  end
  mon.stats = mon.stats or {}
  mon.stats.hp = 1
  if mon.maxHp ~= nil then mon.maxHp = 1 end
  mon.hp = (tonumber(mon.hp) or 1) <= 0 and 0 or 1
  return true
end

local function normalizeSaveShedinjaHp(game)
  local save = game and game.save
  if not save then return 0 end
  local changed = 0
  local function normalizeList(list)
    for _, mon in ipairs(list or {}) do
      if normalizeShedinjaHp(mon, game and game.data) then changed = changed + 1 end
    end
  end
  normalizeList(save.party)
  for _, box in ipairs(save.boxes or {}) do normalizeList(box) end
  if save.daycare and normalizeShedinjaHp(save.daycare.mon, game and game.data) then
    changed = changed + 1
  end
  return changed
end

local function normalizeBattlerShedinjaHp(battler, data)
  local mon = battler and (battler.mon or battler)
  if not normalizeShedinjaHp(mon, data) then return false end
  if battler and battler.mon then
    battler.shownHP = mon.hp
    local Timing = require("src.battle.Timing")
    battler.shownPx = Timing.hpBarPixels(mon.hp, 1)
  end
  return true
end

if GameVersion.get() == "gold" then
  -- Gold has its own schema, palettes, held-item flow, and encounter maps.
  -- Keep that implementation isolated so the working Gen 1 branch below is
  -- never registered or modified during a Gold boot. API 2 publishes the
  -- mutable mod.exports table, so copy the installer handles into it rather
  -- than returning a table the loader intentionally ignores.
  local goldExports = require("mods.shedinja.gold").install(
    mod, SHEDINJA, WONDER_GUARD, ELEC_TERA_ORB, AIR_BALLOON)
  for key, value in pairs(goldExports or {}) do mod.exports[key] = value end
  return mod.exports
end

registerContent()
require("mods.shedinja.wonder_guard").install(mod, SHEDINJA, WONDER_GUARD)
require("mods.shedinja.battle_items").installGen1(
  mod, SHEDINJA, ELEC_TERA_ORB, AIR_BALLOON)
require("mods.shedinja.encounters").install(mod, SHEDINJA)

local frontSprite = mod.path .. "/assets/sprites/shedinja_front.png"
local backSprite = mod.path .. "/assets/sprites/shedinja_back.png"
-- Potato Voxel mirrors the player Pokémon card inside a staged 3D battle. This
-- deterministic horizontal reverse cancels that later renderer transform, but
-- it must be selected only when Potato has actually changed the original
-- player-back request into a front request. Ordinary 2D battles keep `backSprite`.
local potatoVoxelBackSprite = mod.path .. "/assets/sprites/shedinja_back_potato_voxel.png"
local function potatoVoxelActive()
  if type(mod.find) ~= "function" then return false end
  local ok, found = pcall(mod.find, "potato_voxel")
  return ok and found ~= nil
end

-- Resolve Shedinja art outside generic presentation layers. Potato Voxel's
-- staged battle wrapper (priority 1000) asks downstream providers for a front
-- image on an original player-back request; its 3D scene then mirrors that
-- player card. This higher-priority Shedinja-only wrapper observes the
-- downstream result. It supplies the pre-mirrored back image only in that
-- exact staged path, so the later Potato mirror restores the credited back art
-- to its intended orientation. Oak, Dex, and summary callers always receive
-- the credited front art. Every other species remains on the normal chain.
mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
  if not (ctx and ctx.species == SHEDINJA) then return next(path, ctx) end
  if ctx.side ~= "back" then return frontSprite end
  if ctx.kind ~= "battle" or not potatoVoxelActive() then return backSprite end

  local downstream = next(path, ctx)
  if downstream == frontSprite then return potatoVoxelBackSprite end
  return backSprite
end, 2000)

mod.events:on("game.ready", function(ev)
  local game = ev and ev.game
  grantWonderGuard(game)
  normalizeSaveShedinjaHp(game)
end)

-- `give_pokemon` has completed its party/box insertion by the time its
-- command handler returns. This covers Starter Picker's transformed Oak gift
-- as well as any ordinary scripted Shedinja reward without special-casing
-- another mod's private starter state.
mod.hooks:wrap("script.command", function(next, ctx, name, args, cmd)
  local result = next(ctx, name, args, cmd)
  if name == "give_pokemon" then
    local game = (ctx and ctx.game) or mod.game
    if normalizeSaveShedinjaHp(game) > 0 then grantWonderGuard(game) end
  end
  return result
end, -20000)

-- Route encounters construct the wild battler and its initial HUD before the
-- public battle.started event is emitted. Wrap that Gen 1 factory narrowly so
-- a wild Shedinja is already a genuine 1-HP battler when its image, HUD, and
-- capture record are first created. No other species takes this branch.
local BattleState = require("src.battle.BattleState")
if not BattleState._shedinjaOneHpWildFactory then
  local nativeNewWild = BattleState.newWild
  BattleState.newWild = function(game, species, level, opts)
    local battle = nativeNewWild(game, species, level, opts)
    if species == SHEDINJA then
      normalizeBattlerShedinjaHp(battle and battle.enemy, battle and battle.data)
    end
    return battle
  end
  BattleState._shedinjaOneHpWildFactory = true
end

mod.events:on("battle.started", function(ev)
  local battle = ev and ev.battle
  local data = battle and battle.data
  normalizeBattlerShedinjaHp(battle and battle.player, data)
  normalizeBattlerShedinjaHp(battle and battle.enemy, data)
end)
mod.events:on("battle.battler_switched", function(ev)
  local battle = ev and ev.battle
  normalizeBattlerShedinjaHp(ev and ev.battler, battle and battle.data)
end)
mod.events:on("battle.ended", function(ev)
  normalizeSaveShedinjaHp(ev and ev.battle and ev.battle.game)
end)
mod.events:on("pokemon.level_up", function(ev)
  normalizeShedinjaHp(ev and ev.mon, (mod.game and mod.game.data))
end)

-- Loader API 2 publishes `mod.exports`, not a returned table. The bridge reads
-- this object through mod.find("shedinja"), so assign each export directly.
mod.exports.SHEDINJA = SHEDINJA
mod.exports.WONDER_GUARD = WONDER_GUARD
mod.exports.ELEC_TERA_ORB = ELEC_TERA_ORB
mod.exports.AIR_BALLOON = AIR_BALLOON
mod.exports.grantWonderGuard = grantWonderGuard
mod.exports.normalizeHp = normalizeShedinjaHp
mod.exports.normalizeSaveHp = normalizeSaveShedinjaHp
mod.exports.unusedCry43 = SHEDINJA_UNUSED_CRY_43
return mod.exports
end
