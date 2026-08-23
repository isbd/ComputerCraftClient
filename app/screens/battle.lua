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
    encounter_details = result
    idx = 1
end

function draw_waiting_panel(panel)
    -- Awaiting players response
    ui.renderWindowMessage(panel, "Awaiting Response...", colors.gray, colors.white)
end

function draw_combat_panel()
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

function draw_basic_panel(start)
    ui.button(2, 18, "Fight", "basic:fight", colors.white, colors.lightGray)
    ui.button(15, 18, "Bag", "basic:bag", colors.white, colors.lightGray)
    ui.button(2, 20, "Party", "basic:party", colors.white, colors.lightGray)
    ui.button(15, 20, "Run", "basic:run", colors.white, colors.lightGray)
end

function M.draw(state)
    term.setCursorBlink(false)
    term.clear()
    term.setCursorPos(1, 1)

    local half_width = math.floor(ui.width / 2)

    -- local hud = window.create(term.current(), 1, 1, ui.width, 1)
    local mon_hud_a = window.create(term.current(), 1, 1, half_width, 1)
    local mon_hud_b = window.create(term.current(), half_width + 1, 1, ui.width - half_width, 1)
    local mon_a = window.create(term.current(), 1, 1, half_width, 16)
    local mon_b = window.create(term.current(), half_width + 1, 1, ui.width - half_width, 16)
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

    -- Panel logic
    ui.buttons = {}
    if panel_type == "basic" then
        draw_basic_panel()
    elseif panel_type == "move" then
        draw_combat_panel()
    elseif panel_type == "wait" then
        draw_waiting_panel(bar)
    end
end

function update_round()
    local result, err = battle_api.getTurn()

    self_mon_health = math.max(0, result.opponent_mon_attack.target_pre_damage_health - result.opponent_mon_attack.damage_dealt)
    self_mon_max_health = result.opponent_mon_attack.target_max_health
    opponent_mon_health = math.max(0, result.self_mon_attack.target_pre_damage_health - result.self_mon_attack.damage_dealt)
    opponent_mon_max_health = result.self_mon_attack.target_max_health
    -- TODO: Sprites may need updates
    -- display the moves
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
            update_round()
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
    elseif action == "round_resolved" then
        update_round()
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