local ui = require("app.ui.ui")
local rift_api = require("app.api.rift")
local M = {}

local POLL_INTERVAL = 1
local gps_connected = true
local distance = nil

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
        return 0, 0, 0
    end
    return x, y, z
end

function M.load(state, ctx)
    -- Check if gps is active
    fetchGps()
    ctx.setTimer(POLL_INTERVAL, "poll")
end

function M.draw(state)
    term.setCursorBlink(false)
    term.clear()
    term.setCursorPos(1, 1)
    ui.button(1, 20, "Back", "goto:menu")
    if not gps_connected then
        term.setCursorPos(1, 1)
        print("GPS disconnected. Reconnect at spawn")
        return
    end
    if distance then
        term.setCursorPos(10, 1)
        term.write("Distance:")
        term.setCursorPos(13, 2)
        term.write(distance)
        term.setCursorPos(1, 1)
    end
    if distance == 0 then
        ui.button(11, 12, "Fish", "fish")
    end
end

local function fishRift()
    local x, y, z = fetchGps()
    if not x then
        return
    end
    local result, err = rift_api.calibrate(x, z)

    if not result then
        term.write("=== ERROR: ===")
        term.write(err or "Unknown error (nil returned)")
        return
    end

    if result.success then
        return "goto:battle"
    end
end

local function locateRift()
    local x, y, z = fetchGps()
    if not x then
        return
    end
    local result, err = rift_api.fishRifts(x, z)

    if not result then
        term.write("=== ERROR: ===")
        term.write(err or "Unknown error (nil returned)")
        return
    end

    if result.success then
        distance = result.distance
    else
        distance = nil
    end
end

function M.handle(state, action, ctx)
    if action == "fish" then
        return fishRift()
    elseif action == "poll" then
        locateRift()
        ctx.setTimer(POLL_INTERVAL, action)
    end
end

function M.onKey(state, ev, p1, ctx)
    if ev == "key" and p1 == keys.q then
        return "goto:menu"
    end
end

return M