-- Wonder Guard for the standalone Gen 1 Shedinja mod.
-- The game has no held-item system in Gen 1, so WONDER_GUARD is a persistent
-- player inventory token. It never applies to another species or an enemy
-- Shedinja, and it does not suppress typeless self-damage such as confusion.

local WonderGuard = {}

function WonderGuard.install(mod, shedinjaId, itemId)
  mod.hooks:wrap("battle.damage", function(next, ctx)
    local damage, info = next(ctx)

    -- Preserve all non-move, already-nullified, and typeless damage paths.
    if not ctx or (ctx.opts and ctx.opts.typeless) or not damage or damage <= 0 then
      return damage, info
    end

    local battle = ctx.battle
    local target = ctx.target
    local save = battle and battle.game and battle.game.save
    local inventory = save and save.inventory

    -- The token belongs to the player's save. It protects only the currently
    -- active player-side Shedinja, never an opposing Shedinja or a bench mon.
    if not inventory or not inventory[itemId]
        or not battle or target ~= battle.player
        or not target.mon or target.mon.species ~= shedinjaId then
      return damage, info
    end

    -- Damage.compute reports x10 type effectiveness.  Wonder Guard allows
    -- only genuinely super-effective hits; neutral, resisted, and immune
    -- interactions deal no damage.
    if not info or (info.typeMult or 10) <= 10 then
      local guarded = {}
      for key, value in pairs(info or {}) do guarded[key] = value end
      guarded.wonderGuard = true
      return 0, guarded
    end

    return damage, info
  end, 100)
end

return WonderGuard
