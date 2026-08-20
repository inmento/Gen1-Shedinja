-- Temporary battle-only Electric Tera Orb and Air Balloon support.
--
-- These are intentionally not ordinary consumable battle items.  They provide
-- one free activation per player Shedinja field entry, live only in weak
-- battle-local state, and are cleared when that Shedinja leaves the field.

local BattleItems = {}

local function weakKeys()
  return setmetatable({}, { __mode = "k" })
end

local function newBattleState()
  return { byBattler = weakKeys() }
end

local function installSharedState(mod, shedinjaId, teraItemId, balloonItemId, isGold)
  local battles = weakKeys()

  local function monFor(battler)
    return battler and (battler.mon or battler)
  end

  local function playerBattler(battle)
    return battle and battle.player
  end

  local function isPlayerShedinja(battle, battler)
    local player = playerBattler(battle)
    local mon = monFor(battler)
    return player ~= nil and battler == player and mon and mon.species == shedinjaId
  end

  local function stateFor(battle, battler, create)
    if not (battle and battler) then return nil end
    local battleState = battles[battle]
    if not battleState and create then
      battleState = newBattleState()
      battles[battle] = battleState
    end
    if not battleState then return nil end
    local state = battleState.byBattler[battler]
    if not state and create then
      state = {}
      battleState.byBattler[battler] = state
    end
    return state
  end

  local function clearState(battle, battler)
    local state = stateFor(battle, battler, false)
    if state and state.originalTypes and battler and battler.curTypes then
      battler.curTypes = state.originalTypes
    end
    local battleState = battles[battle]
    if battleState and battler then battleState.byBattler[battler] = nil end
  end

  local function activate(battle, itemId)
    local battler = playerBattler(battle)
    if not isPlayerShedinja(battle, battler) then
      return false, "Only an active\nSHEDINJA can use that."
    end

    local state = stateFor(battle, battler, true)
    if itemId == teraItemId then
      if state.teraElectric then
        return false, "ELEC TERA ORB is\nalready active."
      end
      state.teraElectric = true
      -- Gen 1's battle battler carries the current type list used by its
      -- formula, status, and type-effect code.  Gold reads its base species
      -- type in several places, so its defensive overlay is supplied through
      -- the Wonder Guard and damage hooks rather than rewriting mon.types.
      if not isGold and battler.curTypes then
        state.originalTypes = battler.curTypes
        battler.curTypes = { "ELECTRIC" }
      end
      return true, "SHEDINJA became\nELECTRIC type!"
    end

    if itemId == balloonItemId then
      if state.airBalloon then
        return false, "AIR BALLOON is\nalready active."
      end
      state.airBalloon = true
      return true, "SHEDINJA floats on\nan AIR BALLOON!"
    end

    return false, "That isn't going\nto help here."
  end

  local function teraElectric(battle, battler)
    local state = stateFor(battle, battler, false)
    return isPlayerShedinja(battle, battler) and state and state.teraElectric or false
  end

  local function airBalloon(battle, battler)
    local state = stateFor(battle, battler, false)
    return isPlayerShedinja(battle, battler) and state and state.airBalloon or false
  end

  mod.events:on("battle.started", function(ev)
    if ev and ev.battle then battles[ev.battle] = newBattleState() end
  end)

  mod.events:on("battle.battler_switched", function(ev)
    local battle = ev and ev.battle
    if not battle then return end
    -- A reset is deliberately restricted to the player side. Enemy and wild
    -- Shedinja never receive these player-controlled effects.
    if ev.side == (battle.sides and battle.sides[1]) or ev.battler == battle.player then
      clearState(battle, ev.previous)
      clearState(battle, ev.battler)
    end
  end)

  mod.events:on("battle.ended", function(ev)
    local battle = ev and ev.battle
    if not battle then return end
    clearState(battle, battle.player)
    battles[battle] = nil
  end)

  -- Air Balloon is an accuracy-level Ground immunity. Calling downstream first
  -- keeps native accuracy RNG intact, then turns a would-be Ground hit into the
  -- regular miss path before it reaches damage application.
  mod.hooks:wrap("battle.accuracy", function(next, ctx)
    local hit = next(ctx)
    local battle, target, move = ctx and ctx.battle, ctx and ctx.target, ctx and ctx.move
    if hit and battle and target and move and move.type == "GROUND"
      and airBalloon(battle, target) then
      return false
    end
    return hit
  end, 150)

  return {
    activate = activate,
    teraElectric = teraElectric,
    airBalloon = airBalloon,
    isPlayerShedinja = isPlayerShedinja,
  }
end

function BattleItems.installGen1(mod, shedinjaId, teraItemId, balloonItemId)
  local state = installSharedState(mod, shedinjaId, teraItemId, balloonItemId, false)

  -- Gen 1's shared BagMenu exposes item.use as a public Mod API seam. Custom
  -- item uses close the bag and return directly to the command menu instead of
  -- calling BattleState:itemUsed(), which is the native turn-spending path.
  mod.hooks:wrap("item.use", function(next, game, battle, itemId, target, list)
    if itemId ~= teraItemId and itemId ~= balloonItemId then
      return next(game, battle, itemId, target, list)
    end

    local TextBox = require("src.render.TextBox")
    local success, text
    if not battle then
      success, text = false, "OAK: This isn't the\ntime to use that!"
    else
      success, text = state.activate(battle, itemId)
    end

    if success and list and list.close then list:close() end
    if game and game.stack then
      game.stack:push(TextBox.new(game, text, function()
        if success and battle then
          battle.phase = "menu"
          battle.afterQueue = "menu"
        end
      end))
    end
    return nil
  end, 200)

  return state
end

function BattleItems.installGold(mod, shedinjaId, teraItemId, balloonItemId)
  local state = installSharedState(mod, shedinjaId, teraItemId, balloonItemId, true)

  -- Gold currently has no Mod API wrapper around ui/gen2/BattleState:useItem.
  -- Keep a single idempotent dispatcher on the module table, and only intercept
  -- these registered mod IDs while their live item records exist. Every native
  -- item continues through the original method untouched.
  local BattleState = require("src.ui.gen2.BattleState")
  local wrapper = BattleState._shedninjaBattleItemWrapper
  if not wrapper then
    wrapper = {
      original = BattleState.useItem,
      handlers = {},
    }
    BattleState._shedninjaBattleItemWrapper = wrapper
    BattleState.useItem = function(self, itemId)
      local handler = BattleState._shedninjaBattleItemWrapper
        and BattleState._shedninjaBattleItemWrapper.handlers[itemId]
      if handler and handler.enabled(self, itemId) then
        return handler.use(self, itemId)
      end
      return wrapper.original(self, itemId)
    end
  end

  local function itemStillRegistered(self, itemId)
    local items = self and self.game and self.game.data and self.game.data.items
    local record = items and items[itemId]
    return type(record) == "table" and (record.id == nil or record.id == itemId)
  end

  local function showResult(self, text)
    -- useItem is called after BattlePack has popped. An empty queue makes the
    -- regular resolving flow return to the command menu after the player closes
    -- this message, without submitting a turn to Battle:takeTurn().
    self.queue = {}
    self.message = text
    self.messageTimer = 1
    self.phase = "resolving"
  end

  local handler = {
    original = wrapper.original,
    enabled = function(self, itemId)
      return itemStillRegistered(self, itemId)
    end,
    use = function(self, itemId)
      local battle = self and self.battle
      local success, text = state.activate(battle, itemId)
      showResult(self, text)
      return success
    end,
  }
  wrapper.handlers[teraItemId] = handler
  wrapper.handlers[balloonItemId] = handler

  return state
end

return BattleItems
