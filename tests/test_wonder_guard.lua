local root = arg[1] or "."
package.path = root .. "/?.lua;" .. package.path

local WonderGuard = require("wonder_guard")
local wrappers = {}
local mod = {
  hooks = {
    wrap = function(_, name, callback, priority)
      wrappers[name] = { callback = callback, priority = priority }
    end,
  },
}

WonderGuard.install(mod, "SHEDINJA", "WONDER_GUARD")
local wrapper = assert(wrappers["battle.damage"] and wrappers["battle.damage"].callback,
  "damage wrapper was not installed")
local accuracy = assert(wrappers["battle.accuracy"] and wrappers["battle.accuracy"].callback,
  "fixed-damage accuracy wrapper was not installed")
assert(wrappers["battle.damage"].priority == 100 and wrappers["battle.accuracy"].priority == 101,
  "Wonder Guard hook priorities drifted")

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
case("enemy Shedinja is guarded while the Gen 1 key item is present", {
  inventory = { WONDER_GUARD = 1 }, enemySpecies = "SHEDINJA", target = "enemy", typeMult = 10, expected = 0,
})
case("enemy Shedinja is not guarded without the Gen 1 key item", {
  inventory = {}, enemySpecies = "SHEDINJA", target = "enemy", typeMult = 10, expected = 22,
})
case("typeless confusion-like damage is not guarded", {
  inventory = { WONDER_GUARD = 1 }, typeless = true, typeMult = 10, expected = 22,
})
case("already zero damage remains zero", {
  inventory = { WONDER_GUARD = 1 }, damage = 0, typeMult = 10, expected = 0,
})

local fixedTarget = { mon = { species = "SHEDINJA" }, curTypes = { "BUG", "GHOST" } }
local fixedBattle = {
  player = fixedTarget,
  game = { save = { inventory = { WONDER_GUARD = 1 } } },
  data = { type_chart = { matchups = {
    { attacker = "FIRE", defender = "BUG", multiplier = 20 },
    { attacker = "GHOST", defender = "GHOST", multiplier = 20 },
    { attacker = "NORMAL", defender = "GHOST", multiplier = 0 },
    { attacker = "FIGHTING", defender = "GHOST", multiplier = 0 },
  } } },
}
local accuracyCalls = 0
local function nativeAccuracy()
  accuracyCalls = accuracyCalls + 1
  return true
end
assert(accuracy(nativeAccuracy, {
  battle = fixedBattle, target = fixedTarget,
  move = { id = "SONIC_BOOM", type = "NORMAL", effect = "SPECIAL_DAMAGE_EFFECT" },
}) == false, "neutral fixed damage must be blocked before applyDamage")
assert(accuracyCalls == 1, "fixed-damage protection must preserve the native accuracy roll")
assert(accuracy(nativeAccuracy, {
  battle = fixedBattle, target = fixedTarget,
  move = { id = "NIGHT_SHADE", type = "GHOST", effect = "SPECIAL_DAMAGE_EFFECT" },
}) == true, "super-effective fixed damage must remain allowed")
assert(accuracy(nativeAccuracy, {
  battle = fixedBattle, target = fixedTarget,
  move = { id = "SUPER_FANG", type = "NORMAL", effect = "SUPER_FANG_EFFECT" },
}) == false, "Super Fang must be blocked when its type is not super-effective")
fixedBattle.game.save.inventory.WONDER_GUARD = nil
assert(accuracy(nativeAccuracy, {
  battle = fixedBattle, target = fixedTarget,
  move = { id = "SONIC_BOOM", type = "NORMAL", effect = "SPECIAL_DAMAGE_EFFECT" },
}) == true, "fixed damage must remain allowed without the Wonder Guard token")

print("wonder guard tests passed")
