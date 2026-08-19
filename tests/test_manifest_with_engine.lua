local root = arg[1] or "."
package.path = "/home/ubuntu/reference_gen1recomp0210_source/?.lua;/home/ubuntu/reference_gen1recomp0210_source/?/init.lua;" .. package.path

local Manifest = require("src.mods.Manifest")
local ModTargets = require("src.mods.ModTargets")
local raw = {
  id = "gen1_shedinja",
  name = "Shedinja",
  version = "0.1.11",
  github = "inmento/Gen1-Shedinja",
  api = 2,
  entry = "main.lua",
  profile = "overhaul",
  category = "GAMEPLAY",
  permissions = { "engine_internals" },
  games = { "gen1", "gen2" },
  optional_dependencies = {
    {
      id = "shedinja_expanded_bridge",
      range = ">=0.1.1 <1.0.0",
      games = { "gen2" },
      github = "inmento/Shedinja-Expanded-Bridge",
    },
  },
  game_version = ">=0.2.3 <1.0.0",
  incompatible = { "CRYSTAL_251", "Kanto-Reforged" },
  affects_link = true,
  description = "Standalone Shedinja expansion for Red/Blue/Yellow and Gold.",
}
local manifest = Manifest.validate(raw, root)
assert(manifest.id == "gen1_shedinja")
assert(manifest.version == "0.1.11", "manifest must retain the update-fix version")
assert(manifest.github == "inmento/Gen1-Shedinja",
  "manifest must declare the repository used by launcher updates")
assert(manifest.gen2compat == true,
  "manifest must declare Gold compatibility")
assert(#manifest.conflicts == 2, "known expansion conflicts were not retained")
assert(#manifest.optionalSpecs == 1, "Shedinja must declare the bridge as optional")
local bridge = manifest.optionalSpecs[1]
assert(bridge.id == "shedinja_expanded_bridge"
  and bridge.github == "inmento/Shedinja-Expanded-Bridge"
  and ModTargets.specApplies(bridge, "gold", 2)
  and not ModTargets.specApplies(bridge, "red", 1),
  "bridge relationship must remain Gold-scoped and repository-hinted")
print("Shedinja v0.2.10 engine manifest test passed")
