local root = assert(arg[1], "project root is required")

local registered, patched, ready = {}, {}, nil
local function registry()
  return {
    register = function(_, id, value) registered[id] = value end,
    patch = function(_, id, value) patched[id] = value end,
  }
end

package.preload["src.core.GameVersion"] = function()
  return { get = function() return "red" end }
end
package.preload["mods.gen1_shedinja.wonder_guard"] = function()
  return { install = function(_, shedinjaId, itemId)
    assert(shedinjaId == "SHEDINJA")
    assert(itemId == "WONDER_GUARD")
  end }
end
package.preload["mods.gen1_shedinja.encounters"] = function()
  return { install = function(_, shedinjaId)
    assert(shedinjaId == "SHEDINJA")
  end }
end

_G.mod = {
  content = {
    constants = registry(),
    items = registry(),
    text = registry(),
    cries = registry(),
    pokemon = registry(),
  },
  events = {
    on = function(_, name, callback)
      assert(name == "game.ready")
      ready = callback
    end,
  },
  hooks = { wrap = function() end },
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
assert(shedinja.trueColor == true, "Shedinja sprite art must opt out of 4-shade recoloring")
local unusedCry = assert(registered.SHEDINJA_UNUSED_CRY_43,
  "Shedinja's dedicated unused $43 cry was not registered")
assert(unusedCry.base == "NIDORAN_M" and unusedCry.pitch == 128 and unusedCry.length == 16,
  "unused $43 cry must preserve base 0, pitch 128, and length 16")
assert(shedinja.cry == "SHEDINJA_UNUSED_CRY_43",
  "Shedinja must point only to its dedicated unused $43 cry")
assert(registered.NIDORAN_M == nil and patched.NIDORAN_M == nil,
  "the native base-0 Nidoran cry/species must not be modified")
assert(type(ready) == "function", "game.ready grant handler was not registered")

local game = { save = { inventory = {} } }
ready({ game = game })
assert(game.save.inventory.WONDER_GUARD == 1, "Wonder Guard was not granted")
ready({ game = game })
assert(game.save.inventory.WONDER_GUARD == 1, "Wonder Guard grant duplicated")

print("main content tests passed")
