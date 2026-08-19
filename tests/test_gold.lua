local root = assert(arg[1], "project root is required")

local registered, patched = {}, {}
local iconRegistered, iconOverrides = {}, {}
local events, wraps = {}, {}
local storage = {}

local function emit(name, event)
  for _, callback in ipairs(events[name] or {}) do callback(event) end
end
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
package.preload["src.render.TextBox"] = function()
  return { new = function(_, text, onDone) return { text = text, onDone = onDone } end }
end
package.preload["src.battle.gen2.Mon"] = function()
  return {
    new = function(_, species, level, opts)
      return { species = species, level = level, item = opts and opts.item,
        hp = 18, maxHp = 18, stats = { hp = 18 } }
    end,
    stampOT = function() end,
  }
end
package.preload["src.pokemon.Party"] = function()
  return { add = function(party, mon)
    if #party >= 6 then return false end
    party[#party + 1] = mon
    return true
  end }
end
package.preload["src.pokemon.Boxes"] = function()
  return { deposit = function(save, mon)
    save.boxes = save.boxes or { {} }
    for index, box in ipairs(save.boxes) do
      if #box < 20 then box[#box + 1] = mon; return index end
    end
    return nil
  end }
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
      events[name] = events[name] or {}
      events[name][#events[name] + 1] = callback
    end,
  },
  hooks = {
    wrap = function(_, name, callback, priority)
      wraps[name] = { callback = callback, priority = priority }
    end,
  },
  save = {
    get = function(_, key) return storage[key] end,
    set = function(_, key, value) storage[key] = value end,
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
local ready = assert(events["game.ready"] and events["game.ready"][1], "Gold game.ready handler was not registered")
assert(events["pokemon.caught"] and #events["pokemon.caught"] == 1, "Gold catch HP repair handler was not registered")
assert(events["pokemon.received"] and #events["pokemon.received"] == 1, "Gold receipt HP repair handler was not registered")
assert(events["pokemon.level_up"] and #events["pokemon.level_up"] == 1, "Gold level-up HP repair handler was not registered")
assert(events["script.ended"] and #events["script.ended"] == 2, "Gold script completion handlers were not registered")
assert(events["battle.started"] and #events["battle.started"] == 1, "Gold initial enemy HP repair handler was not registered")
assert(events["battle.battler_switched"] and #events["battle.battler_switched"] == 1, "Gold enemy switch HP repair handler was not registered")

local game = {
  save = {
    inventory = {},
    party = { { species = "SHEDINJA", hp = 16, maxHp = 16, stats = { hp = 16 } } },
    boxes = { { { species = "SHEDINJA", hp = 0, maxHp = 17, stats = { hp = 17 } } } },
  },
  data = {
    gen2Pokedex = { entries = {} },
    items = { POKE_BALL = { id = "POKE_BALL", index = 4 } },
  },
  stack = { push = function(self, box) self[#self + 1] = box end },
}
_G.mod.game = game
ready({ game = game })
assert(game.save.inventory.WONDER_GUARD == nil,
  "Gold Wonder Guard must not be placed in the bag at boot")
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

local initialEnemy = { species = "SHEDINJA", hp = 16, maxHp = 16, stats = { hp = 16 } }
local initialPlayer = { species = "SHEDINJA", hp = 18, maxHp = 18, stats = { hp = 18 } }
local liveBattle = { enemy = initialEnemy, player = initialPlayer }
emit("battle.started", { battle = liveBattle })
assert(initialEnemy.hp == 1 and initialEnemy.maxHp == 1 and initialEnemy.stats.hp == 1,
  "Gold initial enemy Shedinja must be normalized to 1 HP after battle construction")
assert(initialPlayer.hp == 18 and initialPlayer.maxHp == 18 and initialPlayer.stats.hp == 18,
  "Gold battle-start repair must not alter the active player mon")
local switchedEnemy = { species = "SHEDINJA", hp = 17, maxHp = 17, stats = { hp = 17 } }
liveBattle.enemy = switchedEnemy
emit("battle.battler_switched", { battle = liveBattle, battler = switchedEnemy, side = { index = 2 } })
assert(switchedEnemy.hp == 1 and switchedEnemy.maxHp == 1 and switchedEnemy.stats.hp == 1,
  "Gold switched-in enemy Shedinja must be normalized to 1 HP")
local switchedPlayer = { species = "SHEDINJA", hp = 19, maxHp = 19, stats = { hp = 19 } }
emit("battle.battler_switched", { battle = liveBattle, battler = switchedPlayer, side = { index = 1 } })
assert(switchedPlayer.hp == 19 and switchedPlayer.maxHp == 19 and switchedPlayer.stats.hp == 19,
  "Gold enemy-switch repair must not alter a player-side Shedinja")

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
emit("pokemon.caught", { game = game, mon = caught })
assert(caught.hp == 1 and caught.maxHp == 1 and caught.stats.hp == 1,
  "Gold caught Shedinja must be normalized to 1 HP")
local leveled = { species = "SHEDINJA", hp = 19, maxHp = 19, stats = { hp = 19 } }
emit("pokemon.level_up", { game = game, mon = leveled })
assert(leveled.hp == 1 and leveled.maxHp == 1 and leveled.stats.hp == 1,
  "Gold level-up Shedinja must remain at 1 HP")
local scripted = { species = "SHEDINJA", hp = 16, maxHp = 16, stats = { hp = 16 } }
game.save.party = { scripted }
emit("script.ended", { ctx = { game = game }, completed = true })
assert(scripted.hp == 1 and scripted.maxHp == 1 and scripted.stats.hp == 1,
  "Gold scripted starter Shedinja must be normalized after its script completes")
local other = { species = "PIKACHU", hp = 14, maxHp = 14, stats = { hp = 14 } }
assert(installed.normalizeHp(other) == false and other.maxHp == 14,
  "Gold HP normalizer must not alter other species")

local assistantCommand = assert(wraps["script.command"],
  "Gold Elm reward script-command detector was not registered")
local assistantCtx = {
  generation = 2, mapId = "ELMS_LAB", vm = { scriptVar = 0 }, scriptKey = "elm_aide_reward",
}
game.save.flags = { EVENT_GAVE_MYSTERY_EGG_TO_ELM = true }
assistantCommand.callback(function(_, _, _, _)
  assistantCtx.vm.scriptVar = 1
  return nil
end, assistantCtx, "giveitem", { 4, 5 }, { item = 4, quantity = 5, args = { 4, 5 } })
emit("script.ended", { ctx = assistantCtx, completed = true })
while #game.stack > 0 do
  local box = table.remove(game.stack, 1)
  if box.onDone then box.onDone() end
end
local reward = assert(game.save.party[#game.save.party], "Elm's assistant did not award Shedinja")
assert(reward.species == "SHEDINJA" and reward.item == "WONDER_GUARD"
  and reward.hp == 1 and reward.maxHp == 1 and reward.stats.hp == 1,
  "Elm's assistant Shedinja reward must hold Wonder Guard and have 1 HP")
assert(storage.gold_elm_shedinja_reward_claimed == true,
  "Elm's assistant reward must persist only after a successful gift")

local encounter = assert(wraps["encounter.species"], "Gold encounter hook was not registered")
assert(encounter.priority == 25, "Gold encounter hook priority drifted")
local original = { species = "RATTATA", level = 2 }
reward.item = nil
local disabled = encounter.callback(function(row) return row end, original, {
  mapId = "ROUTE_29", terrain = "grass", rng = function() error("inactive gate consumed RNG") end,
})
assert(disabled == original, "Gold route encounters must stay native without a Wonder Guard-holding Shedinja")
reward.item = "WONDER_GUARD"
local rolls = { 1, 5 }
local function rng() return table.remove(rolls, 1) end
local r29 = encounter.callback(function(row) return row end, original,
  { mapId = "ROUTE_29", terrain = "grass", rng = rng })
assert(r29.species == "SHEDINJA" and r29.level == 5 and r29.shedinjaEncounter,
  "Gold Route 29 replacement encounter is incorrect after the held-item gate is active")
-- The gate must also see a qualifying Shedinja in a PC box, not only the party.
table.remove(game.save.party)
game.save.boxes[1][#game.save.boxes[1] + 1] = reward
rolls = { 1, 37 }
local victory = encounter.callback(function(row) return row end, original,
  { mapId = "VICTORY_ROAD", terrain = "grass", rng = rng })
assert(victory.species == "SHEDINJA" and victory.level == 37,
  "Gold box-held Wonder Guard Shedinja did not activate Victory Road encounters")
local untouched = encounter.callback(function(row) return row end, original,
  { mapId = "ROUTE_29", terrain = "water", rng = function() return 1 end })
assert(untouched == original, "Gold water encounters must remain untouched")

local damage = assert(wraps["battle.damage"], "Gold Wonder Guard battle hook was not registered")
local accuracy = assert(wraps["battle.accuracy"], "Gold fixed-damage Wonder Guard hook was not registered")
assert(damage.priority == 100 and accuracy.priority == 101, "Gold Wonder Guard hook priorities drifted")
local player = { species = "SHEDINJA", item = "WONDER_GUARD", types = { "BUG" } }
local enemy = { species = "SHEDINJA", types = { "BUG" } }
local battle = { player = player, enemy = enemy, game = game, data = { type_chart = { matchups = {
  { attacker = "FIRE", defender = "BUG", multiplier = 20 },
  { attacker = "NORMAL", defender = "GHOST", multiplier = 0 },
} } } }
local function neutral() return 20, { typeMult = 10 } end
local function super() return 20, { typeMult = 20 } end
local amount, info = damage.callback(neutral, { battle = battle, target = player })
assert(amount == 0 and info.wonderGuard == true,
  "Gold Wonder Guard must block neutral damage while the player item is held")
assert(damage.callback(super, { battle = battle, target = player }) == 20,
  "Gold Wonder Guard must allow super-effective damage")
player.item = nil
assert(damage.callback(neutral, { battle = battle, target = player }) == 20,
  "Gold player Shedinja must not have Wonder Guard without the held item")
assert(damage.callback(neutral, { battle = battle, target = enemy }) == 0,
  "Gold enemy Shedinja must have intrinsic Wonder Guard without a held item")
assert(damage.callback(neutral, { battle = battle, target = player, opts = { typeless = true } }) == 20,
  "Gold Wonder Guard must not suppress typeless damage")
local accuracyCalls = 0
assert(accuracy.callback(function() accuracyCalls = accuracyCalls + 1; return true end, {
  battle = battle, target = enemy,
  move = { id = "SONIC_BOOM", type = "NORMAL", effect = "EFFECT_STATIC_DAMAGE" },
}) == false and accuracyCalls == 1,
  "Gold enemy Shedinja must block ordinary-accuracy fixed damage before HP loss")
assert(accuracy.callback(function() return true end, {
  battle = battle, target = enemy,
  move = { id = "EMBER", type = "FIRE", effect = "EFFECT_STATIC_DAMAGE" },
}) == true, "Gold enemy Shedinja must allow super-effective fixed damage")

assert(installed.SHEDINJA == "SHEDINJA" and installed.WONDER_GUARD == "WONDER_GUARD",
  "Gold initializer return table is incomplete")
print("Gold Shedinja content tests passed")
