local root = assert(arg[1], "project root is required")
local engineRoot = arg[2] or "/home/ubuntu/reference_gen1recomp0210_source"
package.path = engineRoot .. "/?.lua;" .. engineRoot .. "/?/init.lua;" .. package.path

local Schemas = require("src.mods.Schemas")
local cry = { base = "NIDORAN_M", pitch = 128, length = 16 }
local ok, err = Schemas.check(Schemas.GEN1.cries, "cries", "SHEDINJA_UNUSED_CRY_43",
  cry, "register", 1)
assert(ok, err)
assert(cry.base == "NIDORAN_M" and cry.pitch == 128 and cry.length == 16,
  "the engine-validated cry record did not retain raw $43 values")


print("engine cry schema test passed")
