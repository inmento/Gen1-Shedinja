local root = arg[1] or "."
package.path = "/home/ubuntu/reference_gen1recomp023_source/?.lua;/home/ubuntu/reference_gen1recomp023_source/?/init.lua;" .. package.path

local Manifest = require("src.mods.Manifest")
local raw = {
  id = "gen1_shedinja",
  name = "Gen 1 Shedinja",
  version = "0.1.5",
  api = 2,
  entry = "main.lua",
  profile = "overhaul",
  category = "GAMEPLAY",
  permissions = { "engine_internals" },
  game_version = ">=0.2.3 <1.0.0",
  incompatible = { "CRYSTAL_251", "Kanto-Reforged" },
  affects_link = true,
  description = "Standalone Gen 1 Shedinja expansion.",
}
local manifest = Manifest.validate(raw, root)
assert(manifest.id == "gen1_shedinja")
assert(manifest.gen2compat == false,
  "manifest must remain Gen 1-only")
assert(#manifest.conflicts == 2, "known expansion conflicts were not retained")
print("engine manifest test passed")
