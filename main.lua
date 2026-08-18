-- Gen 1 Shedinja
-- Standalone species-expansion test build. Do not combine with other mods that
-- alter the species roster, Pokédex range, or dex-backed content.

local GameVersion = require("src.core.GameVersion")

local SHEDINJA = "SHEDINJA"
local WONDER_GUARD = "WONDER_GUARD"

local function registerContent()
  mod.content.constants:patch("dexSize", 152)

  mod.content.items:register(WONDER_GUARD, {
    id = WONDER_GUARD,
    name = "WONDER GUARD",
    price = 0,
    tossable = false,
  })

  mod.content.text:register("GEN1_SHEDINJA_DEX",
    "The shed skin of a bug Pokémon.\nIt is said to steal the spirit\nof anyone who looks into its\nhollow body from behind.")

  mod.content.pokemon:register(SHEDINJA, {
    id = SHEDINJA,
    index = 152,
    dex = 152,
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
    spriteFront = "assets/sprites/shedinja_front.png",
    spriteBack = "assets/sprites/shedinja_back.png",
    trueColor = true,
    cry = "KABUTO",
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
      kind = "SHED",
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
end

if GameVersion.get() == "gold" then
  -- This test build is intentionally Gen 1-only; a Gen 2 Pokédex expansion
  -- needs a distinct project and data model.
  return
end

registerContent()
require("mods.GEN1_SHEDINJA.wonder_guard").install(mod, SHEDINJA, WONDER_GUARD)

mod.events:on("game.ready", function(ev)
  grantWonderGuard(ev.game)
end)

return {
  SHEDINJA = SHEDINJA,
  WONDER_GUARD = WONDER_GUARD,
  grantWonderGuard = grantWonderGuard,
}
