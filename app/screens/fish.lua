local ui = require("app.ui.ui")
local M = {}

function M.load(state, ctx)
    -- load actions
end

function M.draw(state)
    term.setCursorBlink(false)

    local half_width = math.floor(ui.width / 2)

    local hud = window.create(term.current(), 1, 1, ui.width, 1)
    local mon_hud_a = window.create(term.current(), 1, 2, half_width, 1)
    local mon_hud_b = window.create(term.current(), half_width + 1, 2, ui.width - half_width, 1)
    local mon_a = window.create(term.current(), 1, 2, half_width, 16)
    local mon_b = window.create(term.current(), half_width + 1, 2, ui.width - half_width, 16)
    local bar  = window.create(term.current(), 1, 18, ui.width, 3)
    local mod_a_box  = require("/lib.pixelbox_lite").new(mon_a)
    local mod_b_box  = require("/lib.pixelbox_lite").new(mon_b)

    ui.fillPixelbox(mod_a_box, colors.white)
    ui.fillPixelbox(mod_b_box, colors.blue)

    ui.renderWindowMessage(hud, "HUD", colors.black, colors.lime)

    ui.renderWindowMessage(mon_hud_a, "A", colors.yellow, colors.white)
    ui.renderWindowMessage(mon_hud_b, "B", colors.green, colors.white)
    ui.renderWindowMessage(bar, "BAR TEST", colors.gray, colors.yellow)
end

function M.handle(state, action, ctx)
    -- screen-specific actions
end

function M.onKey(state, ev, p1, ctx)
    if ev == "key" and p1 == keys.q then
        return "goto:menu"
    end
end

return M