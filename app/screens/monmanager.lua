local ui = require("app.ui.ui")
local mon_api = require("app.api.monster")
local M = {}
local idx = 1
local mon_list = {}

local function print_value(key, value, indent)
    indent = indent or ""
    if type(value) == "table" then
        print(indent .. key .. ":")
        for k, v in pairs(value) do
            print_value(k, v, indent .. "  ")
        end
    else
        print(indent .. key .. ": " .. tostring(value))
    end
end

function M.load(state, ctx)
    local result, err = mon_api.get_monsters()

    if not result then
        print("=== ERROR: ===")
        print(err or "Unknown error (nil returned)")
        return
    end

    mon_list = result
    idx = 1
end

function M.draw(state)
    term.setCursorPos(1, 1)
    term.setCursorBlink(false)
    local half_width = math.floor(ui.width / 2)
    local hud = window.create(term.current(), 1, 1, ui.width, 1)
    local mon = window.create(term.current(), 1, 2, half_width, 16)
    local mon_data = window.create(term.current(), half_width + 1, 2, ui.width - half_width, 16)
    local bar  = window.create(term.current(), 1, 18, ui.width, 3)
    local mod_box  = require("/lib.pixelbox_lite").new(mon)

    local mon_inst = mon_list[idx]
    local formatted_mon_data = (
        mon_inst.species.name .. "\n"..
        mon_inst.level .."\n"..
        mon_inst.current_hp .."/".. mon_inst.max_hp
    )
    ui.renderWindowMessage(mon_data, formatted_mon_data)
end

function M.handle(state, action, ctx)
    -- screen-specific actions
    if action == "decrease" then
        idx = idx - 1
        if idx < 1 then
            idx = #mon_list
        end
    elseif action == "increase" then
        idx = idx + 1
        if idx > #mon_list then
            idx = 1
        end
    end
end

function M.onKey(state, ev, p1, ctx)
    if ev == "key" then
        if p1 == keys.a then return "increase" end
        if p1 == keys.d then return "decrease" end
        if p1 == keys.q then return "goto:menu" end
    end
end

return M