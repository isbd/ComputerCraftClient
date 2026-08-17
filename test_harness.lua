local args = { ... }
local config_file = args[1] or "config.json"
local player_api = require("app.api.player")
local encounter_api = require("app.api.encounter")
local monster_api = require("app.api.monster")
local battle_api = require("app.api.battle")
local core = require("app.api.core")

if config_file then
    core.setConfigPath(config_file)
    print("Using config:" .. config_file)
end

config.set("http_enable", true)

local pending = {}

if not fs.exists(config_file) then
    io.write("Enter your name: ")
    local name = io.read()
    local data = player_api.register(name)
    if not data then
        print("Registration failed.")
        return
    end
    print("Registered as " .. data.name .. "!")
end

local ws, ws_err = core.connectWs()
if ws then
    print("WebSocket connected.")
else
    print("WebSocket failed: " .. tostring(ws_err))
end

local function printValue(key, value, indent)
    indent = indent or ""
    if type(value) == "table" then
        print(indent .. key .. ":")
        for k, v in pairs(value) do
            printValue(k, v, indent .. "  ")
        end
    else
        print(indent .. key .. ": " .. tostring(value))
    end
end

function displayResult(api_func, label, ...)
    local result, err = api_func(...)

    if not result then
        print("=== ERROR: " .. (label or "Result") .. " ===")
        print(err or "Unknown error (nil returned)")
        return
    end

    print("=== " .. (label or "Result") .. " ===")
    for key, value in pairs(result) do
        printValue(key, value)
    end
end

local options = {
    { label = "Current Player Info",    func = player_api.getSelf},
    { label = "Player Info",            func = player_api.getPlayer, args = { "Player ID" } },
    { label = "Players",                func = player_api.getPlayers},
    { label = "Wild Encounter",         func = encounter_api.attemptWild },
    { label = "Surrender Encounter",    func = encounter_api.surrender },
    { label = "Encounter Info",         func = encounter_api.encounter },
    { label = "Catch Attempt",          func = battle_api.catch },
    { label = "Attack Attempt",         func = battle_api.attack, args = { "Move ID" } },
    { label = "Moves",                  func = battle_api.getMoves },
    { label = "Player Monsters",        func = monster_api.getMonsters },
    { label = "Monster Info",           func = monster_api.getMonster, args = { "Monster ID" } },

    { label = "Challenge",              func = encounter_api.challenge, args = { "Player ID" } },
    { label = "Challenge Respond",      func = encounter_api.respondChallenge, args = { "Challenge ID", "Accept?" } },
    { label = "Challenge Cancel",       func = encounter_api.cancelChallenge, args = { "Challenge ID" } },
    { label = "Challenges",             func = encounter_api.challenges },
}

local function promptArgs(arg_names)
    if not arg_names then return {} end
    local values = {}
    for _, name in ipairs(arg_names) do
        io.write(name .. ": ")
        table.insert(values, io.read())
    end
    return values
end

local function drainNotifications()
    while #pending > 0 do
        local event = table.remove(pending, 1)
        if event.type == "challenge_received" then
            print("\n>>> " .. event.from .. " challenges you!")
            io.write("Accept? (y/n): ")
            local answer = io.read()
            if answer == "y" then
                encounter_api.respondChallenge(event.from, true)
                print("Accepted.")
            else
                encounter_api.respondChallenge(event.from, false)
                print("Declined.")
            end
        elseif event.type == "your_turn" then
            print("\n>>> Opponent moved, battle updated.")
        elseif event.type == "socket_closed" then
            print("\n>>> Disconnected from server.")
        else
            print("\n>>> Unknown event type:".. event.type .."!")
        end
    end
end

local function runMenu()
    while true do
        drainNotifications()
        print("\n=== Menu ===")
        for i, option in ipairs(options) do
            print(i .. ". " .. option.label)
        end
        print("0. Exit")

        io.write("Select: ")
        local input = tonumber(io.read())

        if input == 0 then
            print("Goodbye!")
            break
        elseif input and options[input] then
            local selected = options[input]
            local args = promptArgs(selected.args)
            print("")
            displayResult(selected.func, selected.label, table.unpack(args))
        else
            print("Invalid option.")
        end
    end
end

local function listen()
    if not ws then
        while true do os.pullEvent() end
    end
    while true do
        local msg = ws.receive()
        if msg == nil then
            print("\n[socket closed]")
            while true do os.pullEvent() end
        else
            local event = textutils.unserialiseJSON(msg)
            table.insert(pending, event)
        end
    end
end

parallel.waitForAny(runMenu, listen)