local u = require 'stackline.lib.utils'
local Indicator = require'stackline.indicator'

local Window = {}

function Window:new(hsWin) -- {{{
    local stackIdResult = self:makeStackId(hsWin)
    local ws = {
        title      = hsWin:title(),              -- window title
        app        = hsWin:application():name(), -- app name (string)
        id         = hsWin:id(),                 -- window id (string) NOTE: HS win.id == yabai win.id
        frame      = hsWin:frame(),              -- x,y,w,h of window (table)
        stackId    = stackIdResult.stackId,      -- "{{x}|{y}|{w}|{h}" e.g., "35|63|1185|741" (string)
        topLeft    = stackIdResult.topLeft,      -- "{{x}|{y}" e.g., "35|63" (string)
        stackIdFzy = stackIdResult.fzyFrame,     -- "{{x}|{y}" e.g., "35|63" (string)
        _win       = hsWin,                      -- hs.window object (table)
        screen     = hsWin:screen():id(),
    }
    setmetatable(ws, self)
    self.__index = self
    return ws
end -- }}}

function Window:setupIndicator()  -- {{{
  if self.indicator then self.indicator:delete() end
  self:isFocused()
  self.stack:isFocused()
  self.indicator = Indicator
     :new(self)
     :init()
     :draw()
end  -- }}}

function Window:isFocused() -- {{{
  local focusedWin = hs.window.focusedWindow()
  return focusedWin and (focusedWin:id() == self.id) or false
end -- }}}

function Window:getScreenSide() -- {{{
    -- Returns the side of the screen that the window is (mostly) on
    -- Retval: "left" or "right"
    local thresh = 0.75
    local screenWidth = self._win:screen():fullFrame().w

    local leftEdge  = self.frame.x
    local rightEdge = self.frame.x + self.frame.w
    local percR     = 1 - ((screenWidth - rightEdge) / screenWidth)
    local percL     = (screenWidth - leftEdge) / screenWidth

    local side = (percR > thresh and percL < thresh) and 'right' or 'left'
    return side

    -- TODO [low-priority]: BUG: Right-side window incorrectly reports as a left-side window with {{{
    -- very large padding settings. Will need to consider coordinates from both sides of a window.
    -- Impact is minimal with smaller threshold (<= 0.75). }}}

    -- TODO [very-low-priority]: find a way to use hs.window.filter.windowsTo{Dir}  {{{
    -- to determine side instead of percLeft/Right
    --    https://www.hammerspoon.org/docs/hs.window.filter.html#windowsToWest
    --      stackline.wf:windowsToWest(self._win)
    --    https://www.hammerspoon.org/docs/hs.window.html#windowsToWest
    --      self._win:windowsToSouth() }}}
end -- }}}

function Window:makeStackId(hsWin) -- {{{
    local frame = hsWin:frame():floor()
    local x,y,w,h = frame.x, frame.y, frame.w, frame.h

    local fuzzFactor = stackline.config:get('features.fzyFrameDetect.fuzzFactor') or 1
    local roundToFuzzFactor = u.partial(u.roundToNearest, fuzzFactor)
    local ff = u.map({x, y, w, h}, roundToFuzzFactor)

    return {
        topLeft = table.concat({x, y}, '|'),
        stackId = table.concat({x, y, w, h}, '|'),
        fzyFrame = table.concat(ff, '|'),
    }
end -- }}}

function Window:deleteIndicator() -- {{{
    if self.indicator then
        self.indicator:delete()
        self.indicator.canvas = nil -- TODO: Update stack_spec so that stack:resetAllIndicators() passes *without* this kludge
    end
end -- }}}

function Window:setOtherAppWindows(byApp) -- {{{
    local function notSelfSameScreen(w)
        return (w.id ~= self.id) and (w.screen == self.screen)
    end
    self.otherAppWindows = u.filter(byApp[self.app], notSelfSameScreen)
end -- }}}

function Window:unfocusOtherAppWindows() -- {{{
    u.each(self.otherAppWindows, function(w)
        w.indicator:redraw()
    end)
end -- }}}

return Window
