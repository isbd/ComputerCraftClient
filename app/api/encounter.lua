local core = require("app.api.core")

local M = {}

function M.attemptWild()
    return core.post("/encounter/wild")
end

function M.surrender()
    return core.post("/encounter/surrender")
end

function M.encounter()
    return core.get("/encounter/")
end

function M.challenges()
    return core.get("/encounter/challenges")
end

function M.cancelChallenge(challenge_id)
    return core.post("/encounter/challenge/cancel", {challenge_id = challenge_id})
end

function M.respondChallenge(challenge_id, accept)
    return core.post("/encounter/challenge/respond", {challenge_id = challenge_id, accept = accept})
end

function M.challenge(player_id)
    return core.post("/encounter/challenge", {player_id = player_id})
end

return M