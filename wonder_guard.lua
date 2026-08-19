-- Wonder Guard for the standalone Gen 1 Shedinja mod.
-- The game has no held-item system in Gen 1, so WONDER_GUARD is a persistent
-- player inventory token. It never applies to another species or an enemy
-- Shedinja, and it does not suppress typeless self-damage such as confusion.

local WonderGuard = {}

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
  if not info or (info.typeMult or 10) <= 10 then
    local guarded = {}
    for key, value in pairs(info or {}) do guarded[key] = value end
    guarded.wonderGuard = true
    return 0, guarded
  end

  return damage, info
end

function WonderGuard.install(mod, shedinjaId, itemId)
  mod.hooks:wrap("battle.damage", function(next, ctx)
    return guardedDamage(next, ctx, function(damageCtx)
      local battle = damageCtx.battle
      local target = damageCtx.target
      local save = battle and battle.game and battle.game.save
      local inventory = save and save.inventory

      -- Gen 1: a persistent player inventory token protects only the active
      -- player-side Shedinja, never an opposing Shedinja or a bench mon.
      return inventory and inventory[itemId]
        and battle and target == battle.player
        and target.mon and target.mon.species == shedinjaId
    end)
  end, 100)
end

function WonderGuard.installGold(mod, shedinjaId, itemId)
  mod.hooks:wrap("battle.damage", function(next, ctx)
    return guardedDamage(next, ctx, function(damageCtx)
      local battle = damageCtx.battle
      local target = damageCtx.target

      -- Gold: the same player-only active-slot restriction applies, but the
      -- protection belongs to the actual held item rather than the bag.
      return battle and target == battle.player
        and target.mon and target.mon.species == shedinjaId
        and target.mon.item == itemId
    end)
  end, 100)
end

return WonderGuard
