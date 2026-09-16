local ui = require("app.ui.ui")
local rift_api = require("app.api.rift")
local encounter_api = require("app.api.encounter")
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
    local text_hud = window.create(term.current(), 1, 1, ui.width, 1)
    term.setCursorBlink(false)
    term.clear()
    ui.renderWindowMessage(text_hud, "Echo Hunter", colors.gray, colors.yellow)
    ui.button(1, 20, "Back", "goto:menu")

    -- Emulator
    if config then
        ui.button(1, 17, "Catch Override", "catch_override")
    end
    if not gps_connected then
        term.setCursorPos(1, 3)
        print("GPS disconnected. Reconnect at spawn")
        return
    end
    if distance then
        term.setCursorPos(10, 3)
        term.write("Distance:")
        term.setCursorPos(13, 4)
        term.write(distance)
        term.setCursorPos(1, 3)
    end
    if distance == 0 then
        ui.button(11, 12, "Engage", "engage")
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
    if action == "engage" then
        return fishRift()
    elseif action == "poll" then
        locateRift()
        ctx.setTimer(POLL_INTERVAL, action)
    elseif action == "catch_override" then
        local result, err = encounter_api.attemptWild()
        if result ~= nil then
            if result.success == true then
                return "goto:battle"
            end
        else
            -- TODO: cleanup
            print(err)
            os.sleep(1)
        end
    end
end

function M.onKey(state, ev, p1, ctx)
    if ev == "key" and p1 == keys.q then
        return "goto:menu"
    end
end

return M