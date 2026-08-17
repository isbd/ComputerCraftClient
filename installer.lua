local REPO = "https://raw.githubusercontent.com/isbd/ComputerCraftClient/main/"

-- TODO: Add versioning handler

local function get(path)
    -- cache buster matters most on the manifest itself
    return http.get(REPO .. path .. "?v=" .. os.epoch("utc"))
end

if not http then printError("HTTP is disabled.") return end

local manifest = get("file_index.txt")
if not manifest then printError("Couldn't fetch file_index.txt manifest.") return end

local list = {}
for line in manifest.readAll():gmatch("[^\r\n]+") do
    line = line:match("^%s*(.-)%s*$")
    if line ~= "" and line:sub(1, 1) ~= "#" then
        list[#list + 1] = line
    end
end
manifest.close()

local ok, failed = 0, 0
for _, path in ipairs(list) do
    local res = get(path)
    if res then
        local dir = fs.getDir(path)
        if dir ~= "" and not fs.exists(dir) then fs.makeDir(dir) end
        local f = fs.open(path, "w")
        f.write(res.readAll())
        f.close()
        res.close()
        print("ok    " .. path)
        ok = ok + 1
    else
        printError("fail  " .. path)
        failed = failed + 1
    end
end

print(("Installed %d file(s), %d failed."):format(ok, failed))