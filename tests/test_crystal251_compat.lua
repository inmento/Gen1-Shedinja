local root = arg[1] or "."

local registered, patched = {}, {}
local function registry()
  return {
    register = function(_, id, value) registered[id] = value end,
    patch = function(_, id, value) patched[id] = value end,
  }
end

package.preload["src.core.GameVersion"] = function()
  return { get = function() return "yellow" end }
end
package.preload["mods.shedinja.wonder_guard"] = function()
  return { install = function() end }
end
package.preload["mods.shedinja.battle_items"] = function()
  return { installGen1 = function() end }
end
package.preload["mods.shedinja.encounters"] = function()
  return { install = function() end }
end

local mod = {
  path = root,
  find = function(first, second)
    local id = second or first
    if id == "CRYSTAL_251" then return { exports = {} } end
    return nil
  end,
  content = {
    constants = registry(),
    items = registry(),
    text = registry(),
    cries = registry(),
    icons = { register = function() end, override = function() end },
    pokemon = registry(),
  },
  events = { on = function() end },
  hooks = { wrap = function() end },
}

local init = assert(dofile(root .. "/main.lua"))
assert(init(mod), "Crystal-aware core initialization failed")
local shedinja = assert(registered.SHEDINJA, "Shedinja species was not registered")
assert(shedinja.index == 252,
  "active Crystal 251 must move Shedinja out of its occupied index-152 slot")
assert(shedinja.dex == 292 and patched.dexSize == 292,
  "Crystal-aware core registration must retain National Dex #292")

print("Shedinja Crystal 251 core-compatibility harness: valid")
