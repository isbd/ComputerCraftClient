local ui = require("app.ui.ui")
local panel = require("app.ui.panel")
local encounter_api = require("app.api.encounter")
local player_api = require("app.api.player")
local M = {}

local challengers
local challengeable
local challengeable_players = {}
local received_challenges = {}
local sent_challenge = nil
local self_id = nil

local function reloadChallenges()
    received_challenges = {}
    challengeable_players = {}
    sent_challenge = nil
    local result, err = encounter_api.challenges()

    if not result then
        term.write("=== ERROR: ===")
        term.write(err or "Unknown error (nil returned)")
        return
    end

    sent_challenge = result.sent_challenge
    received_challenges = result.received_challenges

    if sent_challenge == nil then
        local result_players, err_players = player_api.getPlayers()
        if not result_players then
            term.write("=== ERROR: ===")
            term.write(err_players or "Unknown error (nil returned)")
            return
        end

        local ids = {}
        for _, challenger in ipairs(received_challenges) do
            if challenger.challenger_id ~= nil then
                ids[challenger.challenger_id] = true
            end
        end

        for _, player in ipairs(result_players) do
            if player.id == self_id then
                -- continue
            elseif player.id ~= nil and not ids[player.id] then
                challengeable_players[#challengeable_players + 1] = player
            end
        end
    end

    challengeable:setItems(challengeable_players)
    challengers:setItems(received_challenges)
end

function M.load(state, ctx)
    self_id = ctx.player_id
    challengers = challengers or panel.newPanelList{
        x = 2, y = 3, width = 24, row_height = 2, visible_rows = 3,
        drawRow = function(ch, x, y, w)
            ui.fillRect(x, y, w, 1, colors.gray)
            term.setBackgroundColor(colors.gray)
            term.setCursorPos(x + 1, y)
            term.write(ch.challenger)
            term.setBackgroundColor(colors.black)
            ui.button(x + w - 11, y, "Y", { type = "accept", challenge = ch }, colors.white, colors.green)
            ui.button(x + w - 7, y, "X",  { type = "reject", challenge = ch }, colors.white, colors.red)
        end
    }
    challengeable = challengeable or panel.newPanelList{
        x = 2, y = 11, width = 24, row_height = 2, visible_rows = 3,
        drawRow = function(usr, x, y, w)
            ui.fillRect(x, y, w, 1, colors.gray)
            term.setBackgroundColor(colors.gray)
            term.setCursorPos(x + 1, y)
            term.write(usr.name)
            term.setBackgroundColor(colors.black)
            ui.button(x + w - 11, y, "CHALLENGE", { type = "challenge", user = usr }, colors.white, colors.orange)
        end
    }
    reloadChallenges()
    -- If there is an active encounter need to relocate to battle
end

function M.draw(state)
    term.setCursorBlink(false)
    term.clear()
    term.setCursorPos(2, 1)
    term.write("== Challenges ==")
    challengers:draw()
    if sent_challenge == nil then
        challengeable:draw()
    else
        term.setCursorPos(2, 11)
        term.write("Awaiting response")
        term.setCursorPos(2, 12)
        term.write("from ".. sent_challenge.challenged .."...")
        ui.button(2, 13, "Cancel Request", "cancel")
    end
    ui.button(1, 20, "Back", "goto:menu")
end

local function respond(state, challenge, response)
    -- May want to have the server cancel requested challenges if you accept one (server side)
    local result, err = encounter_api.respondChallenge(challenge.challenge_id, response == "accept")
    if response == "accept" then
        if not err then
            return "goto:battle"
        end
    elseif response == "reject" then
        reloadChallenges()
    end
    return nil
end

function M.handle(state, action, ctx)
    if action.challenge then
        -- Respond to challenge
        return respond(state, action.challenge, action.type)
    elseif action.type == "challenge" then
        -- Issue challenge
        encounter_api.challenge(action.user.id)
        reloadChallenges()
    elseif action == "cancel" then
        encounter_api.cancelChallenge(sent_challenge.challenge_id)
        reloadChallenges()
    end
end

function M.eventHandler(state, event, event_name, event_message)
    local ev_type = event_message.type
    if ev_type == "challenge_canceled"
        or ev_type == "challenge_received" then
        reloadChallenges()
    elseif ev_type == "challenge_response" then
        if event_message.accepted then
            return "goto:battle"
        end
        reloadChallenges()
    end
end

function M.onScroll(state, dir, x, y, ctx)
    if challengers and challengers:contains(x, y) then
        challengers:onScroll(dir)
    end
    if challengeable and challengeable:contains(x, y) then
        challengeable:onScroll(dir)
    end
end

function M.onKey(state, ev, p1, ctx)
    if ev == "key" and p1 == keys.q then
        return "goto:menu"
    end
end

return M