local root = assert(arg[1], "project root is required")

local hooks = {}
local mod = {
  hooks = {
    wrap = function(_, name, callback, priority)
      assert(name == "encounter.species")
      assert(priority == 25)
      hooks[name] = callback
    end,
  },
}

local Encounters = assert(dofile(root .. "/encounters.lua"))
Encounters.install(mod, "SHEDINJA")
local transform = assert(hooks["encounter.species"], "encounter transform hook was not installed")

local function nextEncounter(encounter)
  return encounter
end

local function sequence(values)
  local index = 0
  return function(low, high)
    index = index + 1
    local value = assert(values[index], "missing deterministic RNG value")
    assert(value >= low and value <= high, "test RNG value was outside requested range")
    return value
  end
end

local base = { species = "RATTATA", level = 3, source = "vanilla" }
local route1 = transform(nextEncounter, base, {
  mapId = "ROUTE_1", terrain = "grass", rng = sequence({ 1, 4 }),
})
assert(route1.species == "SHEDINJA" and route1.level == 4 and route1.shedinjaEncounter,
  "Route 1 did not produce the configured Shedinja encounter")
assert(base.species == "RATTATA" and base.level == 3,
  "Shedinja replacement mutated the original encounter record")

local route4 = transform(nextEncounter, base, {
  mapId = "ROUTE_4", terrain = "grass", rng = sequence({ 1, 11 }),
})
assert(route4.species == "SHEDINJA" and route4.level == 11,
  "Route 4 did not produce the configured Shedinja encounter")

for _, mapId in ipairs({ "VICTORY_ROAD_1F", "VICTORY_ROAD_2F", "VICTORY_ROAD_3F" }) do
  local victory = transform(nextEncounter, base, {
    mapId = mapId, terrain = "indoor", rng = sequence({ 1, 37 }),
  })
  assert(victory.species == "SHEDINJA" and victory.level == 37,
    mapId .. " did not produce the configured Shedinja encounter")
end

local unchangedChance = transform(nextEncounter, base, {
  mapId = "ROUTE_1", terrain = "grass", rng = sequence({ 6 }),
})
assert(unchangedChance == base, "out-of-chance Route 1 encounter should stay vanilla")

local unchangedMap = transform(nextEncounter, base, {
  mapId = "ROUTE_2", terrain = "grass", rng = sequence({}),
})
assert(unchangedMap == base, "non-target map encounter should stay vanilla")

local obsoleteVictoryKey = transform(nextEncounter, base, {
  mapId = "VICTORY_ROAD_1", terrain = "indoor", rng = sequence({}),
})
assert(obsoleteVictoryKey == base,
  "obsolete non-floor-qualified Victory Road map IDs must not masquerade as live maps")

local unchangedTerrain = transform(nextEncounter, base, {
  mapId = "ROUTE_4", terrain = "water", rng = sequence({}),
})
assert(unchangedTerrain == base, "wrong terrain encounter should stay vanilla")

print("Shedinja Route 1, Route 4, and floor-qualified Victory Road encounter tests passed")
