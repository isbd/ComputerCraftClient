local core = require("app.api.core")

local M = {}

function M.register(name)
    local data = core.post_unauthed("/player/", { name = name })
    if not data then
        return nil, "Registration failed"
    end
    core.save_config({ api_key = data.api_key, player_id = data.id })
    return data
end

function M.get_player(player_id)
    return core.get("/player/" .. player_id)
end

function M.get_self()
    local config = core.load_config()
    if not config or not config.player_id then
        return nil, "No player config found"
    end
    return core.get("/player/" .. config.player_id)
end

function M.get_players()
    return core.get("/player")
end

return M