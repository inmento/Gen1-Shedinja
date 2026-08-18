local root = arg[1] or "."

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
package.preload["mods.GEN1_SHEDINJA.wonder_guard"] = function()
  return { install = function(_, shedinjaId, itemId)
    assert(shedinjaId == "SHEDINJA")
    assert(itemId == "WONDER_GUARD")
  end }
end

_G.mod = {
  content = {
    constants = registry(),
    items = registry(),
    text = registry(),
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

assert(dofile(root .. "/main.lua"))
assert(patched.dexSize == 152, "Pokédex size was not expanded to 152")
assert(registered.WONDER_GUARD and registered.WONDER_GUARD.tossable == false,
  "Wonder Guard item was not registered as a persistent token")
local shedinja = assert(registered.SHEDINJA, "Shedinja species was not registered")
assert(shedinja.dex == 152 and shedinja.index == 152, "Shedinja dex/index mismatch")
assert(shedinja.types[1] == "BUG" and shedinja.types[2] == "GHOST", "Shedinja must be Bug/Ghost")
assert(shedinja.baseStats.hp == 1, "Shedinja must retain base HP 1")
assert(shedinja.trueColor == true, "Shedinja sprite art must opt out of 4-shade recoloring")
assert(type(ready) == "function", "game.ready grant handler was not registered")

local game = { save = { inventory = {} } }
ready({ game = game })
assert(game.save.inventory.WONDER_GUARD == 1, "Wonder Guard was not granted")
ready({ game = game })
assert(game.save.inventory.WONDER_GUARD == 1, "Wonder Guard grant duplicated")

print("main content tests passed")
