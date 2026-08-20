-- Wonder Guard for the standalone Shedinja mod.
--
-- Gen 1 has no held-item system, so WONDER_GUARD is a persistent player key
-- item. While that token exists, every active Shedinja in the battle receives
-- Wonder Guard. Gold keeps the player-side held-item switch, while opposing
-- Shedinja receive the species behavior intrinsically.

local WonderGuard = {}

-- Formula damage is covered by the public battle.damage hook. These effects
-- instead choose or apply their own direct HP damage, so they require the same
-- type gate before that alternate path can reach the target. The identifier
-- pairs are the real Gen 1 / Gen 2 engine names, not move-name guesses.
local ALTERNATE_DAMAGE_EFFECTS = {
  SPECIAL_DAMAGE_EFFECT = true,
  SUPER_FANG_EFFECT = true,
  OHKO_EFFECT = true,
  BIDE_EFFECT = true,
  EFFECT_STATIC_DAMAGE = true,
  EFFECT_LEVEL_DAMAGE = true,
  EFFECT_PSYWAVE = true,
  EFFECT_SUPER_FANG = true,
  EFFECT_OHKO = true,
  EFFECT_COUNTER = true,
  EFFECT_MIRROR_COAT = true,
  EFFECT_BIDE = true,
}

local ALTERNATE_DAMAGE_MOVES = {
  COUNTER = true,
}

local function isDirectDamagingMove(move)
  if type(move) ~= "table" or move.id == "STRUGGLE" then return false end
  return (tonumber(move.power) or 0) > 0
    or ALTERNATE_DAMAGE_EFFECTS[move.effect] == true
    or ALTERNATE_DAMAGE_MOVES[move.id] == true
end

local function isAlternateDirectDamageMove(move)
  return type(move) == "table" and move.id ~= "STRUGGLE"
    and (ALTERNATE_DAMAGE_EFFECTS[move.effect] == true
      or ALTERNATE_DAMAGE_MOVES[move.id] == true)
end

local function guardedDamage(next, ctx, isProtected)
  local damage, info = next(ctx)

  -- Preserve all non-move, already-nullified, and typeless damage paths.
  if not ctx or not isDirectDamagingMove(ctx.move)
    or (ctx.opts and ctx.opts.typeless) or not damage or damage <= 0 then
    return damage, info
  end

  if not isProtected(ctx) then return damage, info end

  -- Damage.compute reports x10 type effectiveness. Wonder Guard allows only
  -- genuinely super-effective hits; neutral, resisted, and immune interactions
  -- deal no damage.
  if not info or (info.typeMult or info.effectiveness or 10) <= 10 then
    local guarded = {}
    for key, value in pairs(info or {}) do guarded[key] = value end
    -- Report actual type immunity to the native hit pipeline. Returning only
    -- zero damage makes the game still animate a successful hit; multiplier
    -- zero selects its ordinary "It doesn't affect" path before HP animation.
    guarded.typeMult = 0
    guarded.effectiveness = 0
    guarded.wonderGuard = true
    return 0, guarded
  end

  return damage, info
end

local function fixedMoveEffectiveness(ctx)
  local battle, move, target = ctx and ctx.battle, ctx and ctx.move, ctx and ctx.target
  local chart = battle and battle.data and battle.data.type_chart
  local targetTypes = ctx and ctx.virtualTargetTypes or (target and target.curTypes)
  if not targetTypes and battle and battle.speciesDef and target then
    local def = battle:speciesDef(target)
    targetTypes = def and def.types
  end
  targetTypes = targetTypes or (target and target.types)
  if not (move and move.type and chart and type(chart.matchups) == "table"
    and type(targetTypes) == "table") then
    return 10
  end

  local mult = 10
  for _, defenderType in ipairs(targetTypes) do
    for _, row in ipairs(chart.matchups) do
      if row.attacker == move.type and row.defender == defenderType then
        mult = math.floor(mult * (tonumber(row.multiplier) or 10) / 10)
      end
    end
  end
  return mult
end

local function shouldBlockDirectDamage(battle, user, target, move, isProtected,
    virtualTargetTypes)
  if not isDirectDamagingMove(move) then return false end
  local ctx = {
    battle = battle,
    user = user,
    target = target,
    move = move,
    virtualTargetTypes = virtualTargetTypes,
  }
  return isProtected(ctx) and fixedMoveEffectiveness(ctx) <= 10
end

local function installDirectDamageGate(mod, isProtected)
  -- Call downstream first so ordinary moves preserve the engine's native
  -- accuracy RNG. A direct non-super-effective move then enters the existing
  -- miss path before its formula, fixed-damage, Counter, or OHKO implementation
  -- can apply HP. Status moves and Struggle never enter this classifier.
  mod.hooks:wrap("battle.accuracy", function(next, ctx)
    local hit = next(ctx)
    local move = ctx and ctx.move
    if hit and isAlternateDirectDamageMove(move)
      and shouldBlockDirectDamage(ctx and ctx.battle, ctx and ctx.user,
        ctx and ctx.target, move, isProtected, ctx and ctx.virtualTargetTypes) then
      return false
    end
    return hit
  end, 101)
end

local function installGen1BideGuard(isProtected)
  -- Bide releases stored damage from BattleState:continueBide instead of the
  -- normal damaging or accuracy pipelines. It can therefore target Shedinja
  -- only after the move was started against another Pokémon. Zero only that
  -- pending release, letting the native method produce its ordinary failure
  -- path without changing Bide, Substitute, or damage handling globally.
  local ok, BattleState = pcall(require, "src.battle.BattleState")
  if not ok or type(BattleState) ~= "table" or BattleState._shedinjaWonderGuardBide then
    return
  end
  local nativeContinueBide = BattleState.continueBide
  if type(nativeContinueBide) ~= "function" then return end

  BattleState.continueBide = function(self, user, target)
    if user and user.bideTurns == 1
      and shouldBlockDirectDamage(self, user, target, {
        id = "BIDE", type = "NORMAL", effect = "BIDE_EFFECT",
      }, isProtected) then
      user.bideDamage = 0
    end
    return nativeContinueBide(self, user, target)
  end
  BattleState._shedinjaWonderGuardBide = true
end

local function installGoldAlternativeDamageGuard(isProtected, hasElectricTera)
  -- Gold resolves Counter, Mirror Coat, and Bide through Battle:dealDamage
  -- before (or outside) the normal accuracy/formula path. Only calls with the
  -- originating move attached are candidates: delayed Future Sight, Spikes,
  -- recoil, weather, and other indirect damage have no move here and remain
  -- deliberately untouched.
  local ok, Battle = pcall(require, "src.battle.gen2.Battle")
  if not ok or type(Battle) ~= "table" or Battle._shedinjaWonderGuardDirectDamage then
    return
  end
  local nativeDealDamage = Battle.dealDamage
  if type(nativeDealDamage) ~= "function" then return end

  Battle.dealDamage = function(self, attacker, defender, damage, opts)
    local move = opts and opts.move
    local ctx = { battle = self, user = attacker, target = defender, move = move }
    local virtualTargetTypes = hasElectricTera and hasElectricTera(ctx)
      and { "ELECTRIC" } or nil
    if shouldBlockDirectDamage(self, attacker, defender, move, isProtected,
        virtualTargetTypes) then
      return 0
    end
    return nativeDealDamage(self, attacker, defender, damage, opts)
  end
  Battle._shedinjaWonderGuardDirectDamage = true
end

function WonderGuard.install(mod, shedinjaId, itemId)
  local function protectedTarget(damageCtx)
    local battle = damageCtx and damageCtx.battle
    local target = damageCtx and damageCtx.target
    local save = battle and battle.game and battle.game.save
    local inventory = save and save.inventory

    -- Gen 1's key item is a global activation switch. It grants Wonder Guard
    -- to either active Shedinja but never to a bench mon or another species.
    return inventory and inventory[itemId]
      and battle and (target == battle.player or target == battle.enemy)
      and target and target.mon and target.mon.species == shedinjaId
  end

  installDirectDamageGate(mod, protectedTarget)
  installGen1BideGuard(protectedTarget)
  mod.hooks:wrap("battle.damage", function(next, ctx)
    return guardedDamage(next, ctx, protectedTarget)
  end, 100)
end

function WonderGuard.installGold(mod, shedinjaId, itemId, battleItems)
  local function hasElectricTera(ctx)
    local battle, target = ctx and ctx.battle, ctx and ctx.target
    return battleItems and battle and target
      and battleItems.teraElectric(battle, target) or false
  end

  -- Gold's native formula reads a species definition before mon.types. Supply a
  -- temporary defensive type overlay beneath the Wonder Guard wrapper, so the
  -- existing guard receives Electric's matchup result rather than Bug/Ghost's.
  -- The target has one HP, so an allowed Ground hit needs only remain non-zero;
  -- the hook preserves the engine's native damage amount while correcting the
  -- effectiveness used for immunity, messaging, and Wonder Guard.
  mod.hooks:wrap("battle.damage", function(next, ctx)
    if hasElectricTera(ctx) then ctx.virtualTargetTypes = { "ELECTRIC" } end
    local damage, info = next(ctx)
    if hasElectricTera(ctx) and info then
      local adjusted = {}
      for key, value in pairs(info) do adjusted[key] = value end
      local effectiveness = info.wonderGuard and 0 or fixedMoveEffectiveness(ctx)
      adjusted.effectiveness = effectiveness
      adjusted.typeMult = effectiveness
      return damage, adjusted
    end
    return damage, info
  end, 90)

  mod.hooks:wrap("battle.accuracy", function(next, ctx)
    if hasElectricTera(ctx) then ctx.virtualTargetTypes = { "ELECTRIC" } end
    return next(ctx)
  end, 200)

  local function protectedTarget(damageCtx)
    local battle = damageCtx and damageCtx.battle
    local target = damageCtx and damageCtx.target
    if not (battle and target and target.species == shedinjaId) then return false end

    -- An opposing Shedinja has Wonder Guard as an intrinsic species behavior.
    -- The player-side held item remains the deliberate Gold activation rule;
    -- Electric Tera only changes that protected Shedinja's defensive matchup.
    if target == battle.enemy then return true end
    return target == battle.player and target.item == itemId
  end

  installDirectDamageGate(mod, protectedTarget)
  installGoldAlternativeDamageGuard(protectedTarget, hasElectricTera)
  mod.hooks:wrap("battle.damage", function(next, ctx)
    return guardedDamage(next, ctx, protectedTarget)
  end, 100)
end

return WonderGuard
