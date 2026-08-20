local root = arg[1] or "."
package.path = root .. "/?.lua;" .. package.path

local WonderGuard = require("wonder_guard")
local chains = {}
local mod = {
  hooks = {
    wrap = function(_, name, callback, priority)
      chains[name] = chains[name] or {}
      table.insert(chains[name], { callback = callback, priority = priority or 0 })
      table.sort(chains[name], function(a, b) return a.priority > b.priority end)
    end,
  },
}

local player = { species = "SHEDINJA", item = "WONDER_GUARD" }
local enemy = { species = "RATTATA" }
local teraOn = false
local battleItems = {
  teraElectric = function(battle, target)
    return teraOn and target == battle.player
  end,
}

WonderGuard.installGold(mod, "SHEDINJA", "WONDER_GUARD", battleItems)

local function call(name, terminal, ...)
  local entries = chains[name] or {}
  local function dispatch(index, ...)
    local entry = entries[index]
    if not entry then return terminal(...) end
    return entry.callback(function(...)
      return dispatch(index + 1, ...)
    end, ...)
  end
  return dispatch(1, ...)
end

local battle = {
  player = player,
  enemy = enemy,
  data = { type_chart = { matchups = {
    { attacker = "GROUND", defender = "ELECTRIC", multiplier = 20 },
    { attacker = "FIRE", defender = "ELECTRIC", multiplier = 10 },
    { attacker = "GROUND", defender = "BUG", multiplier = 5 },
    { attacker = "FIRE", defender = "BUG", multiplier = 20 },
  } } },
}

local function nativeDamage()
  -- The native Gold formula may still have calculated from Bug/Ghost. The
  -- overlay corrects the returned effectiveness before Wonder Guard sees it.
  return 20, { effectiveness = 5, typeMult = 5 }
end

teraOn = true
local damage, info = call("battle.damage", nativeDamage, {
  battle = battle, target = player, move = { id = "EARTHQUAKE", type = "GROUND" }, opts = {},
})
assert(damage == 20 and info.effectiveness == 20,
  "Electric Tera must allow Ground through Wonder Guard using Electric effectiveness")

damage, info = call("battle.damage", nativeDamage, {
  battle = battle, target = player, move = { id = "EMBER", type = "FIRE" }, opts = {},
})
assert(damage == 0 and info.wonderGuard == true and info.effectiveness == 10,
  "Electric Tera must block a neutral Fire hit through Wonder Guard")

local accuracyCalls = 0
assert(call("battle.accuracy", function()
  accuracyCalls = accuracyCalls + 1
  return true
end, {
  battle = battle, target = player,
  move = { id = "FISSURE", type = "GROUND", effect = "EFFECT_STATIC_DAMAGE" },
}) == true and accuracyCalls == 1,
  "Electric Tera must allow super-effective fixed Ground damage before the guard")
assert(call("battle.accuracy", function() return true end, {
  battle = battle, target = player,
  move = { id = "SONIC_BOOM", type = "FIRE", effect = "EFFECT_STATIC_DAMAGE" },
}) == false, "Electric Tera must block neutral fixed damage before application")

teraOn = false
player.item = nil
damage = call("battle.damage", nativeDamage, {
  battle = battle, target = player, move = { id = "EMBER", type = "FIRE" }, opts = {},
})
assert(damage == 20, "player Shedinja without held Wonder Guard or Orb must remain unguarded")

battle.player = { species = "PIKACHU" }
teraOn = true
damage = call("battle.damage", nativeDamage, {
  battle = battle, target = battle.player, move = { id = "EMBER", type = "FIRE" }, opts = {},
})
assert(damage == 20, "the Electric overlay must never protect another player species")

print("Gold Electric Tera overlay tests passed")
