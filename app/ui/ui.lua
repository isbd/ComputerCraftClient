local M = {}
M.buttons = {}
M.width, M.height = term.getSize()

local default_pal = {
    ["0"]=0xD2C9A5,
    ["1"]=0xAE5D40,
    ["2"]=0xC77B58,
    ["3"]=0x8CABA1,
    ["4"]=0xB3A555,
    ["5"]=0x847875,
    ["6"]=0xD1B187,
    ["7"]=0x4D4539,
    ["8"]=0xAB9B8E,
    ["9"]=0x574852,
    ["a"]=0xBA9158,
    ["b"]=0x4B726E,
    ["c"]=0x927441,
    ["d"]=0x77743B,
    ["e"]=0x79444A,
    ["f"]=0x4B3D44,
}

function M.reset()
    M.buttons = {}
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

function M.button(x, y, label, action, color_text, color_bg)
    term.setCursorPos(x, y)
    term.setTextColor(color_text or colors.white)
    term.setBackgroundColor(color_bg or colors.gray)
    term.write(" " .. label .. " ")
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    table.insert(M.buttons, {x=x, y=y, w=#label+2, action=action})
end

function M.hitTest(x, y)
    for _, b in ipairs(M.buttons) do
        if y == b.y and x >= b.x and x < b.x + b.w then
            return b.action
        end
    end
end

function M.fillPixelbox(mod_box, color)
    if mod_box.clear then
        mod_box:clear(color)
    else
        for y = 1, mod_box.height do
        local row = mod_box.canvas[y]
        for x = 1, mod_box.width do
            row[x] = color
        end
        end
    end
    mod_box:render()
end

function M.renderWindowMessage(win, message, bg_color, text_color)
    bg_color = bg_color or colors.gray
    text_color = text_color or colors.white
    message = message or ""

    local w, h = win.getSize()

    win.setVisible(false)

    win.setBackgroundColor(bg_color)
    win.setTextColor(text_color)
    win.clear()

    local lines = {}
    for line in (message .. "\n"):gmatch("(.-)\n") do
        table.insert(lines, line)
    end

    local num_lines = #lines
    local start_y = math.max(1, math.floor((h - num_lines) / 2) + 1)

    for i, line in ipairs(lines) do
        local x = math.max(1, math.floor((w - #line) / 2) + 1)
        local y = start_y + (i - 1)

        if y >= 1 and y <= h then
            win.setCursorPos(x, y)
            win.write(line)
        end
    end

    win.setVisible(true)
end

function M.renderHealthBar(win, current, max, health_color, text_color, empty_color)
    health_color = health_color or colors.lime
    empty_color = empty_color or colors.gray
    text_color = text_color or colors.white
    local width = win.getSize()
    if width < 1 then
        return
    end

    current = math.max(0, current)
    local filled = math.floor(width * current / max + 0.5)
    if current > 0 and filled == 0 then
        filled = 1
    end
    if current < max and filled == width then
        filled = width - 1
    end

    local label = current .. "/" .. max

    local pad = math.floor((width - #label) / 2)
    local text = (" "):rep(pad) .. label .. (" "):rep(width - #label - pad)

    win.setCursorPos(1, 1)
    win.blit(
        text,
        colors.toBlit(text_color):rep(width),
        colors.toBlit(health_color):rep(filled) .. colors.toBlit(empty_color):rep(width - filled)
    )
end

-- Drawing
function M.fillRect(x, y, w, h, bg)
    term.setBackgroundColor(bg or colors.gray)
    local blank = string.rep(" ", w)
    for dy = 0, h - 1 do
        term.setCursorPos(x, y + dy)
        term.write(blank)
    end
    term.setBackgroundColor(colors.black)
end

function M.applyPalette(pal)
    if not pal then
        pal = default_pal
    end
    local t = term.current()
    for digit, hex in pairs(pal) do
        local colorConst = colors.fromBlit(digit)
        if colorConst then
            t.setPaletteColor(colorConst, hex)
        end
    end
end

function M.resetPalette()
    local t = term.current()
    for idx = 0, 15 do
        local c = 2 ^ idx
        t.setPaletteColor(c, term.nativePaletteColor(c))
    end
end

local function parseTexture(image_str)
    -- Turn string into table
    if type(image_str) == "table" then
        return image_str
    end
    local rows = {}
    for line in (image_str .. "\n"):gmatch("([^\n]*)\n") do
        rows[#rows + 1] = line
    end
    return rows
end

function M.renderImage(box, image_str)
    local image_table = parseTexture(image_str)
    local canvas = box.canvas
    for y = 1, box.height do
        local canvas_row = canvas[y]
        local image_row = image_table[y]
        if image_row then
            for x = 1, box.width do
                local char = image_row:sub(x, x)
                if char ~= "" and char ~= " " then
                    local color = colors.fromBlit(char)
                    if color then
                        canvas_row[x] = color
                    end
                end
            end
        end
    end
    box:render()
end

return M