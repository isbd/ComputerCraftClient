local core = require("app.api.core")

local M = {}

function M.healMon(x, z)
    return core.post("/shop/heal", {x=math.floor(x), z=math.floor(z)})
end

return M