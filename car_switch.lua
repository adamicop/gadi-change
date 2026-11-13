-- car_switch.lua : in-game car switcher window for an AssettoServer / CSP online script.
--
-- UI: open the CSP chat app, click the lightbulb (extras) icon and pick "Car switcher".
--     A small window stays on screen with the list of cars and a Switch button (click twice to confirm).
-- Hotkeys still work too (hold Shift): PageUp / PageDown pick a car, Enter twice switches.
--
-- Switching uses ac.reconnectTo{ carID = ... } from the CSP Lua SDK. That REconnects you to the same
-- server with the other car, so a short loading screen is normal. It is not an instant swap.
--
-- Requirements on the server:
--   * every car in CARS must exist in entry_list.ini as a PLAYER slot (AI=none) and be free,
--     otherwise the reconnect fails to join.
--   * the car must be installed / downloadable for the player.

-- EDIT THIS LIST: car folder names (the ones in entry_list.ini MODEL=...). All playable cars of this server.
local CARS = {
  'nohesi_urus_mansory',
  'nohesi_porsche_gt3rs',
  'ford_mustang_dark_horse_redd_spec',
  'p_mlgz_tgn_bmw_m2_g87_tuned',
  'nissan_r32_pandem_hellspec',
  'prvvy_bmw_m3_f80_comp_single_turbo',
  'cis_bmw_m5_g90_mansory',
  'as_bmw_m3_g80_ceky_x_pushin_p',
  'tgn_x_prvvy_bmw_x5m_2020',
  'mlgz_x_prvvy_bmw_m8_gc2',
  'c63_2008_w204',
  'mrkryp_lexus_lc500',
  'mercedes_sls_amg_s',
  'mercedes_benz_w211_e55_kybic_Realistic',
  'ferrari_sf90_2020_blackwidow',
  'mitsubishi_evo6_1999_tommi_makinen',
  'prvvy_550_e39',
}

local selected = 1
local pendingConfirm = 0   -- seconds left to confirm the switch

local function currentCarID()
  return ac.getCarID(0)
end

local function doSwitch(id)
  ui.toast(ui.Icons.Settings, 'Switching to ' .. id .. '...')
  ac.reconnectTo({ carID = id })
end

local function requestSwitch(id)
  if id == currentCarID() then
    ui.toast(ui.Icons.Settings, 'You are already driving ' .. id)
    return
  end
  if pendingConfirm > 0 then
    pendingConfirm = 0
    doSwitch(id)
  else
    pendingConfirm = 3
    ui.toast(ui.Icons.Settings, 'Confirm again to switch to ' .. id)
  end
end

-- hotkeys (hold Shift)
function script.update(dt)
  if pendingConfirm > 0 then
    pendingConfirm = pendingConfirm - dt
  end
  if not ui.keyboardButtonDown(16) then return end        -- VK_SHIFT

  if ui.keyboardButtonPressed(33) then                    -- PageUp
    selected = selected - 1
    if selected < 1 then selected = #CARS end
    pendingConfirm = 0
    ui.toast(ui.Icons.Settings, 'Car: ' .. CARS[selected] .. '  (Shift+Enter twice to switch)')
  elseif ui.keyboardButtonPressed(34) then                -- PageDown
    selected = selected + 1
    if selected > #CARS then selected = 1 end
    pendingConfirm = 0
    ui.toast(ui.Icons.Settings, 'Car: ' .. CARS[selected] .. '  (Shift+Enter twice to switch)')
  elseif ui.keyboardButtonPressed(13) then                -- Enter
    requestSwitch(CARS[selected])
  end
end

-- window contents
local function carSwitcherUI()
  ui.text('Driving now: ' .. currentCarID())
  ui.text('Pick a car:')
  ui.childWindow('##carlist', vec2(ui.availableSpaceX(), 220), function ()
    for i = 1, #CARS do
      local label = CARS[i]
      if CARS[i] == currentCarID() then label = label .. '  (current)' end
      if ui.selectable(label, selected == i) then
        selected = i
        pendingConfirm = 0
      end
    end
  end)
  local buttonLabel = pendingConfirm > 0 and 'Click again to confirm' or 'Switch to selected car'
  if ui.button(buttonLabel) then
    requestSwitch(CARS[selected])
  end
end

-- "Tool" flag = small window that stays on screen (combos and buttons work in it)
ui.registerOnlineExtra(ui.Icons.Settings, 'Car switcher', nil, carSwitcherUI, function () end, ui.OnlineExtraFlags.Tool)
