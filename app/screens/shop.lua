local ui = require("app.ui.ui")
local shop_api = require("app.api.shop")
local M = {}
shop_x, shop_z, shop_radius = nil
within_range = false
gps_connected = false
POLL_INTERVAL = 1

local function fetchGps()
    local x, y, z = gps.locate()

    if not x then
        gps_connected = false
    else
        gps_connected = true
    end

    -- Emulator
    if config then
        gps_connected = true
        return -9, 0, 153
    end
    return x, y, z
end

local function nearestShop(x, z)
    local result, err = shop_api.nearestShop(x, z)
    if not result then
        return false
    end
    shop_x = result.x_coord
    shop_z = result.z_coord
    shop_radius = result.radius
    return true
end

local function hypot(x, z)
    return math.sqrt(x * x + z * z)
end

local function inRangeDetector()
    local x, _,  z = fetchGps()
    if shop_x == nil then
        if not nearestShop(x, z) then
            return
        end
    end
    local distance = math.floor(hypot(shop_x - x, shop_z - z))
    if distance - shop_radius < 1 then
        within_range = true
    else
        within_range = false
    end
end

function M.load(state, ctx)
    shop_x, shop_z, shop_radius = nil
    within_range = false
    gps_connected = false
    inRangeDetector()
    ctx.setTimer(POLL_INTERVAL, "poll")
end

function M.draw(state)
    local text_hud = window.create(term.current(), 1, 1, ui.width, 1)
    local warning = window.create(term.current(), 1, 2, ui.width, 1)
    term.setCursorBlink(false)
    term.clear()
    ui.renderWindowMessage(text_hud, "Shop", colors.gray, colors.yellow)
    if not gps_connected then
        ui.renderWindowMessage(warning, "GPS Not Connected!", colors.red, colors.white)
    else
        if within_range then
            ui.button(2, 3, " Heal ", "heal")
        else
            ui.renderWindowMessage(warning, "Outside Shop Range!", colors.red, colors.white)
        end
    end
    ui.button(ui.width - 8, 20, " Refresh ", "refresh")
    ui.button(1, 20, " Back ", "goto:menu")
end

function M.handle(state, action, ctx)
    if action == "heal" then
        local x, _, z = fetchGps()
        local result, err = shop_api.healMon(x, z)
        if err then
            print("")
        end
    elseif action == "poll" then
        inRangeDetector()
        ctx.setTimer(POLL_INTERVAL, action)
    elseif action == "refresh" then
        ctx.clearTimers()
        shop_x, shop_z, shop_radius = nil
        within_range = false
        inRangeDetector()
        ctx.setTimer(POLL_INTERVAL, "poll")
    end
end

function M.onKey(state, ev, p1, ctx)
    if ev == "key" and p1 == keys.q then
        return "goto:menu"
    end
end

return M
