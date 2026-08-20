local root = assert(arg[1], "project root is required")

local registered, patched, callbacks, wraps = {}, {}, {}, {}
local function registry()
  return {
    register = function(_, id, value) registered[id] = value end,
    patch = function(_, id, value) patched[id] = value end,
  }
end

local registeredIcons = {}
local function iconRegistry()
  return {
    register = function(_, id, value) registeredIcons[id] = value end,
    override = function() error("Gen 1 Shedinja must register its icon directly on the species ID") end,
  }
end

package.preload["src.core.GameVersion"] = function()
  return { get = function() return "red" end }
end
package.preload["mods.shedinja.wonder_guard"] = function()
  return { install = function(_, shedinjaId, itemId)
    assert(shedinjaId == "SHEDINJA")
    assert(itemId == "WONDER_GUARD")
  end }
end
package.preload["mods.shedinja.battle_items"] = function()
  return { installGen1 = function(_, shedinjaId, teraItemId, balloonItemId)
    assert(shedinjaId == "SHEDINJA")
    assert(teraItemId == "ELEC_TERA_ORB" and balloonItemId == "AIR_BALLOON")
  end }
end
package.preload["mods.shedinja.encounters"] = function()
  return { install = function(_, shedinjaId)
    assert(shedinjaId == "SHEDINJA")
  end }
end
package.preload["src.battle.Timing"] = function()
  return { hpBarPixels = function(hp, maxHp)
    assert(maxHp == 1, "Shedinja battler HP bar must use max HP 1")
    return hp > 0 and 48 or 0
  end }
end
local battleState = {
  newWild = function(game, species, level)
    local mon = { species = species, level = level, hp = 99, stats = { hp = 99 } }
    return { data = game.data, enemy = { mon = mon, shownHP = 99, shownPx = 48 } }
  end,
}
package.preload["src.battle.BattleState"] = function() return battleState end

_G.mod = {
  path = root,
  find = function() return nil end,
  content = {
    constants = registry(),
    items = registry(),
    text = registry(),
    cries = registry(),
    icons = iconRegistry(),
    pokemon = registry(),
  },
  events = {
    on = function(_, name, callback)
      callbacks[name] = callback
    end,
  },
  hooks = { wrap = function(_, name, callback, priority)
    wraps[name] = { callback = callback, priority = priority }
  end },
  exports = {},
}

local init = assert(dofile(root .. "/main.lua"), "Shedinja entry module did not return an initializer")
assert(type(init) == "function", "Shedinja entry module must return an initializer")
assert(init(_G.mod), "Shedinja initializer failed")
assert(patched.dexSize == 292, "Pokédex size was not expanded to National Dex #292")
assert(registered.WONDER_GUARD and registered.WONDER_GUARD.tossable == false,
  "Wonder Guard item was not registered as a persistent token")
local shedinja = assert(registered.SHEDINJA, "Shedinja species was not registered")
assert(shedinja.dex == 292 and shedinja.index == 152,
  "Shedinja must retain internal slot 152 while displaying National Dex #292")
assert(shedinja.types[1] == "BUG" and shedinja.types[2] == "GHOST", "Shedinja must be Bug/Ghost")
assert(shedinja.spriteFront == root .. "/assets/sprites/shedinja_front.png"
  and shedinja.spriteBack == root .. "/assets/sprites/shedinja_back.png",
  "Gen 1 Oak and Dex screens must receive mounted Shedinja portrait paths")
assert(shedinja.dexEntry.kind == "BUG/GHOST",
  "Gen 1 Shedinja Dex category must display BUG/GHOST rather than SHED")
local icon = assert(registeredIcons.SHEDINJA,
  "Gen 1 Shedinja party icon was not registered directly on the species ID")
assert(icon.image == root .. "/assets/sprites/shedinja_icon.png" and icon.frames == 2,
  "Gen 1 Shedinja party icon must use the mounted two-frame icon sheet")
local dexText = assert(registered.GEN1_SHEDINJA_DEX, "Shedinja Dex text was not registered")
local expectedDexLines = {
  "HOLLOW BUG SHELL.", "LEGEND SAYS IT", "STEALS THE SPIRIT", "OF THOSE WHO PEEK",
}
local lineCount = 0
for line in (dexText .. "\n"):gmatch("(.-)\n") do
  lineCount = lineCount + 1
  assert(#line <= 18, "Shedinja Dex text exceeds the 18-column entry width")
end
assert(lineCount == 4, "Shedinja Dex text must stay on one four-line page")
assert(dexText == table.concat(expectedDexLines, "\n"),
  "Shedinja Dex text must use its approved explicit line breaks")
assert(shedinja.baseStats.hp == 1, "Shedinja must retain base HP 1")
assert(shedinja.battleScaleBack == 1,
  "Gen 1 Shedinja player-back art must override the default 2x battle scale")
assert(shedinja.battleScaleFront == 0.6,
  "Gen 1 Shedinja enemy-front art must fit the ordinary opponent slot")
assert(shedinja.trueColor == true, "Shedinja sprite art must opt out of 4-shade recoloring")
local unusedCry = assert(registered.SHEDINJA_UNUSED_CRY_43,
  "Shedinja's dedicated unused $43 cry was not registered")
assert(unusedCry.base == "NIDORAN_M" and unusedCry.pitch == 128 and unusedCry.length == 16,
  "unused $43 cry must preserve base 0, pitch 128, and length 16")
assert(shedinja.cry == "SHEDINJA_UNUSED_CRY_43",
  "Shedinja must point only to its dedicated unused $43 cry")
assert(registered.NIDORAN_M == nil and patched.NIDORAN_M == nil,
  "the native base-0 Nidoran cry/species must not be modified")
assert(mod.exports.SHEDINJA == "SHEDINJA",
  "API 2 core exports must publish SHEDINJA for the compatibility bridge")
assert(type(mod.exports.normalizeHp) == "function" and type(mod.exports.normalizeSaveHp) == "function",
  "core HP repair helpers must be exported for bridge-safe lifecycle checks")
assert(type(callbacks["game.ready"]) == "function", "game.ready grant handler was not registered")
assert(type(callbacks["battle.started"]) == "function"
  and type(callbacks["battle.battler_switched"]) == "function"
  and type(callbacks["battle.ended"]) == "function",
  "Shedinja battle HP repair lifecycle handlers were not registered")
assert(type(wraps["pokemon.sprite"]) == "table" and wraps["pokemon.sprite"].priority == 100,
  "Shedinja front/back sprite resolver must be installed at final presentation priority")
assert(type(wraps["script.command"]) == "table" and wraps["script.command"].priority == -20000,
  "post-gift Shedinja repair hook was not registered")
assert(battleState._shedinjaOneHpWildFactory == true,
  "Gen 1 wild battle factory must be wrapped for pre-HUD Shedinja normalization")

local data = { pokemon = { SHEDINJA = shedinja } }
local starter = { species = "SHEDINJA", level = 5, hp = 16, stats = { hp = 16 } }
local boxed = { species = "SHEDINJA", level = 5, hp = 16, stats = { hp = 16 } }
local fainted = { species = "SHEDINJA", level = 5, hp = 0, stats = { hp = 16 } }
local game = { data = data, save = { inventory = {}, party = { starter, fainted }, boxes = { { boxed } } } }
callbacks["game.ready"]({ game = game })
assert(game.save.inventory.WONDER_GUARD == 1, "Wonder Guard was not granted")
assert(game.save.inventory.ELEC_TERA_ORB == 1 and game.save.inventory.AIR_BALLOON == 1,
  "battle-only Shedinja items were not granted")
assert(starter.hp == 1 and starter.stats.hp == 1,
  "starter Shedinja must be normalized to 1 current and maximum HP")
assert(boxed.hp == 1 and boxed.stats.hp == 1,
  "boxed Shedinja must be normalized to 1 current and maximum HP")
assert(fainted.hp == 0 and fainted.stats.hp == 1,
  "a fainted Shedinja must retain 0 current HP while its maximum becomes 1")

local front = wraps["pokemon.sprite"].callback(function(path) return "next/" .. path end,
  "fallback.png", { species = "SHEDINJA", side = "front", kind = "dex" })
local back = wraps["pokemon.sprite"].callback(function(path) return "next/" .. path end,
  "fallback.png", { species = "SHEDINJA", side = "back", kind = "battle" })
assert(front == root .. "/assets/sprites/shedinja_front.png",
  "Shedinja portrait callers must receive the front sprite")
assert(back == root .. "/assets/sprites/shedinja_back.png",
  "player-side Shedinja battle callers must receive the back sprite")

local gifted = { species = "SHEDINJA", level = 5, hp = 16, stats = { hp = 16 } }
game.save.party = { gifted }
game.save.inventory = {}
wraps["script.command"].callback(function() return true end,
  { game = game }, "give_pokemon", {}, {})
assert(gifted.hp == 1 and gifted.stats.hp == 1,
  "a newly given Shedinja must be normalized immediately after insertion")
assert(game.save.inventory.WONDER_GUARD == 1,
  "a newly given Shedinja must receive WONDER GUARD before control returns")

local enemyMon = { species = "SHEDINJA", level = 20, hp = 50, stats = { hp = 50 } }
local enemy = { mon = enemyMon }
callbacks["battle.started"]({ battle = { data = data, enemy = enemy } })
assert(enemyMon.hp == 1 and enemyMon.stats.hp == 1 and enemy.shownHP == 1,
  "enemy battle Shedinja must be normalized to 1 HP at battle start")

local wildBattle = battleState.newWild(game, "SHEDINJA", 8)
assert(wildBattle.enemy.mon.hp == 1 and wildBattle.enemy.mon.stats.hp == 1
  and wildBattle.enemy.shownHP == 1 and wildBattle.enemy.shownPx == 48,
  "wild Shedinja must be normalized before its initial battle HUD is created")
local ordinaryWild = battleState.newWild(game, "SQUIRTLE", 8)
assert(ordinaryWild.enemy.mon.hp == 99 and ordinaryWild.enemy.mon.stats.hp == 99,
  "wild HP normalization must not affect another species")

local leveling = { species = "SHEDINJA", level = 25, hp = 26, stats = { hp = 26 } }
callbacks["pokemon.level_up"]({ mon = leveling })
assert(leveling.hp == 1 and leveling.stats.hp == 1,
  "Shedinja HP must return to 1 immediately after level-up stat recalculation")
local otherLeveling = { species = "SQUIRTLE", level = 25, hp = 62, stats = { hp = 62 } }
callbacks["pokemon.level_up"]({ mon = otherLeveling })
assert(otherLeveling.hp == 62 and otherLeveling.stats.hp == 62,
  "level-up normalization must not affect another species")

print("main content tests passed")
