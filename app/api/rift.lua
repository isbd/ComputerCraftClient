local core = require("app.api.core")

local M = {}

function M.fishRifts(x, z)
    return core.get("/rift/fish_rifts?x=" .. math.floor(x) .."&z=".. math.floor(z))
end

function M.calibrate(x, z)
    return core.get("/rift/calibrate?x=" .. math.floor(x) .."&z=".. math.floor(z))
end

return M