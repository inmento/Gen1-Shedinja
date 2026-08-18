local Encounters = {}

-- A small local replacement chance keeps the native encounter table, encounter
-- rate, repel behavior, and every non-Shedinja slot intact. Route maps use the
-- grass path; Victory Road uses the indoor/cave encounter path on all floors.
local PLACEMENTS = {
  ROUTE_1 = { terrain = "grass", chance = 5, minLevel = 3, maxLevel = 5 },
  ROUTE_4 = { terrain = "grass", chance = 7, minLevel = 10, maxLevel = 12 },
  VICTORY_ROAD_1 = { terrain = "indoor", chance = 10, minLevel = 36, maxLevel = 38 },
  VICTORY_ROAD_2 = { terrain = "indoor", chance = 10, minLevel = 36, maxLevel = 38 },
  VICTORY_ROAD_3 = { terrain = "indoor", chance = 10, minLevel = 36, maxLevel = 38 },
}

local function copyEncounter(encounter)
  local out = {}
  for key, value in pairs(encounter or {}) do out[key] = value end
  return out
end

local function chooseLevel(rng, placement)
  local low = placement.minLevel
  local high = placement.maxLevel
  if high <= low then return low end
  return rng(low, high)
end

function Encounters.install(mod, speciesId)
  mod.hooks:wrap("encounter.species", function(next, encounter, ctx)
    encounter = next(encounter, ctx)
    if type(encounter) ~= "table" or type(ctx) ~= "table" then return encounter end

    local placement = PLACEMENTS[ctx.mapId]
    if not placement or placement.terrain ~= ctx.terrain then return encounter end

    local rng = ctx.rng
    if type(rng) ~= "function" or rng(1, 100) > placement.chance then return encounter end

    local replacement = copyEncounter(encounter)
    replacement.species = speciesId
    replacement.level = chooseLevel(rng, placement)
    replacement.shedinjaEncounter = true
    return replacement
  end, 25)
end

return Encounters
