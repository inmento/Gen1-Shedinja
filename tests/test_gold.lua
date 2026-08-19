local root = assert(arg[1], "project root is required")

local registered, patched = {}, {}
local iconRegistered, iconOverrides = {}, {}
local events, wraps = {}, {}
local now = 0

local function registry()
  return {
    register = function(_, id, value) registered[id] = value end,
    patch = function(_, id, value) patched[id] = value end,
  }
end

package.preload["src.core.GameVersion"] = function()
  return { get = function() return "gold" end }
end
package.preload["mods.shedninja.gold"] = function()
  return assert(dofile(root .. "/gold.lua"))
end
package.preload["mods.shedninja.wonder_guard"] = function()
  return assert(dofile(root .. "/wonder_guard.lua"))
end
package.preload["mods.shedninja.encounters"] = function()
  return assert(dofile(root .. "/encounters.lua"))
end

_G.love = { timer = { getTime = function() return now end } }
_G.mod = {
  path = root,
  content = {
    constants = registry(),
    growth_rates = registry(),
    items = registry(),
    palettes = registry(),
    pokemon = registry(),
    icons = {
      register = function(_, id, value) iconRegistered[id] = value end,
      override = function(_, id, value) iconOverrides[id] = value end,
    },
  },
  events = {
    on = function(_, name, callback)
      assert(events[name] == nil, "duplicate Gold event registration: " .. name)
      events[name] = callback
    end,
  },
  hooks = {
    wrap = function(_, name, callback, priority)
      wraps[name] = { callback = callback, priority = priority }
    end,
  },
}

local init = assert(dofile(root .. "/main.lua"), "Shedinja entry module did not return an initializer")
local installed = assert(init(_G.mod), "Gold Shedinja initializer failed")

assert(patched.dexSize == 292, "Gold Pokédex size was not expanded to National Dex #292")
assert(registered.SHEDINJA_UNUSED_CRY_43 == nil,
  "Gold must not register the Gen 1-only unused cry override")

local growth = assert(registered.ERRATIC, "Gold Erratic growth curve was not registered")
assert(growth.expForLevel(1) == 0, "Erratic experience at level 1 must be zero")
assert(growth.expForLevel(50) == 125000, "Erratic level-50 experience is incorrect")
assert(growth.expForLevel(100) == 600000, "Erratic level-100 experience is incorrect")

local shedinja = assert(registered.SHEDINJA, "Gold Shedinja species was not registered")
assert(shedinja.index == 252 and shedinja.dex == 292,
  "Gold Shedinja must use internal slot 252 while displaying National Dex #292")
assert(shedinja.types[1] == "BUG" and shedinja.types[2] == "GHOST", "Gold Shedinja must be Bug/Ghost")
assert(shedinja.baseStats.hp == 1 and shedinja.baseStats.specialAttack == 30
  and shedinja.baseStats.specialDefense == 30, "Gold split Special stats are incorrect")
assert(shedinja.growthRate == "ERRATIC", "Gold Shedinja must use the Erratic growth curve")
assert(shedinja.picSize == 6 and shedinja.trueColor == nil,
  "Gold art must use the 6-tile GBC palette-rendered sprite path")
assert(shedinja.spriteFront == root .. "/assets/gen2/shedinja_front_1.png"
  and shedinja.spriteBack == root .. "/assets/gen2/shedinja_back.png",
  "Gold static screens must receive mounted Shedinja portrait paths")
assert(iconRegistered.ICON_GEN1_SHEDINJA
  and iconRegistered.ICON_GEN1_SHEDINJA.image == root .. "/assets/gen2/shedinja_icon.png"
  and iconRegistered.ICON_GEN1_SHEDINJA.width == 16
  and iconRegistered.ICON_GEN1_SHEDINJA.height == 32
  and iconRegistered.ICON_GEN1_SHEDINJA.frames == 2,
  "Gold Shedinja party icon sheet was not registered correctly")
assert(iconOverrides.SHEDINJA == "ICON_GEN1_SHEDINJA",
  "Gold Shedinja species was not associated with its party icon")
assert(shedinja.eggSteps == 15 and shedinja.eggGroups[1] == "EGG_MINERAL"
  and shedinja.eggGroups[2] == "EGG_MINERAL", "Gold breeding data is incorrect")
assert(#shedinja.levelMoves == 10 and shedinja.levelMoves[10].move == "GRUDGE",
  "Gold level-up move data is incomplete")

local palettes = assert(patched.pokemon and patched.pokemon.SHEDINJA,
  "Gold normal/shiny palette rows were not registered")
assert(palettes.normal[2][1] == 214 and palettes.normal[2][2] == 165 and palettes.normal[2][3] == 41,
  "Gold normal palette does not match the credited Crystal art")
assert(palettes.shiny[2][1] == 230 and palettes.shiny[2][2] == 173 and palettes.shiny[2][3] == 115,
  "Gold shiny palette does not match the credited Crystal art")

local item = assert(registered.WONDER_GUARD, "Gold Wonder Guard item was not registered")
assert(item.tossable == true and item.needsTarget == false,
  "Gold Wonder Guard must be a non-usable normal bag item so it can be given")
local ready = assert(events["game.ready"], "Gold game.ready handler was not registered")
assert(type(events["pokemon.caught"]) == "function", "Gold catch HP repair handler was not registered")
assert(type(events["pokemon.received"]) == "function", "Gold receipt HP repair handler was not registered")
assert(type(events["pokemon.level_up"]) == "function", "Gold level-up HP repair handler was not registered")
assert(type(events["script.ended"]) == "function", "Gold script HP repair handler was not registered")

local game = {
  save = {
    inventory = {},
    party = { { species = "SHEDINJA", hp = 16, maxHp = 16, stats = { hp = 16 } } },
    boxes = { { { species = "SHEDINJA", hp = 0, maxHp = 17, stats = { hp = 17 } } } },
  },
  data = { gen2Pokedex = { entries = {} } },
}
ready({ game = game })
assert(game.save.inventory.WONDER_GUARD == 1, "Gold Wonder Guard was not granted")
assert(game.save.party[1].hp == 1 and game.save.party[1].maxHp == 1
  and game.save.party[1].stats.hp == 1, "Gold save repair must normalize a living Shedinja to 1 HP")
assert(game.save.boxes[1][1].hp == 0 and game.save.boxes[1][1].maxHp == 1
  and game.save.boxes[1][1].stats.hp == 1, "Gold save repair must preserve a fainted Shedinja at 0/1 HP")
local entry = assert(game.data.gen2Pokedex.entries.SHEDINJA, "Gold Shedinja Dex entry was not inserted")
assert(entry.dex == 292 and entry.height == 207 and entry.weight == 26,
  "Gold Shedinja Dex measurements or number are incorrect")
for _, page in ipairs({ entry.text, entry.text2 }) do
  for line in (page .. "<NEXT>"):gmatch("(.-)<NEXT>") do
    assert(#line <= 18, "Gold Shedinja Dex text exceeds the 18-column entry width")
  end
end
local existing = { dex = 999 }
game.data.gen2Pokedex.entries.SHEDINJA = existing
ready({ game = game })
assert(game.data.gen2Pokedex.entries.SHEDINJA == existing,
  "Gold Dex injection must never overwrite an existing entry")

local sprite = assert(wraps["pokemon.sprite"], "Gold animated sprite hook was not registered")
assert(sprite.priority == 50, "Gold sprite hook priority drifted")
local mon = { species = "SHEDINJA" }
local function fallback(path) return "fallback/" .. path end
nnow = nil
now = 0
assert(sprite.callback(fallback, "base.png", { kind = "battle", species = "SHEDINJA", side = "front", mon = mon })
  == root .. "/assets/gen2/shedinja_front_1.png", "Gold animation must begin on frame 1")
now = 0.11
assert(sprite.callback(fallback, "base.png", { kind = "battle", species = "SHEDINJA", side = "front", mon = mon })
  == root .. "/assets/gen2/shedinja_front_2.png", "Gold animation frame 2 timing is incorrect")
now = 0.65
assert(sprite.callback(fallback, "base.png", { kind = "battle", species = "SHEDINJA", side = "front", mon = mon })
  == root .. "/assets/gen2/shedinja_front_3.png", "Gold animation frame 3 timing is incorrect")
now = 3
assert(sprite.callback(fallback, "base.png", { kind = "battle", species = "SHEDINJA", side = "front", mon = mon })
  == root .. "/assets/gen2/shedinja_front_3.png", "Gold animation must hold the final frame after one pass")
assert(sprite.callback(fallback, "base.png", { kind = "battle", species = "SHEDINJA", side = "back", mon = mon })
  == "fallback/base.png", "Gold back sprite must remain static")
assert(sprite.callback(fallback, "base.png", { kind = "battle", species = "PIKACHU", side = "front", mon = {} })
  == "fallback/base.png", "Gold animation hook must not alter other species")
assert(sprite.callback(fallback, "base.png", { kind = "battle", species = "SHEDINJA", side = "front" })
  == root .. "/assets/gen2/shedinja_front_3.png",
  "Gold animation fallback must remain safe when no battler record is available")

local caught = { species = "SHEDINJA", hp = 17, maxHp = 17, stats = { hp = 17 } }
events["pokemon.caught"]({ game = game, mon = caught })
assert(caught.hp == 1 and caught.maxHp == 1 and caught.stats.hp == 1,
  "Gold caught Shedinja must be normalized to 1 HP")
local leveled = { species = "SHEDINJA", hp = 19, maxHp = 19, stats = { hp = 19 } }
events["pokemon.level_up"]({ game = game, mon = leveled })
assert(leveled.hp == 1 and leveled.maxHp == 1 and leveled.stats.hp == 1,
  "Gold level-up Shedinja must remain at 1 HP")
local scripted = { species = "SHEDINJA", hp = 16, maxHp = 16, stats = { hp = 16 } }
game.save.party = { scripted }
events["script.ended"]({ ctx = { game = game } })
assert(scripted.hp == 1 and scripted.maxHp == 1 and scripted.stats.hp == 1,
  "Gold scripted starter Shedinja must be normalized after its script completes")
local other = { species = "PIKACHU", hp = 14, maxHp = 14, stats = { hp = 14 } }
assert(installed.normalizeHp(other) == false and other.maxHp == 14,
  "Gold HP normalizer must not alter other species")

local encounter = assert(wraps["encounter.species"], "Gold encounter hook was not registered")
assert(encounter.priority == 25, "Gold encounter hook priority drifted")
local rolls = { 1, 5 }
local function rng() return table.remove(rolls, 1) end
local original = { species = "RATTATA", level = 2 }
local r29 = encounter.callback(function(row) return row end, original,
  { mapId = "ROUTE_29", terrain = "grass", rng = rng })
assert(r29.species == "SHEDINJA" and r29.level == 5 and r29.shedinjaEncounter,
  "Gold Route 29 replacement encounter is incorrect")
rolls = { 1, 37 }
local victory = encounter.callback(function(row) return row end, original,
  { mapId = "VICTORY_ROAD", terrain = "grass", rng = rng })
assert(victory.species == "SHEDINJA" and victory.level == 37,
  "Gold Victory Road replacement encounter is incorrect")
local untouched = encounter.callback(function(row) return row end, original,
  { mapId = "ROUTE_29", terrain = "water", rng = function() return 1 end })
assert(untouched == original, "Gold water encounters must remain untouched")

local damage = assert(wraps["battle.damage"], "Gold Wonder Guard battle hook was not registered")
assert(damage.priority == 100, "Gold Wonder Guard hook priority drifted")
local player = { mon = { species = "SHEDINJA", item = "WONDER_GUARD" } }
local battle = { player = player, game = game }
local function neutral() return 20, { typeMult = 10 } end
local function super() return 20, { typeMult = 20 } end
local amount, info = damage.callback(neutral, { battle = battle, target = player })
assert(amount == 0 and info.wonderGuard == true,
  "Gold Wonder Guard must block neutral damage while the item is held")
assert(damage.callback(super, { battle = battle, target = player }) == 20,
  "Gold Wonder Guard must allow super-effective damage")
player.mon.item = nil
assert(damage.callback(neutral, { battle = battle, target = player }) == 20,
  "Gold Wonder Guard must not work without the held item")
player.mon.item = "WONDER_GUARD"
local enemy = { mon = { species = "SHEDINJA", item = "WONDER_GUARD" } }
assert(damage.callback(neutral, { battle = battle, target = enemy }) == 20,
  "Gold Wonder Guard must not protect opposing Shedinja")
assert(damage.callback(neutral, { battle = battle, target = player, opts = { typeless = true } }) == 20,
  "Gold Wonder Guard must not suppress typeless damage")

assert(installed.SHEDINJA == "SHEDINJA" and installed.WONDER_GUARD == "WONDER_GUARD",
  "Gold initializer return table is incomplete")
print("Gold Shedinja content tests passed")
