local ui = require("app.ui.ui")
local M = {}

local PanelList = {}
PanelList.__index = PanelList

function M.newPanelList(opts)
    return setmetatable({
        x = opts.x,
        y = opts.y,
        width = opts.width,
        row_height = opts.row_height,
        visible_rows = opts.visible_rows,
        drawRow = opts.drawRow,
        items = opts.items or {},
        scroll = 0,
    }, PanelList)
end

function M.isList(obj)
    return getmetatable(obj) == PanelList
end

function PanelList:setItems(items)
    self.items = items or {}
    self:clamp()
end

function PanelList:clamp()
    local maxScroll = math.max(0, #self.items - self.visible_rows)
    self.scroll = math.max(0, math.min(self.scroll, maxScroll))
end

function PanelList:onScroll(dir)
    self.scroll = self.scroll + dir
    self:clamp()
end

function PanelList:contains(px, py)
    local inside_x = px >= self.x and px < self.x + self.width + 1
    local inside_y = py >= self.y and py < self.y + self.visible_rows * self.row_height
    return inside_x and inside_y
end

function PanelList:draw()
    local first = self.scroll + 1
    local last  = math.min(#self.items, self.scroll + self.visible_rows)
    for i = first, last do
        local row_y = self.y + (i - first) * self.row_height
        self.drawRow(self.items[i], self.x, row_y, self.width)
    end
    self:drawScrollbar()
end

function PanelList:drawScrollbar()
    if #self.items <= self.visible_rows then return end

    local track_height = self.visible_rows * self.row_height
    local bar_x = self.x + self.width

    local max_scroll = #self.items - self.visible_rows
    local marker_offset = math.floor((self.scroll / max_scroll) * (track_height - 1))
    local marker_row = self.y + marker_offset

    term.setBackgroundColor(colors.lightGray)
    for dy = 0, track_height - 1 do
        term.setCursorPos(bar_x, self.y + dy)
        term.write(" ")
    end

    term.setBackgroundColor(colors.white)
    term.setCursorPos(bar_x, marker_row)
    term.write(" ")

    term.setBackgroundColor(colors.black)
end

return M