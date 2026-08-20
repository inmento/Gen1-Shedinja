local root = arg[1] or "."
package.path = root .. "/?.lua;" .. package.path

local BattleItems = require("battle_items")

local function makeMod()
  local hooks, events = {}, {}
  return {
    hooks = {
      wrap = function(_, name, callback, priority)
        hooks[name] = hooks[name] or {}
        table.insert(hooks[name], { callback = callback, priority = priority or 0 })
        table.sort(hooks[name], function(a, b) return a.priority > b.priority end)
      end,
    },
    events = {
      on = function(_, name, callback)
        events[name] = events[name] or {}
        table.insert(events[name], callback)
      end,
    },
    _hooks = hooks,
    _events = events,
  }
end

local function emit(mod, name, ev)
  for _, callback in ipairs(mod._events[name] or {}) do callback(ev) end
end

local function findHook(mod, name, priority)
  for _, entry in ipairs(mod._hooks[name] or {}) do
    if not priority or entry.priority == priority then return entry.callback end
  end
  error("missing hook " .. name .. " at priority " .. tostring(priority))
end

-- Gen 1: the temporary type list is a true active-battler override and resets
-- to the original Bug/Ghost types whenever its owner leaves the field.
do
  local mod = makeMod()
  local state = BattleItems.installGen1(mod, "SHEDINJA", "ELEC_TERA_ORB", "AIR_BALLOON")
  local player = { mon = { species = "SHEDINJA" }, curTypes = { "BUG", "GHOST" } }
  local enemy = { mon = { species = "RATTATA" }, curTypes = { "NORMAL" } }
  local battle = { player = player, enemy = enemy, sides = { {}, {} } }
  emit(mod, "battle.started", { battle = battle })

  local ok = state.activate(battle, "ELEC_TERA_ORB")
  assert(ok, "active player Shedinja must activate the Electric Tera Orb")
  assert(#player.curTypes == 1 and player.curTypes[1] == "ELECTRIC",
    "Gen 1 Orb activation must replace the active type list")
  assert(not state.activate(battle, "ELEC_TERA_ORB"),
    "the Orb must be limited to one activation per field entry")
  assert(state.activate(battle, "AIR_BALLOON"),
    "the Air Balloon must activate independently after the Orb")
  assert(not state.activate(battle, "AIR_BALLOON"),
    "the Air Balloon must be limited to one activation per field entry")

  local accuracy = findHook(mod, "battle.accuracy", 150)
  assert(accuracy(function() return true end, {
    battle = battle, target = player, move = { type = "GROUND" },
  }) == false, "Air Balloon must stop Ground moves before damage")
  assert(accuracy(function() return true end, {
    battle = battle, target = player, move = { type = "FIRE" },
  }) == true, "Air Balloon must not stop non-Ground moves")

  emit(mod, "battle.battler_switched", {
    battle = battle, side = battle.sides[1], previous = player,
    battler = { mon = { species = "PIKACHU" } },
  })
  assert(player.curTypes[1] == "BUG" and player.curTypes[2] == "GHOST",
    "switching out must restore Gen 1 Shedinja's original types")
  battle.player = player
  assert(state.activate(battle, "ELEC_TERA_ORB"),
    "sending Shedinja back out must permit a new Orb activation")
  emit(mod, "battle.ended", { battle = battle })
  assert(player.curTypes[1] == "BUG" and player.curTypes[2] == "GHOST",
    "battle end must restore original Gen 1 types")

  battle.player = { mon = { species = "PIKACHU" }, curTypes = { "ELECTRIC" } }
  assert(not state.activate(battle, "ELEC_TERA_ORB"),
    "non-Shedinja must never activate either custom item")
end

-- Gold: the direct menu dispatcher is intentionally intercepted only for the
-- two current Shedinja item records, leaves the bag count untouched, and does
-- not submit a turn.
do
  local originalPackage = package.loaded["src.ui.gen2.BattleState"]
  local GoldBattleState = {
    useItem = function(self, itemId)
      self.nativeItem = itemId
      return "native"
    end,
  }
  package.loaded["src.ui.gen2.BattleState"] = GoldBattleState

  local mod = makeMod()
  local state = BattleItems.installGold(mod, "SHEDINJA", "ELEC_TERA_ORB", "AIR_BALLOON")
  local player = { species = "SHEDINJA" }
  local battle = { player = player, enemy = { species = "RATTATA" }, sides = { {}, {} } }
  emit(mod, "battle.started", { battle = battle })
  local screen = {
    battle = battle,
    game = { data = { items = {
      ELEC_TERA_ORB = { id = "ELEC_TERA_ORB" },
      AIR_BALLOON = { id = "AIR_BALLOON" },
    } } },
  }

  assert(GoldBattleState.useItem(screen, "ELEC_TERA_ORB") == true,
    "Gold dispatcher must activate the Orb without native useItem")
  assert(state.teraElectric(battle, player), "Gold Orb state must be battle-local")
  assert(screen.phase == "resolving" and screen.messageTimer == 1
      and #screen.queue == 0 and screen.nativeItem == nil,
    "Gold custom activation must return to resolving with no turn queued")
  assert(GoldBattleState.useItem(screen, "AIR_BALLOON") == true,
    "Gold dispatcher must activate the Balloon independently")
  assert(state.airBalloon(battle, player), "Gold Balloon state must be battle-local")
  assert(GoldBattleState.useItem(screen, "POTION") == "native" and screen.nativeItem == "POTION",
    "Gold dispatcher must leave every native item untouched")

  emit(mod, "battle.battler_switched", {
    battle = battle, side = battle.sides[1], previous = player,
    battler = { species = "PIKACHU" },
  })
  assert(not state.teraElectric(battle, player) and not state.airBalloon(battle, player),
    "Gold switch-out must clear both temporary item states")

  package.loaded["src.ui.gen2.BattleState"] = originalPackage
end

print("battle item tests passed")
