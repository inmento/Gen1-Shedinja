local root = assert(arg[1], "project root is required")

package.preload["src.core.GameVersion"] = function()
  return {
    get = function() return "silver" end,
    generation = function(id)
      assert(id == "silver", "Shedinja must classify the active Silver version")
      return 2
    end,
  }
end

local installed = false
package.preload["mods.shedinja.gold"] = function()
  return {
    install = function(mod, speciesId, itemId, teraItemId, balloonItemId)
      installed = true
      assert(speciesId == "SHEDINJA")
      assert(itemId == "WONDER_GUARD")
      assert(teraItemId == "ELEC_TERA_ORB")
      assert(balloonItemId == "AIR_BALLOON")
      return {
        SHEDINJA = speciesId,
        WONDER_GUARD = itemId,
        marker = "silver-entry-exports",
      }
    end,
  }
end

local mod = { exports = {} }
local init = assert(dofile(root .. "/main.lua"), "Shedinja entry module did not return an initializer")
local returned = assert(init(mod), "Silver Shedinja initializer failed")
assert(installed, "Silver must invoke the shared Gen 2 installer")
assert(returned == mod.exports, "Silver entry must return the API 2 export table")
assert(mod.exports.SHEDINJA == "SHEDINJA" and mod.exports.WONDER_GUARD == "WONDER_GUARD",
  "Silver core exports must publish the bridge-facing Shedinja handles")
assert(mod.exports.marker == "silver-entry-exports",
  "Silver installer exports must be copied into the API 2 export table")

print("Silver Shedinja entry export harness: valid")
