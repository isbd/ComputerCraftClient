local ui = require("app.ui.ui")
local shop_api = require("app.api.shop")
local M = {}

local function fetchGps()
    local x, y, z = gps.locate()
    if not x then
        gps_connected = false
        distance = nil
    else
        gps_connected = true
    end
    -- Emulator
    if config then
        return -9, 0, 53
    end
    return x, y, z
end

function M.load(state, ctx)
    -- load actions
end

function M.draw(state)

    term.setCursorBlink(false)
    term.clear()
    term.setCursorPos(2, 1)
    term.write("== Monster Game ==")
    ui.button(2, 3, "Party", "goto:party")
    ui.button(2, 5, "Challenge", "goto:challenge")
    ui.button(2, 7, "Fish", "goto:fish")
    ui.button(2, 9, "MonManager", "goto:monmanager")
    ui.button(2, 11, "Heal", "heal")
    ui.button(2, 13, "Quit",  "quit")
end

function M.handle(state, action, ctx)
    if action == "heal" then
        local x, _, z = fetchGps()
        shop_api.healMon(x, z)
    end
end

function M.onKey(state, ev, p1, ctx)

end

return M