-- Wonder Guard for the standalone Shedinja mod.
--
-- Gen 1 has no held-item system, so WONDER_GUARD is a persistent player key
-- item. While that token exists, every active Shedinja in the battle receives
-- Wonder Guard. Gold keeps the player-side held-item switch, while opposing
-- Shedinja receive the species behavior intrinsically.

local WonderGuard = {}

-- Gen 1 routes SonicBoom, Dragon Rage, Seismic Toss, Night Shade, Psywave,
-- and Super Fang through EffectRegistry's chooseDamage path. Gold has the
-- corresponding Gen 2 effect names. Both families skip the normal formula
-- damage hook, so a pre-application accuracy gate covers their ordinary-hit
-- paths without allowing HP loss first.
local FIXED_DAMAGE_EFFECTS = {
  SPECIAL_DAMAGE_EFFECT = true,
  SUPER_FANG_EFFECT = true,
  EFFECT_STATIC_DAMAGE = true,
  EFFECT_LEVEL_DAMAGE = true,
  EFFECT_PSYWAVE = true,
  EFFECT_SUPER_FANG = true,
}

local function guardedDamage(next, ctx, isProtected)
  local damage, info = next(ctx)

  -- Preserve all non-move, already-nullified, and typeless damage paths.
  if not ctx or (ctx.opts and ctx.opts.typeless) or not damage or damage <= 0 then
    return damage, info
  end

  if not isProtected(ctx) then return damage, info end

  -- Damage.compute reports x10 type effectiveness. Wonder Guard allows only
  -- genuinely super-effective hits; neutral, resisted, and immune interactions
  -- deal no damage.
  if not info or (info.typeMult or info.effectiveness or 10) <= 10 then
    local guarded = {}
    for key, value in pairs(info or {}) do guarded[key] = value end
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

local function installFixedDamageGate(mod, isProtected)
  -- Call downstream first so the native accuracy path consumes its usual RNG,
  -- then stop a protected non-super-effective fixed hit before it can apply HP
  -- loss. Gold sure-hit paths do not roll accuracy and therefore require an
  -- engine-level pre-fixed-damage seam for complete coverage.
  mod.hooks:wrap("battle.accuracy", function(next, ctx)
    local hit = next(ctx)
    local move = ctx and ctx.move
    if hit and move and FIXED_DAMAGE_EFFECTS[move.effect]
      and isProtected(ctx) and fixedMoveEffectiveness(ctx) <= 10 then
      return false
    end
    return hit
  end, 101)
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

  installFixedDamageGate(mod, protectedTarget)
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
      local effectiveness = fixedMoveEffectiveness(ctx)
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

  installFixedDamageGate(mod, protectedTarget)
  mod.hooks:wrap("battle.damage", function(next, ctx)
    return guardedDamage(next, ctx, protectedTarget)
  end, 100)
end

return WonderGuard
