local core = require("app.api.core")

local M = {}

function M.register(name)
    local data = core.postUnauthed("/player/", { name = name })
    if not data then
        return nil, "Registration failed"
    end
    core.saveConfig({ api_key = data.api_key, player_id = data.id })
    return data
end

function M.getPlayer(player_id)
    return core.get("/player/" .. player_id)
end

function M.getSelf()
    local config = core.loadConfig()
    if not config or not config.player_id then
        return nil, "No player config found"
    end
    return core.get("/player/" .. config.player_id)
end

function M.getPlayers()
    return core.get("/player")
end

return M