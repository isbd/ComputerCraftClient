local ui = require("app.ui.ui")
local encounter_api = require("app.api.encounter")
local battle_api = require("app.api.battle")
local M = {}
local encounter_details = nil
local self_mon_sprite = nil
local self_mon_health = nil
local self_mon_max_health = nil
local opponent_mon_sprite = nil
local opponent_mon_health = nil
local opponent_mon_max_health = nil
-- basic, wait, fight
local panel_type = "basic"
local display_text = ""
local animation_details = nil

function M.load(state, ctx)
    local result, err = encounter_api.encounter()

    if not result then
        print("=== ERROR: ===")
        print(err or "Unknown error (nil returned)")
        os.sleep(.5)
        return
    end

    if result ~= nil then
        self_mon_sprite = result.self_mon.texture
        self_mon_health = result.self_mon.current_health
        self_mon_max_health = result.self_mon.max_health
        opponent_mon_sprite = result.opponent_mon.texture
        opponent_mon_health = result.opponent_mon.current_health
        opponent_mon_max_health = result.opponent_mon.max_health
    end
    panel_type = "basic"
    animation_details = nil
    encounter_details = result
    idx = 1
    display_text = ""
end

function drawWaitingPanel(panel)
    -- Awaiting players response
    ui.renderWindowMessage(panel, "Awaiting Response...", colors.gray, colors.white)
end

function drawCombatPanel()
    local result, err = battle_api.getMoves()
    local by_slot = {}
    for _, move in ipairs(result.moves) do
        by_slot[move.slot] = move
    end

    if not result then
        print("=== MOVES ERROR: ===")
        print(err or "Unknown error (nil returned)")
        os.sleep(.5)
        return
    end

    local layout = {
        [1] = {2, 18},
        [2] = {15, 18},
        [3] = {2, 20},
        [4] = {15, 20},
    }

    for slot = 1, #by_slot do
        local x, y = layout[slot][1], layout[slot][2]
        local move = by_slot[slot]
        ui.button(x, y, "".. by_slot[slot].name, "move:".. slot, colors.white, colors.lightGray)
    end
end

function drawBasicPanel(start)
    ui.button(2, 18, "Fight", "basic:fight", colors.white, colors.lightGray)
    ui.button(15, 18, "Bag", "basic:bag", colors.white, colors.lightGray)
    ui.button(2, 20, "Party", "basic:party", colors.white, colors.lightGray)
    ui.button(15, 20, "Run", "basic:run", colors.white, colors.lightGray)
end

function M.draw(state)
    term.setCursorBlink(false)
    term.clear()
    term.setCursorPos(1, 1)
    -- TODO: Add better filtering to prevent blinking

    local half_width = math.floor(ui.width / 2)

    local text_hud = window.create(term.current(), 1, 2, ui.width, 1)
    local mon_hud_a = window.create(term.current(), 1, 1, half_width, 1)
    local mon_hud_b = window.create(term.current(), half_width + 1, 1, ui.width - half_width, 1)
    local mon_a = window.create(term.current(), 1, 2, half_width, 16)
    local mon_b = window.create(term.current(), half_width + 1, 2, ui.width - half_width, 16)
    local bar  = window.create(term.current(), 1, 18, ui.width, 3)
    local mon_a_box  = require("/lib.pixelbox_lite").new(mon_a)
    local mon_b_box  = require("/lib.pixelbox_lite").new(mon_b)

    ui.renderWindowMessage(bar, "", colors.gray, colors.yellow)

    if self_mon_sprite ~= nil then
        ui.renderImage(mon_a_box, self_mon_sprite)
    end

    if opponent_mon_sprite ~= nil then
        ui.renderImage(mon_b_box, opponent_mon_sprite)
    end

    if encounter_details ~= nil then
        ui.renderHealthBar(mon_hud_a, self_mon_health, self_mon_max_health)
        ui.renderHealthBar(mon_hud_b, opponent_mon_health, opponent_mon_max_health, colors.green)
    end

    -- ui.renderWindowMessage(text_hud, display_text, colors.pink, colors.black)

    -- Panel logic
    ui.buttons = {}
    if animation_details ~= nil then
        ui.renderWindowMessage(bar, display_text, colors.pink, colors.black)
    elseif panel_type == "basic" then
        drawBasicPanel()
    elseif panel_type == "move" then
        drawCombatPanel()
    elseif panel_type == "wait" then
        drawWaitingPanel(bar)
    end
end

function updateRound(ctx)
    local result, err = battle_api.getTurn()
    -- TODO: better error handling
    if err then
        print("ERROR ISSUE")
        os.sleep(3)
        return
    end

    animation_details = {
        initial_message = true,
        actions = result.actions,
    }
    ctx.setTimer(.1, "animate")

    -- TODO: Sprites may need updates
end

function relativeHealthDecrease(damage, divisor)
    return math.max(1, math.floor(damage / divisor))
end

function animationHandler(ctx)
    if animation_details == nil then
        return
    end

    if #animation_details.actions == 0 then
        animation_details = nil
        return
    end

    if animation_details.initial_message == true then
        display_text = animation_details.actions[1].message
        animation_details.initial_message = false
        ctx.setTimer(1.5, "animate")
    else
        if animateHealth(ctx) then
            ctx.setTimer(.3, "animate")
        else
            display_text = ""
        end
    end
end

function animateHealth(ctx)
    local current = animation_details.actions[1]

    if current.current_health == nil then
        current.current_health = current.target_pre_damage_health
    end

    if current.damage_dealt < 1 then
        table.remove(animation_details.actions, 1)
        if #animation_details.actions < 1 then
            animation_details = nil
            return false
        end
        animation_details.initial_message = true
        current = animation_details.actions[1]
        return true
    end

    local increment = relativeHealthDecrease(current.damage_dealt, 3)
    current.current_health = current.current_health - increment
    current.damage_dealt = current.damage_dealt - increment

    if current.actor == "self" then
        opponent_mon_health = math.max(0, current.current_health)
        opponent_mon_max_health = current.target_max_health
    else
        self_mon_health = math.max(0, current.current_health)
        self_mon_max_health = current.target_max_health
    end
    return true
end

function M.handle(state, action, ctx)
    if type(action) == "string" and action:sub(1, 5) == "move:" then
        local move = tonumber(action:sub(6))
        local result, err = battle_api.attack(move)

        if result == nil then
            print("=== ATTACK ERROR: ===")
            print(err or "Unknown error (nil returned)")
            os.sleep(.5)
            return
        end

        if result.pending == false then
            if result.active == false then
                return "goto:menu"
            end
            updateRound(ctx)
            panel_type = "basic"
        else
            panel_type = "wait"
        end
        -- If the result is end
    elseif type(action) == "string" and action:sub(1, 6) == "basic:" then
        local option = action:sub(7)
        if option == "fight" then
            panel_type = "move"
        elseif option == "run" then
            encounter_api.surrender()
            return "goto:menu"
        end
    elseif action == "animate" then
        animationHandler(ctx)
    elseif action == "round_resolved" then
        updateRound(ctx)
        panel_type = "basic"
    end
end

function M.onKey(state, ev, p1, ctx)
    if ev == "key" then
        if p1 == keys.s then
            encounter_api.surrender()
            return "goto:menu"
        elseif p1 == keys.b then
            if panel_type ~= "wait" then
                panel_type = "basic"
            end
        end
    end
end

function M.eventHandler(state, event, event_name, event_message)
    local ev_type = event_message.type
    if ev_type == "battle_forfeited" then
        return "goto:menu"
    elseif ev_type == "encounter_over" then
        return "goto:menu"
    elseif ev_type == "round_resolved" then
        return "round_resolved"
    end
end

return M