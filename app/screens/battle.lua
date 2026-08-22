local ui = require("app.ui.ui")
local encounter_api = require("app.api.encounter")
local M = {}
local encounter_details = nil

function M.load(state, ctx)
    local result, err = encounter_api.encounter()

    if not result then
        print("=== ERROR: ===")
        print(err or "Unknown error (nil returned)")
        return
    end

    encounter_details = result
    idx = 1
end

function M.draw(state)
    term.setCursorBlink(false)
    term.clear()
    term.setCursorPos(1, 1)

    local half_width = math.floor(ui.width / 2)

    local hud = window.create(term.current(), 1, 1, ui.width, 1)
    local mon_hud_a = window.create(term.current(), 1, 2, half_width, 1)
    local mon_hud_b = window.create(term.current(), half_width + 1, 2, ui.width - half_width, 1)
    local mon_a = window.create(term.current(), 1, 2, half_width, 16)
    local mon_b = window.create(term.current(), half_width + 1, 2, ui.width - half_width, 16)
    local bar  = window.create(term.current(), 1, 18, ui.width, 3)
    local mod_a_box  = require("/lib.pixelbox_lite").new(mon_a)
    local mod_b_box  = require("/lib.pixelbox_lite").new(mon_b)

    ui.renderWindowMessage(hud, "HUD", colors.black, colors.lime)
    ui.renderWindowMessage(bar, "BAR TEST", colors.gray, colors.yellow)

    if encounter_details ~= nil then
        ui.renderImage(mod_a_box, encounter_details.self_mon.texture)
        ui.renderImage(mod_b_box, encounter_details.opponent_mon.texture)
        ui.renderHealthBar(mon_hud_a, encounter_details.self_mon.current_health, encounter_details.self_mon.max_health)
        ui.renderHealthBar(mon_hud_b, encounter_details.opponent_mon.current_health, encounter_details.opponent_mon.max_health, colors.green)
    end
end

function M.onKey(state, ev, p1, ctx)
    if ev == "key" then
        if p1 == keys.q then
            -- return "goto:menu"
        elseif p1 == keys.s then
            encounter_api.surrender()
            return "goto:menu"
        elseif p1 == keys.o then
            -- Testing
            encounter_details.opponent_mon.current_health = encounter_details.opponent_mon.current_health - 1
        elseif p1 == keys.p then
            -- Testing
            encounter_details.self_mon.current_health = encounter_details.self_mon.current_health - 1
        end
    end
end

function M.eventHandler(state, event, event_name, event_message)
    local ev_type = event_message.type
    if ev_type == "battle_forfeited" then
        return "goto:menu"
    end
end

return M