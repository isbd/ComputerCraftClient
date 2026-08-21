local ui = require("app.ui.ui")
local M = {}

local api = require("app.api.core")
local config_path = nil

local screens = {
    menu  = require("app.screens.menu"),
    party = require("app.screens.party"),
    challenge = require("app.screens.challenge"),
    fish = require("app.screens.fish"),
    battle = require("app.screens.battle"),
    monmanager = require("app.screens.monmanager"),
}

local state = {
    screen = "menu",
    dirty = true,
}

local ctx = {}
ctx.timers = {}

local function navigate(name)
    if not screens[name] then return end
    state.screen = name
    screens[name].load(state, ctx)
    state.dirty = true
end

local function dispatch(action)
    if not action then return end
    local scr = screens[state.screen]

    if action == "quit" then
        state.running = false
    elseif type(action) == "string" and action:sub(1, 5) == "goto:" then
        navigate(action:sub(6))
    elseif scr and scr.handle then
        local next_action = scr.handle(state, action, ctx)
        if next_action then
            state.dirty = true
            return dispatch(next_action)
        end
    end
    state.dirty = true
end

function ctx.setTimer(seconds, action)
    local id = os.startTimer(seconds)
    ctx.timers[id] = action
end

function ctx.queueAction(action)
    dispatch(action)
end

local function startup()
    -- Craftos emulator only
    if config and config.set then
        config.set("http_enable", true)  -- emulator only
    end

    -- Ensure wireless modem, excluding emulator
    local attachment = peripheral.wrap("back")
    if not config and (not attachment or not attachment.isWireless()) then
        print("Program requires advanced modem to be attached.")
        sleep(1)
        return
    end

    local player_api = require("app.api.player")

    if config_path then
        api.setConfigPath(config_path)
        print("Using config:" .. config_path)
        os.sleep(1)
    end

    if not fs.exists(config_path) then
        io.write("Enter your name: ")
        local name = io.read()
        local data = player_api.register(name)
        if not data then
            error("Registration failed.")
        end
        print("Registered as " .. data.name .. "!")
        os.sleep(.5)
    end
    print("Logging in with ".. config_path)

    local ws, ws_err = api.connectWs()
    if ws then
        print("WebSocket connected.")
    else
        print("Error connecting".. tostring(ws_err))
        return
    end
    os.sleep(.5)
    ctx.ws = ws
    ctx.player_id = api.loadPlayerId()
    ctx.ws_opened_at = os.clock()

    navigate("menu")
    state.running = true
end

function M.run(config)
    config_path = config
    startup()

    while state.running do
        if state.dirty then
            ui.reset()
            screens[state.screen].draw(state)
            state.dirty = false
        end

        local ev, p1, p2, p3 = os.pullEvent()
        if ev == "mouse_click" then
            dispatch(ui.hitTest(p2, p3))
        elseif ev == "mouse_scroll" then
            local scr = screens[state.screen]
            if scr.onScroll then
                local action = scr.onScroll(state, p1, p2, p3)
                state.dirty = true
                if action then dispatch(action) end
            end
        elseif ev == "websocket_message" then
            -- websocket handling
            local scr = screens[state.screen]
            local msg = textutils.unserialiseJSON(p2)
            if scr.eventHandler then
                local action = scr.eventHandler(state, ev, p1, msg)
                state.dirty = true
                if action then dispatch(action) end
            end
        elseif ev == "websocket_closed" then
            -- TO DO: FIX WEBSOCKET FAILURE
            -- os.error("WebSocket failed: ".. tostring(p3))
        elseif ev == "timer" then
            local action = ctx.timers[p1]
            if action then
                ctx.timers[p1] = nil
                dispatch(action)
            end
        elseif ev == "char" or ev == "key" then
            local scr = screens[state.screen]
            if scr.onKey then
                local action = scr.onKey(state, ev, p1, ctx)
                state.dirty = true
                if action then dispatch(action) end
            end
        end
    end

    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
end

return M