local root = arg[1] or "."
package.path = "/home/ubuntu/reference_gen1recomp0210_source/?.lua;/home/ubuntu/reference_gen1recomp0210_source/?/init.lua;" .. package.path

local Manifest = require("src.mods.Manifest")
local ModTargets = require("src.mods.ModTargets")
local raw = {
  id = "shedinja",
  name = "Shedinja",
  version = "0.3.0",
  github = "inmento/Shedinja",
  api = 2,
  entry = "main.lua",
  profile = "overhaul",
  category = "GAMEPLAY",
  permissions = { "engine_internals" },
  games = { "gen1", "gen2" },
  optional_dependencies = {
    {
      id = "shedinja_expanded_bridge",
      range = ">=0.1.4 <1.0.0",
      games = { "gen1", "gen2" },
      github = "inmento/Shedinja-Expanded-Bridge",
    },
    {
      id = "CRYSTAL_251",
      range = ">=0.11.3 <1.0.0",
      games = { "gen1" },
      github = "Deftones565/gen1recomp-mod-crystal-251",
    },
  },
  game_version = ">=0.2.3 <1.0.0",
  incompatible = { "Kanto-Reforged" },
  affects_link = true,
  description = "Standalone Shedinja expansion for Red/Blue/Yellow and Gold.",
}
local manifest = Manifest.validate(raw, root)
assert(manifest.id == "shedinja")
assert(manifest.version == "0.3.0", "manifest must carry the corrected package-identity migration")
assert(manifest.github == "inmento/Shedinja",
  "manifest must declare the repository used by launcher updates")
assert(manifest.gen2compat == true,
  "manifest must declare Gold compatibility")
assert(#manifest.conflicts == 1 and manifest.conflicts[1] == "Kanto-Reforged",
  "Crystal 251 must no longer be a core Shedinja conflict")
assert(#manifest.optionalSpecs == 2,
  "Shedinja must declare both game-scoped bridges as optional ordering sources")
local goldBridge, crystal
for _, spec in ipairs(manifest.optionalSpecs) do
  if spec.id == "shedinja_expanded_bridge" then goldBridge = spec end
  if spec.id == "CRYSTAL_251" then crystal = spec end
end
assert(goldBridge and goldBridge.github == "inmento/Shedinja-Expanded-Bridge"
  and ModTargets.specApplies(goldBridge, "gold", 2)
  and ModTargets.specApplies(goldBridge, "red", 1),
  "Unified bridge relationship must apply in both Gen 1 and Gold")
assert(crystal and crystal.github == "Deftones565/gen1recomp-mod-crystal-251"
  and ModTargets.specApplies(crystal, "red", 1)
  and not ModTargets.specApplies(crystal, "gold", 2),
  "Crystal 251 relationship must remain Gen 1-scoped and repository-hinted")
print("Shedinja v0.2.10 engine manifest test passed")
