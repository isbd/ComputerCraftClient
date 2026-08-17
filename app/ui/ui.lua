local M = {}
M.buttons = {}
M.width, M.height = term.getSize()

function M.reset()
    M.buttons = {}
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

function M.button(x, y, label, action, color_text, color_bg)
    term.setCursorPos(x, y)
    term.setBackgroundColor(color_text or colors.gray)
    term.write(" " .. label .. " ")
    term.setBackgroundColor(color_bg or colors.black)
    table.insert(M.buttons, {x=x, y=y, w=#label+2, action=action})
end

function M.hitTest(x, y)
    for _, b in ipairs(M.buttons) do
        if y == b.y and x >= b.x and x < b.x + b.w then
            return b.action
        end
    end
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
    if not pal then return end
    local t = term.current()
    for digit, rgb in pairs(pal) do
        local colorConst = colors.fromBlit(digit)
        if colorConst then
            t.setPaletteColor(colorConst, rgb[1], rgb[2], rgb[3])
        end
    end
end

function M.renderImage(box, image)
    local canvas = box.canvas
    for y = 1, box.height do
        local canvas_row = canvas[y]
        local image_row  = image[y]
        for x = 1, box.width do
        local char = image_row and image_row[x]
        if char and char ~= " " then
            local color = colors.fromBlit(char)
            if color then
            canvas_row[x] = color
            end
        end
        end
    end
    box:render()
end

return M