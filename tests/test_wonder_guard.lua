local root = arg[1] or "."
package.path = root .. "/?.lua;" .. package.path

local WonderGuard = require("wonder_guard")
local wrapper
local mod = {
  hooks = {
    wrap = function(_, name, callback)
      assert(name == "battle.damage", "Wonder Guard must wrap battle.damage")
      wrapper = callback
    end,
  },
}

WonderGuard.install(mod, "SHEDINJA", "WONDER_GUARD")
assert(type(wrapper) == "function", "damage wrapper was not installed")

local function case(label, opts)
  local playerMon = { species = opts.playerSpecies or "SHEDINJA" }
  local enemyMon = { species = opts.enemySpecies or "RATTATA" }
  local player = { mon = playerMon }
  local enemy = { mon = enemyMon }
  local save = { inventory = opts.inventory or {} }
  local battle = { player = player, enemy = enemy, game = { save = save } }
  local target = opts.target == "enemy" and enemy or player
  local ctx = {
    battle = battle,
    target = target,
    opts = opts.typeless and { typeless = true } or {},
  }
  local baseDamage = opts.damage == nil and 22 or opts.damage
  local result, info = wrapper(function()
    return baseDamage, { typeMult = opts.typeMult == nil and 10 or opts.typeMult }
  end, ctx)
  assert(result == opts.expected,
    label .. ": expected " .. tostring(opts.expected) .. ", got " .. tostring(result))
  return info
end

local info = case("neutral hit on active player Shedinja with token", {
  inventory = { WONDER_GUARD = 1 }, typeMult = 10, expected = 0,
})
assert(info.wonderGuard == true, "guarded hit must be labelled")
case("resisted hit on active player Shedinja with token", {
  inventory = { WONDER_GUARD = 1 }, typeMult = 5, expected = 0,
})
case("super-effective hit passes through", {
  inventory = { WONDER_GUARD = 1 }, typeMult = 20, expected = 22,
})
case("missing token does not guard", {
  inventory = {}, typeMult = 10, expected = 22,
})
case("another player species does not guard", {
  inventory = { WONDER_GUARD = 1 }, playerSpecies = "PIKACHU", typeMult = 10, expected = 22,
})
case("enemy Shedinja is never guarded by player token", {
  inventory = { WONDER_GUARD = 1 }, enemySpecies = "SHEDINJA", target = "enemy", typeMult = 10, expected = 22,
})
case("typeless confusion-like damage is not guarded", {
  inventory = { WONDER_GUARD = 1 }, typeless = true, typeMult = 10, expected = 22,
})
case("already zero damage remains zero", {
  inventory = { WONDER_GUARD = 1 }, damage = 0, typeMult = 10, expected = 0,
})

print("wonder guard tests passed")
