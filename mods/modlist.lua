-- Balatro mod loader: Mods button, mod management UI, and Modlist API for mod creators
-- Mods can patch game functions and hook into UI without editing game files.

-- Mod registry: each mod adds { id, name, enabled, settings_func (optional) }
G.MODS = G.MODS or { registry = {} }

--[[ Modlist API: gives mod creators power to edit the game without touching game files.

  Modlist.patch(env, name, wrapper)
    Wrap any global or table function. wrapper receives (orig, ...) and can call orig(...).
    Example: Modlist.patch(Controller, "key_press_update", function(orig, self, key, dt)
      if key == 't' then my_handler(); return end
      return orig(self, key, dt)
    end)

  Modlist.hook(name, callback)
    Register a callback for a named hook. Modlist fires hooks at key points.
    Hooks: "options_menu_contents" (contents table, index to insert before Mods button)
    Example: Modlist.hook("options_menu_contents", function(contents, insert_at)
      table.insert(contents, insert_at, my_button)
    end)

  Modlist.register(id, data)
    Register a mod. Same as G.MODS.registry[id] = data.
]]
Modlist = Modlist or {}
Modlist._hooks = {}

function Modlist.patch(env, name, wrapper)
  env = env or _G
  local orig = env[name]
  if type(orig) ~= "function" then
    error("Modlist.patch: " .. tostring(name) .. " is not a function")
  end
  env[name] = function(...) return wrapper(orig, ...) end
end

function Modlist.hook(name, callback)
  Modlist._hooks[name] = Modlist._hooks[name] or {}
  table.insert(Modlist._hooks[name], callback)
end

function Modlist._fire(name, ...)
  local list = Modlist._hooks[name]
  if list then for _, cb in ipairs(list) do cb(...) end end
end

function Modlist.register(id, data)
  G.MODS.registry[id] = data
end

-- Add Mods button to the Options menu (after Settings)
local _create_UIBox_options = create_UIBox_options
function create_UIBox_options()
  local t = _create_UIBox_options()
  local contents = t.nodes and t.nodes[1] and t.nodes[1].nodes and t.nodes[1].nodes[1] and t.nodes[1].nodes[1].nodes and t.nodes[1].nodes[1].nodes[1] and t.nodes[1].nodes[1].nodes[1].nodes
  if contents then
    -- Fire hook so other mods can inject their options before the Mods button
    Modlist._fire("options_menu_contents", contents, 2)
    local mods_button = UIBox_button{ label = {'Mods'}, button = "mod_menu", minw = 5, colour = G.C.PURPLE }
    table.insert(contents, 2, mods_button)
  end
  return t
end

-- Build one row: [Title] [gear | toggle] - buttons side by side
local function create_mod_row(mod_id, mod)
  local gear_sprite = nil
  if mod.settings_func then
    gear_sprite = Sprite(0, 0, 0.4, 0.4, G.ASSET_ATLAS["icons"], {x = 4, y = 0})
    gear_sprite.states.drag.can = false
  end

  local button_nodes = {}
  if mod.settings_func then
    button_nodes[#button_nodes + 1] = {n = G.UIT.C, config = {align = "cm", padding = 0.02, minw = 0.45, minh = 0.45, r = 0.08, hover = true, colour = G.C.ORANGE, button = mod.settings_func, shadow = true}, nodes = {
      {n = G.UIT.O, config = {object = gear_sprite}}
    }}
  end
  button_nodes[#button_nodes + 1] = create_toggle({
    label = '',
    w = 0.8,
    ref_table = mod,
    ref_value = 'enabled',
    scale = 0.8,
    label_scale = 0.35,
    active_colour = G.C.GREEN,
    inactive_colour = G.C.BLACK,
  })

  return {n = G.UIT.R, config = {align = "cm", padding = 0.05, r = 0.06, colour = G.C.CLEAR}, nodes = {
    {n = G.UIT.C, config = {align = "cl", minw = 2.0}, nodes = {
      {n = G.UIT.T, config = {text = mod.name or mod_id, scale = 0.42, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
    }},
    {n = G.UIT.R, config = {align = "cm", padding = 0}, nodes = button_nodes}
  }}
end

local function create_UIBox_mod_menu()
  local mod_ids = {}
  for id in pairs(G.MODS.registry) do
    mod_ids[#mod_ids + 1] = id
  end
  table.sort(mod_ids)
  local mod_rows = {}
  for _, id in ipairs(mod_ids) do
    mod_rows[#mod_rows + 1] = create_mod_row(id, G.MODS.registry[id])
  end

  local contents = {
    {n = G.UIT.R, config = {align = "cm", padding = 0.15}, nodes = {
      {n = G.UIT.T, config = {text = "Mods", scale = 0.6, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
    }},
  }
  if #mod_rows == 0 then
    contents[#contents + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.1}, nodes = {
      {n = G.UIT.T, config = {text = "No mods loaded.", scale = 0.4, colour = G.C.UI.TEXT_DARK, shadow = true}}
    }}
  else
    for _, row in ipairs(mod_rows) do
      contents[#contents + 1] = row
    end
  end

  return create_UIBox_generic_options({
    back_func = 'exit_overlay_menu',
    contents = contents,
  })
end

G.FUNCS.mod_menu = function(e)
  G.SETTINGS.paused = true
  G.FUNCS.overlay_menu{
    definition = create_UIBox_mod_menu(),
  }
end

-- Auto-discover and load all mod .lua files from the mods/ folder (except modlist.lua)
local _mods_dir = love.filesystem.getSourceBaseDirectory() .. '/mods'
local _list_cmd = love.system.getOS() == 'Windows'
  and ('dir "' .. _mods_dir .. '" /b /a-d 2>nul')
  or  ('ls -1 "' .. _mods_dir .. '" 2>/dev/null')
local _pipe = io.popen(_list_cmd)
if _pipe then
  for filename in _pipe:lines() do
    if filename:match('%.lua$') and filename ~= 'modlist.lua' then
      local mod_name = filename:gsub('%.lua$', '')
      local ok, err = pcall(require, mod_name)
      if not ok then
        print('[modlist] Error loading ' .. mod_name .. ': ' .. tostring(err))
      end
    end
  end
  _pipe:close()
end
