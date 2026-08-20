-- Gen 1 Shedinja
-- Standalone species-expansion test build. Do not combine with other mods that
-- alter the species roster, Pokédex range, or dex-backed content.

return function(mod)
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

  -- Party/PC menus use a dedicated two-frame 16x32 icon sheet; they do not
  -- use spriteFront. Register a Gen 1-derived per-species icon explicitly.
  local iconId = "ICON_GEN1_SHEDINJA"
  mod.content.icons:register(iconId, {
    image = mod.path .. "/assets/sprites/shedinja_icon.png",
    frames = 2,
  })
  mod.content.icons:override(SHEDINJA, iconId)

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
    -- Oak's starter Dex preview and the Gen 1 Dex menu resolve these paths
    -- directly. Mounted absolute paths are required outside the battle hook.
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

  -- The token is persistent and is granted once to both new and existing saves.
  -- If a player somehow removes it from an old save, loading again restores it.
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

if GameVersion.get() == "gold" then
  -- Gold has its own schema, palettes, held-item flow, and encounter maps.
  -- Keep that implementation isolated so the working Gen 1 branch below is
  -- never registered or modified during a Gold boot.
  return require("mods.shedinja.gold").install(
    mod, SHEDINJA, WONDER_GUARD, ELEC_TERA_ORB, AIR_BALLOON)
end

registerContent()
require("mods.shedinja.wonder_guard").install(mod, SHEDINJA, WONDER_GUARD)
require("mods.shedinja.battle_items").installGen1(
  mod, SHEDINJA, ELEC_TERA_ORB, AIR_BALLOON)
require("mods.shedinja.encounters").install(mod, SHEDINJA)

mod.events:on("game.ready", function(ev)
  grantWonderGuard(ev.game)
end)

return {
  SHEDINJA = SHEDINJA,
  WONDER_GUARD = WONDER_GUARD,
  ELEC_TERA_ORB = ELEC_TERA_ORB,
  AIR_BALLOON = AIR_BALLOON,
  grantWonderGuard = grantWonderGuard,
  unusedCry43 = SHEDINJA_UNUSED_CRY_43,
}
end
