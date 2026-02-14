-- Trainer mod for Balatro: in-run cheats, T key to open menu, unlock all / skip tutorials

local MOD_ID = 'trainer'

-- Register this mod (using Modlist API - no direct G.MODS edits)
Modlist.register(MOD_ID, {
  name = 'Trainer',
  enabled = true,
  settings_func = 'trainer_settings',
})

-- T key opens trainer in-game (using Modlist.patch - no direct Controller override)
Modlist.patch(Controller, "key_press_update", function(orig, self, key, dt)
  if key == 't' and G.MODS and G.MODS.registry and G.MODS.registry.trainer and G.MODS.registry.trainer.enabled then
    if G.STAGE == G.STAGES.RUN and not G.OVERLAY_MENU then
      G.FUNCS.trainer_settings()
      return
    end
  end
  return orig(self, key, dt)
end)

-- Unlock helpers: set flags on game data then save
local function trainer_save_progress()
  G:save_progress()
  G.FILE_HANDLER.force = true
  if set_discover_tallies then set_discover_tallies() end
end

local function trainer_unlock_all()
  for k, v in pairs(G.P_CENTERS) do
    if not v.wip and (string.find(k, '^j_') or string.find(k, '^b_') or string.find(k, '^v_') or v.set == 'Tarot' or v.set == 'Planet' or v.set == 'Spectral' or v.set == 'Booster' or v.set == 'Edition') then
      if v.unlocked ~= nil then v.unlocked = true end
      v.discovered = true
      v.alerted = true
    end
  end
  for k, v in pairs(G.P_BLINDS) do
    if not v.wip and not v.demo then v.discovered = true; v.alerted = true end
  end
  for k, v in pairs(G.P_TAGS) do
    if not v.wip and not v.demo then v.discovered = true; v.alerted = true end
  end
  for k, v in pairs(G.P_SEALS) do
    if not v.wip and not v.demo then v.discovered = true; v.alerted = true end
  end
  G.SETTINGS.tutorial_complete = true
  if G.SETTINGS.tutorial_progress and G.SETTINGS.tutorial_progress.completed_parts then
    for part in pairs(G.SETTINGS.tutorial_progress.completed_parts) do
      G.SETTINGS.tutorial_progress.completed_parts[part] = true
    end
  end
  trainer_save_progress()
end

local function trainer_skip_tutorials()
  G.SETTINGS.tutorial_complete = true
  if G.SETTINGS.tutorial_progress and G.SETTINGS.tutorial_progress.completed_parts then
    for part in pairs(G.SETTINGS.tutorial_progress.completed_parts) do
      G.SETTINGS.tutorial_progress.completed_parts[part] = true
    end
  end
  trainer_save_progress()
end

local function trainer_unlock_set(predicate)
  for k, v in pairs(G.P_CENTERS) do
    if not v.wip and predicate(k, v) then
      if v.unlocked ~= nil then v.unlocked = true end
      v.discovered = true
      v.alerted = true
    end
  end
  trainer_save_progress()
end

G.FUNCS.trainer_unlock_all = function()
  trainer_unlock_all()
end
G.FUNCS.trainer_skip_tutorials = function()
  trainer_skip_tutorials()
end
G.FUNCS.trainer_unlock_jokers   = function() trainer_unlock_set(function(k) return string.find(k, '^j_') end) end
G.FUNCS.trainer_unlock_tarots   = function() trainer_unlock_set(function(_, v) return v.set == 'Tarot' end) end
G.FUNCS.trainer_unlock_planets  = function() trainer_unlock_set(function(_, v) return v.set == 'Planet' end) end
G.FUNCS.trainer_unlock_spectrals= function() trainer_unlock_set(function(_, v) return v.set == 'Spectral' end) end
G.FUNCS.trainer_unlock_vouchers = function() trainer_unlock_set(function(k) return string.find(k, '^v_') end) end
G.FUNCS.trainer_unlock_boosters= function() trainer_unlock_set(function(_, v) return v.set == 'Booster' end) end
G.FUNCS.trainer_unlock_backs   = function() trainer_unlock_set(function(k) return string.find(k, '^b_') end) end
G.FUNCS.trainer_unlock_editions= function() trainer_unlock_set(function(_, v) return v.set == 'Edition' end) end
G.FUNCS.trainer_unlock_blinds   = function()
  for k, v in pairs(G.P_BLINDS) do
    if not v.wip and not v.demo then v.discovered = true; v.alerted = true end
  end
  trainer_save_progress()
end
G.FUNCS.trainer_unlock_tags    = function()
  for k, v in pairs(G.P_TAGS) do
    if not v.wip and not v.demo then v.discovered = true; v.alerted = true end
  end
  trainer_save_progress()
end
G.FUNCS.trainer_unlock_seals   = function()
  for k, v in pairs(G.P_SEALS) do
    if not v.wip and not v.demo then v.discovered = true; v.alerted = true end
  end
  trainer_save_progress()
end

-- In-run cheat wrappers: close overlay first, then run cheat next frame so G.HUD/dollar_UI etc. are valid
local function trainer_cheat_after_close(callback)
  G.FUNCS.exit_overlay_menu()
  G.E_MANAGER:add_event(Event({
    trigger = 'after',
    delay = 0.05,
    func = function()
      if G.STAGE == G.STAGES.RUN and callback then callback() end
      return true
    end
  }))
end

G.FUNCS.trainer_add_money    = function() trainer_cheat_after_close(function() ease_dollars(10) end) end
G.FUNCS.trainer_add_hand     = function() trainer_cheat_after_close(function() ease_hands_played(1) end) end
G.FUNCS.trainer_add_discard  = function() trainer_cheat_after_close(function() ease_discard(1) end) end
G.FUNCS.trainer_add_round    = function() trainer_cheat_after_close(function() ease_round(1) end) end
G.FUNCS.trainer_add_ante     = function() trainer_cheat_after_close(function() ease_ante(1) end) end
G.FUNCS.trainer_add_chips    = function() trainer_cheat_after_close(function() update_hand_text({delay = 0}, {chips = 10 + G.GAME.current_round.current_hand.chips}); play_sound('chips1') end) end
G.FUNCS.trainer_add_mult     = function() trainer_cheat_after_close(function() update_hand_text({delay = 0}, {mult = 10 + G.GAME.current_round.current_hand.mult}); play_sound('multhit1') end) end
G.FUNCS.trainer_reroll_boss  = function() trainer_cheat_after_close(function() if G.blind_select_opts then G.from_boss_tag = true; G.FUNCS.reroll_boss(); G.from_boss_tag = nil end end) end
G.FUNCS.trainer_win_game     = function() trainer_cheat_after_close(function() win_game() end) end
G.FUNCS.trainer_lose_game    = function() trainer_cheat_after_close(function() G.STATE = G.STATES.GAME_OVER; G.STATE_COMPLETE = false end) end

local function create_UIBox_trainer_settings()
  local in_run = G.STAGE == G.STAGES.RUN
  local contents = {
    {n = G.UIT.R, config = {align = "cm", padding = 0.12}, nodes = {
      {n = G.UIT.T, config = {text = "Trainer", scale = 0.55, colour = G.C.WHITE, shadow = true}}
    }},
  }
  if not in_run then
    contents[#contents + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.05}, nodes = {
      {n = G.UIT.T, config = {text = "[T] opens this menu in-game", scale = 0.35, colour = G.C.WHITE, shadow = true}}
    }}
    -- Unlocks section (main menu / collection only)
    contents[#contents + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.08}, nodes = {
      {n = G.UIT.T, config = {text = "Unlocks & Tutorial", scale = 0.45, colour = G.C.ORANGE, shadow = true}}
    }}
    contents[#contents + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.06}, nodes = {
      UIBox_button{ label = {"Skip tutorials + unlock ALL"}, button = "trainer_unlock_all", minw = 3.2, minh = 0.55, scale = 0.36, colour = G.C.RED, text_colour = G.C.WHITE},
    }}
    contents[#contents + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.06}, nodes = {
      UIBox_button{ label = {"Skip tutorials only"}, button = "trainer_skip_tutorials", minw = 2.8, minh = 0.5, scale = 0.35, text_colour = G.C.WHITE},
    }}
    contents[#contents + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.05}, nodes = {
      UIBox_button{ label = {"All Jokers"}, button = "trainer_unlock_jokers", minw = 1.5, minh = 0.45, scale = 0.33, text_colour = G.C.WHITE},
      UIBox_button{ label = {"All Tarots"}, button = "trainer_unlock_tarots", minw = 1.5, minh = 0.45, scale = 0.33, text_colour = G.C.WHITE},
      UIBox_button{ label = {"All Planets"}, button = "trainer_unlock_planets", minw = 1.5, minh = 0.45, scale = 0.33, text_colour = G.C.WHITE},
      UIBox_button{ label = {"All Spectrals"}, button = "trainer_unlock_spectrals", minw = 1.5, minh = 0.45, scale = 0.33, text_colour = G.C.WHITE},
    }}
    contents[#contents + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.05}, nodes = {
      UIBox_button{ label = {"All Vouchers"}, button = "trainer_unlock_vouchers", minw = 1.5, minh = 0.45, scale = 0.33, text_colour = G.C.WHITE},
      UIBox_button{ label = {"All Boosters"}, button = "trainer_unlock_boosters", minw = 1.5, minh = 0.45, scale = 0.33, text_colour = G.C.WHITE},
      UIBox_button{ label = {"All Backs"}, button = "trainer_unlock_backs", minw = 1.5, minh = 0.45, scale = 0.33, text_colour = G.C.WHITE},
      UIBox_button{ label = {"All Editions"}, button = "trainer_unlock_editions", minw = 1.5, minh = 0.45, scale = 0.33, text_colour = G.C.WHITE},
    }}
    contents[#contents + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.05}, nodes = {
      UIBox_button{ label = {"All Blinds"}, button = "trainer_unlock_blinds", minw = 1.5, minh = 0.45, scale = 0.33, text_colour = G.C.WHITE},
      UIBox_button{ label = {"All Tags"}, button = "trainer_unlock_tags", minw = 1.5, minh = 0.45, scale = 0.33, text_colour = G.C.WHITE},
      UIBox_button{ label = {"All Seals"}, button = "trainer_unlock_seals", minw = 1.5, minh = 0.45, scale = 0.33, text_colour = G.C.WHITE},
    }}
  end

  -- In-run cheats section
  contents[#contents + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.1}, nodes = {
    {n = G.UIT.T, config = {text = "In-run cheats", scale = 0.45, colour = G.C.WHITE, shadow = true}}
  }}
  if not in_run then
    contents[#contents + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.08}, nodes = {
      {n = G.UIT.T, config = {text = "Start a run to use these.", scale = 0.4, colour = G.C.WHITE, shadow = true}}
    }}
  else
    contents[#contents + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.06}, nodes = {
      UIBox_button{ label = {"+$10"}, button = "trainer_add_money", minw = 1.6, minh = 0.5, scale = 0.38, colour = G.C.GREEN, text_colour = G.C.WHITE},
      UIBox_button{ label = {"+1 Hand"}, button = "trainer_add_hand", minw = 1.6, minh = 0.5, scale = 0.38, text_colour = G.C.WHITE},
      UIBox_button{ label = {"+1 Discard"}, button = "trainer_add_discard", minw = 1.6, minh = 0.5, scale = 0.38, text_colour = G.C.WHITE},
      UIBox_button{ label = {"+1 Round"}, button = "trainer_add_round", minw = 1.6, minh = 0.5, scale = 0.38, text_colour = G.C.WHITE},
      UIBox_button{ label = {"+1 Ante"}, button = "trainer_add_ante", minw = 1.6, minh = 0.5, scale = 0.38, text_colour = G.C.WHITE},
    }}
    contents[#contents + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.06}, nodes = {
      UIBox_button{ label = {"+10 chips"}, button = "trainer_add_chips", minw = 1.6, minh = 0.5, scale = 0.38, text_colour = G.C.WHITE},
      UIBox_button{ label = {"+10 mult"}, button = "trainer_add_mult", minw = 1.6, minh = 0.5, scale = 0.38, text_colour = G.C.WHITE},
      UIBox_button{ label = {"Reroll Boss"}, button = "trainer_reroll_boss", minw = 1.6, minh = 0.5, scale = 0.38, text_colour = G.C.WHITE},
      UIBox_button{ label = {"Win Run"}, button = "trainer_win_game", minw = 1.6, minh = 0.5, scale = 0.38, colour = G.C.GREEN, text_colour = G.C.WHITE},
      UIBox_button{ label = {"Lose Run"}, button = "trainer_lose_game", minw = 1.6, minh = 0.5, scale = 0.38, colour = G.C.RED, text_colour = G.C.WHITE},
    }}
  end

  return create_UIBox_generic_options({
    back_func = 'exit_overlay_menu',
    contents = contents,
  })
end

G.FUNCS.trainer_settings = function(e)
  G.SETTINGS.paused = true
  G.FUNCS.overlay_menu{
    definition = create_UIBox_trainer_settings(),
  }
end
