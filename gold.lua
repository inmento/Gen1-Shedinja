-- Gold-specific content for the standalone Shedinja package.
--
-- This module deliberately contains no Gen 1 registration or state changes.
-- Gold has a distinct species schema, a held-item system, and a GBC palette
-- renderer, so keeping its work here prevents either generation from leaking
-- into the other.

local Gold = {}

local FRONT_FRAMES = {
  "assets/gen2/shedinja_front_1.png",
  "assets/gen2/shedinja_front_2.png",
  "assets/gen2/shedinja_front_3.png",
}
local BACK_FRAME = "assets/gen2/shedinja_back.png"
local ICON_FRAME = "assets/gen2/shedinja_icon.png"
local ICON_ID = "ICON_GEN1_SHEDINJA"

-- Crystal's `anim.asm` holds frames 1, 2, and 3 for 6, 32, and 10 sixty-Hz
-- ticks. Gold re-resolves pokemon.sprite every draw, so a wall-clock path
-- sequence recreates that one-pass entrance animation without replacing an
-- engine animation routine.
local FRAME_DURATIONS = { 6 / 60, 32 / 60, 10 / 60 }
local ANIMATION_LENGTH = FRAME_DURATIONS[1] + FRAME_DURATIONS[2] + FRAME_DURATIONS[3]

local NORMAL_PALETTE = {
  { 255, 255, 255 }, { 214, 165, 41 }, { 115, 90, 58 }, { 0, 0, 0 },
}
local SHINY_PALETTE = {
  { 255, 255, 255 }, { 230, 173, 115 }, { 107, 82, 74 }, { 0, 0, 0 },
}

local DEX_ENTRY = {
  dex = 292,
  kind = "SHED POKEMON",
  -- Gold stores height as the four printed digits (2'07") and weight in lb.
  height = 207,
  weight = 26,
  text = "HOLLOW BUG SHELL.<NEXT>LEGEND SAYS IT<NEXT>STEALS THE SPIRIT",
  text2 = "OF THOSE WHO PEEK.<NEXT>IT NEVER EATS<NEXT>OR BREATHES.",
}

local function elapsedTime()
  if love and love.timer and love.timer.getTime then
    return love.timer.getTime()
  end
  return 0
end

local function frameAt(elapsed)
  if elapsed >= ANIMATION_LENGTH then return #FRONT_FRAMES end
  if elapsed < FRAME_DURATIONS[1] then return 1 end
  if elapsed < FRAME_DURATIONS[1] + FRAME_DURATIONS[2] then return 2 end
  return 3
end

local function erraticExperience(level)
  local n = math.max(1, math.floor(level or 1))
  if n == 1 then return 0 end
  if n <= 50 then return n * n * n * (100 - n) / 50 end
  if n <= 68 then return n * n * n * (150 - n) / 100 end
  if n <= 98 then return n * n * n * (1911 - 10 * n) / 1500 end
  return n * n * n * (160 - n) / 100
end

local function grantBattleItems(save, teraItemId, balloonItemId)
  if not save then return end
  save.inventory = save.inventory or {}
  if not save.inventory[teraItemId] then save.inventory[teraItemId] = 1 end
  if not save.inventory[balloonItemId] then save.inventory[balloonItemId] = 1 end
end

local function injectDexEntry(game, speciesId)
  local data = game and game.data
  local dex = data and data.gen2Pokedex
  if not dex then return end
  dex.entries = dex.entries or {}
  if dex.entries[speciesId] then return end

  local entry = {}
  for key, value in pairs(DEX_ENTRY) do entry[key] = value end
  dex.entries[speciesId] = entry
end

-- Base HP 1 alone follows Gold's ordinary stat formula, which produces 15–16
-- HP at level 5. Shedinja's defining rule is stricter: its maximum HP is one
-- at every level. Preserve a fainted record at zero HP rather than reviving it
-- while normalizing a save or a post-script gift.
local function normalizeShedinjaHp(mon, speciesId)
  if type(mon) ~= "table" or mon.species ~= speciesId then return false end
  mon.stats = mon.stats or {}
  mon.stats.hp = 1
  mon.maxHp = 1
  mon.hp = (tonumber(mon.hp) or 1) <= 0 and 0 or 1
  return true
end

local function normalizeSaveShedinjaHp(save, speciesId)
  if type(save) ~= "table" then return 0 end
  local changed = 0
  local function inspect(list)
    for _, mon in ipairs(type(list) == "table" and list or {}) do
      if normalizeShedinjaHp(mon, speciesId) then changed = changed + 1 end
    end
  end
  inspect(save.party)
  for _, box in pairs(save.boxes or {}) do inspect(box) end
  return changed
end

local ELM_REWARD_KEY = "gold_elm_shedinja_reward_claimed"

local function ownsWonderGuardShedinja(save, speciesId, itemId)
  if type(save) ~= "table" then return false end
  local function inspect(list)
    for _, mon in ipairs(type(list) == "table" and list or {}) do
      if mon.species == speciesId and mon.item == itemId then return true end
    end
    return false
  end
  if inspect(save.party) then return true end
  for _, box in pairs(save.boxes or {}) do
    if inspect(box) then return true end
  end
  return false
end

local function itemIndex(game, itemId)
  local items = game and game.data and game.data.items or {}
  local direct = items[itemId]
  if type(direct) == "table" and type(direct.index) == "number" then return direct.index end
  for id, record in pairs(items) do
    if id == itemId or (type(record) == "table" and record.id == itemId) then
      return type(record) == "table" and record.index or nil
    end
  end
  return nil
end

local function giveElmShedinja(game, speciesId, itemId)
  local save = game and game.save
  local data = game and game.data
  if not (save and data) then return nil, "The gift could not be prepared." end

  local Mon = require("src.battle.gen2.Mon")
  local Party = require("src.pokemon.Party")
  local Boxes = require("src.pokemon.Boxes")
  local mon = Mon.new(data, speciesId, 5, { item = itemId })
  if not mon then return nil, "The rift closed before the POKéMON could arrive." end
  Mon.stampOT(save, mon)
  save.party = save.party or {}
  local addedToParty = Party.add(save.party, mon)
  local boxNum
  if not addedToParty then
    boxNum = Boxes.deposit(save, mon)
    if not boxNum then return nil, "Please make room for the\nPOKéMON first." end
  end

  save.pokedex = save.pokedex or { seen = {}, caught = {} }
  save.pokedex.seen = save.pokedex.seen or {}
  save.pokedex.caught = save.pokedex.caught or {}
  save.pokedex.seen[speciesId] = true
  save.pokedex.caught[speciesId] = true
  normalizeShedinjaHp(mon, speciesId)
  return mon, boxNum
end

local function queueElmReward(mod, game, speciesId, itemId)
  if not (game and game.stack) then return false end
  local TextBox = require("src.render.TextBox")
  local claimed = mod.save and mod.save:get(ELM_REWARD_KEY)
  if claimed then return false end

  local lines = {
    "While PROF. ELM dealt\nwith the robbery,\na rift opened.",
    "A strange POKéMON\ncame through. ELM\nwants you to have it.",
  }
  local function show(index)
    if lines[index] then
      game.stack:push(TextBox.new(game, lines[index], function() show(index + 1) end))
      return
    end
    local mon, boxNumOrError = giveElmShedinja(game, speciesId, itemId)
    if not mon then
      game.stack:push(TextBox.new(game, boxNumOrError, function() end))
      return
    end
    if mod.save then mod.save:set(ELM_REWARD_KEY, true) end
    local destination = boxNumOrError and ("SHEDINJA was sent\nto BOX " .. tostring(boxNumOrError) .. "!")
      or "You received\nSHEDINJA!"
    game.stack:push(TextBox.new(game,
      destination .. "\nIt is holding WONDER\nGUARD.", function() end))
  end
  show(1)
  return true
end

function Gold.install(mod, speciesId, itemId, teraItemId, balloonItemId)
  -- Gold contains the four original Gen 2 experience curves only. Shedinja's
  -- Gen III Erratic curve is supplied as a small local registry record rather
  -- than silently falling back to Medium Fast.
  mod.content.growth_rates:register("ERRATIC", {
    expForLevel = function(level)
      return math.max(0, math.floor(erraticExperience(level)))
    end,
  })

  -- Shedinja occupies the first free internal Gold species index. Its public
  -- National Dex number remains 292, matching the Gen 1 branch and all later
  -- official games.
  mod.content.constants:patch("dexSize", 292)
  mod.content.pokemon:register(speciesId, {
    id = speciesId,
    index = 252,
    dex = 292,
    name = "SHEDINJA",
    types = { "BUG", "GHOST" },
    baseStats = {
      hp = 1,
      attack = 90,
      defense = 45,
      speed = 40,
      specialAttack = 30,
      specialDefense = 30,
    },
    catchRate = 45,
    baseExp = 95,
    growthRate = "ERRATIC",
    picSize = 6,
    -- Static Gold screens (Elm's pokepic preview, Summary, and trades) load
    -- these fields directly and do not invoke pokemon.sprite. Use mounted
    -- absolute asset paths here; the battle hook below only replaces the front
    -- path with time-indexed frames during battle.
    spriteFront = mod.path .. "/" .. FRONT_FRAMES[1],
    spriteBack = mod.path .. "/" .. BACK_FRAME,
    levelMoves = {
      { level = 1, move = "SCRATCH" },
      { level = 1, move = "HARDEN" },
      { level = 5, move = "LEECH_LIFE" },
      { level = 9, move = "SAND_ATTACK" },
      { level = 14, move = "FURY_SWIPES" },
      { level = 19, move = "MIND_READER" },
      { level = 25, move = "SPITE" },
      { level = 31, move = "CONFUSE_RAY" },
      { level = 38, move = "SHADOW_BALL" },
      -- GRUDGE was introduced in Generation III and is absent from Gold and
      -- Silver's move registry. DESTINY_BOND is the legal Generation II
      -- Ghost move for this late-game thematic slot.
      { level = 45, move = "DESTINY_BOND" },
    },
    evolutions = {},
    eggGroups = { "EGG_MINERAL", "EGG_MINERAL" },
    eggSteps = 15,
    genderRatio = 255,
  })

  -- Gold's party list uses a dedicated 16x32 two-frame icon sheet rather
  -- than a battle or summary sprite. Register the static Shedinja icon before
  -- associating it with the species so party, PC, and selection menus do not
  -- fall back to an empty slot.
  mod.content.icons:register(ICON_ID, {
    image = mod.path .. "/" .. ICON_FRAME,
    width = 16,
    height = 32,
    frames = 2,
  })
  mod.content.icons:override(speciesId, ICON_ID)

  -- The PNG frames are four grayscale source shades. Gold's sprite renderer
  -- applies one of these registered palette rows at draw time, so shininess
  -- follows the actual mon.shiny flag without separate shiny art files.
  mod.content.palettes:patch("pokemon", {
    [speciesId] = { normal = NORMAL_PALETTE, shiny = SHINY_PALETTE },
  })

  -- The native bag must be able to offer GIVE. In Gold, non-tossable items are
  -- key-item-style rows and intentionally never offer it, so Wonder Guard is a
  -- non-usable normal item that the player may give, take, or discard.
  mod.content.items:register(itemId, {
    id = itemId,
    name = "WONDER GUARD",
    price = 0,
    tossable = true,
    needsTarget = false,
  })

  -- These permanent Key Items are selectable in the battle Pack but have no
  -- field effect. The module-specific BattleState handler supplies their free,
  -- active-Shedinja-only behavior during battle.
  mod.content.items:register(teraItemId, {
    id = teraItemId,
    name = "ELEC TERA ORB",
    price = 0,
    pocket = "KEY_ITEM",
    tossable = false,
    needsTarget = false,
    battleMenu = "ITEMMENU_PARTY",
    fieldMenu = "ITEMMENU_NOUSE",
  })
  mod.content.items:register(balloonItemId, {
    id = balloonItemId,
    name = "AIR BALLOON",
    price = 0,
    pocket = "KEY_ITEM",
    tossable = false,
    needsTarget = false,
    battleMenu = "ITEMMENU_PARTY",
    fieldMenu = "ITEMMENU_NOUSE",
  })

  local animationStart = setmetatable({}, { __mode = "k" })
  mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
    if ctx and ctx.kind == "battle" and ctx.species == speciesId and ctx.side == "front" then
      local mon = ctx.mon
      -- Gold battle contexts always carry the battler's mon. Keep the fallback
      -- defensive for future callers that may ask for a battle-front path
      -- before a battler has been constructed.
      if type(mon) ~= "table" then
        return mod.path .. "/" .. FRONT_FRAMES[frameAt(elapsedTime())]
      end
      local start = animationStart[mon]
      if start == nil then
        start = elapsedTime()
        animationStart[mon] = start
      end
      return mod.path .. "/" .. FRONT_FRAMES[frameAt(elapsedTime() - start)]
    end
    return next(path, ctx)
  end, 50)

  local battleItems = require("mods.shedinja.battle_items").installGold(
    mod, speciesId, teraItemId, balloonItemId)
  require("mods.shedinja.wonder_guard").installGold(
    mod, speciesId, itemId, battleItems)
  require("mods.shedinja.encounters").installGold(mod, speciesId, function()
    return ownsWonderGuardShedinja(mod.game and mod.game.save, speciesId, itemId)
  end)

  local function normalizeEvent(ev)
    local game = ev and (ev.game or (ev.ctx and ev.ctx.game)) or mod.game
    normalizeShedinjaHp(ev and (ev.mon or ev.pokemon), speciesId)
    normalizeSaveShedinjaHp(game and game.save, speciesId)
  end

  local pendingElmReward

  mod.events:on("game.ready", function(ev)
    local game = ev and ev.game
    normalizeSaveShedinjaHp(game and game.save, speciesId)
    grantBattleItems(game and game.save, teraItemId, balloonItemId)
    injectDexEntry(game, speciesId)
  end)

  -- Gold's ordinary monster constructor is intentionally shared by all
  -- species, so it cannot encode Shedinja's special one-HP rule. These
  -- post-construction boundaries cover wild catches, link/trade receipts,
  -- level-up stat refreshes, and scripted gifts such as an Elm starter.
  for _, eventName in ipairs({
    "pokemon.caught", "pokemon.received", "pokemon.level_up", "script.ended",
  }) do
    mod.events:on(eventName, normalizeEvent)
  end

  -- `Mon.new` applies the ordinary Gold stat formula before Battle exposes an
  -- enemy. Repair the live opponent after construction and again on a trainer
  -- send-out. The Gold battle object stores mons directly, while the shared
  -- event shape may carry a battler wrapper on other generations.
  local function normalizeEnemyBattler(event)
    local battle = event and event.battle
    local mon = event and event.battler or (battle and battle.enemy)
    mon = mon and (mon.mon or mon)
    if battle and mon and mon == battle.enemy then
      normalizeShedinjaHp(mon, speciesId)
    end
  end

  mod.events:on("battle.started", normalizeEnemyBattler)
  mod.events:on("battle.battler_switched", normalizeEnemyBattler)

  -- Preserve Elm's native five Poké Balls. Once that exact post-Mystery-Egg
  -- command succeeds, wait for its script to complete before presenting the
  -- rift scene and gifting the held-item Shedinja. This deliberately avoids
  -- replacing the native story script or triggering from an unrelated ball.
  mod.hooks:wrap("script.command", function(next, ctx, name, args, cmd)
    local result = next(ctx, name, args, cmd)
    local game = mod.game
    local save = game and game.save
    local flags = save and save.flags
    local item = cmd and cmd.item
    local quantity = cmd and (cmd.quantity or (cmd.args and cmd.args[2])) or nil
    local pokeBallIndex = itemIndex(game, "POKE_BALL")
    local isNativeBallReward = (name == "giveitem" or name == "verbosegiveitem")
      and ctx and ctx.generation == 2 and ctx.mapId == "ELMS_LAB"
      and flags and flags.EVENT_GAVE_MYSTERY_EGG_TO_ELM == true
      and pokeBallIndex ~= nil and tonumber(item) == tonumber(pokeBallIndex)
      and tonumber(quantity or 1) == 5
      and ctx.vm and ctx.vm.scriptVar == 1
    if isNativeBallReward and not (mod.save and mod.save:get(ELM_REWARD_KEY)) then
      pendingElmReward = ctx
    end
    return result
  end, 75)

  mod.events:on("script.ended", function(ev)
    local ctx = ev and ev.ctx
    if pendingElmReward and ctx == pendingElmReward then
      pendingElmReward = nil
      if ev.completed then queueElmReward(mod, mod.game, speciesId, itemId) end
    end
  end)

  return {
    SHEDINJA = speciesId,
    WONDER_GUARD = itemId,
    ELEC_TERA_ORB = teraItemId,
    AIR_BALLOON = balloonItemId,
    injectDexEntry = function(game)
      injectDexEntry(game, speciesId)
    end,
    normalizeHp = function(mon)
      return normalizeShedinjaHp(mon, speciesId)
    end,
    normalizeSaveHp = function(save)
      return normalizeSaveShedinjaHp(save, speciesId)
    end,
  }
end

return Gold
