-- @description MYKScripts Spred to Markers
-- @author MYK
-- @version 2024.4
-- @changelog
--  v2024.4
--      + Initial Release
-- @donation https://www.paypal.com/donate/?hosted_button_id=P3YG2YNZWAMAC
-- @about
--  Spread single or groups of items across
--  markers in a REAPER project.
--  Requires [REAPER Toolkit GUI library](https://reapertoolkit.dev/index.html).

-- Load Reaper Toolkit library
package.path = reaper.GetResourcePath() .. '/Scripts/rtk/1/?.lua'
local rtk = require('rtk')

-- ================
-- Global Variables
-- ================
local version = '2024.4'
local num_media_items = reaper.CountSelectedMediaItems(0)

-- ================
-- Helper Functions
-- ================
local function window(t)
    local widget_settings = {
        title = t,
    }
    return widget_settings
end

local function box_widget()
    local widget_settings = {
        padding = 10,
        fillw = true
    }
    return widget_settings
end

local function text_widget(t)
    local widget_settings = {
        text = t,
        padding = 3,
    }
    return widget_settings
end 

local function entry_widget(v)
    local widget_settings = {
        value = v,
        textwidth = 3,
    }
    return widget_settings
end 

local function button_widget(l)
    local widget_settings = {
        label = l,
    }
    return widget_settings
end

-- ======
-- Window
-- ======
local window = rtk.Window(window('Spread to Markers'))
local parent_window_vbox = rtk.VBox(box_widget())
local child_window_hbox1 = rtk.HBox(box_widget())
local child_window_hbox2 = rtk.HBox(box_widget())

-- =======
-- Widgets
-- =======
local text_marker_start = rtk.Text(text_widget('Start Marker:'))
local text_marker_range = rtk.Text(text_widget('Marker Range:'))
local text_num_items = rtk.Text(text_widget('Media Items Selected: ' .. num_media_items))

local entry_marker_start = rtk.Entry(entry_widget(tostring(1)))
local entry_marker_range = rtk.Entry(entry_widget(tostring(num_media_items)))

local go_button = rtk.Button(button_widget('Go'))

-- ==============
-- Main Functions
-- ==============
-- Return value of entry widget and turn to number
local function get_entry_var(w)
    return tonumber(w.value)
end

-- Return input media item position and length
local function get_item_info(i)
    local pos = reaper.GetMediaItemInfo_Value(i, 'D_POSITION')
    local len = reaper.GetMediaItemInfo_Value(i, 'D_LENGTH')
    return pos, len
end

-- Set marker table for seeking
local function set_marker_table(n)
    local out_table = {}
    for i = 0, n - 1 do
        local _1, _2, _3, _4, _5, marker_actual = reaper.EnumProjectMarkers(i)
        out_table[i] = marker_actual
    end
    return out_table
end

-- Find timeline index of actual marker number within marker table
local function get_timeline_index(t, m)
    for i, v in pairs(t) do
        if v == m then
            return i + 1, i + 1
        end
    end
end

local function main()
    local marker_table = set_marker_table(reaper.CountProjectMarkers(0))
    local marker_start = get_entry_var(entry_marker_start)
    local marker_range = get_entry_var(entry_marker_range)
    local marker_index, marker_max = get_timeline_index(marker_table, marker_start)

    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    for i = 0, num_media_items - 1 do
        local current_item = reaper.GetSelectedMediaItem(0, i)
        local item_pos, item_len = get_item_info(current_item)

        if (i <= marker_range and i <= reaper.CountProjectMarkers(0) - marker_max) then
            reaper.GoToMarker(0, marker_index, true)
            reaper.SetMediaItemInfo_Value(current_item, 'D_POSITION', reaper.GetCursorPosition())

            marker_index = marker_index + 1
        else
            local last_item = reaper.GetSelectedMediaItem(0, i - 1)
            local last_item_pos, last_item_len = get_item_info(last_item)
            reaper.SetMediaItemInfo_Value(current_item, 'D_POSITION', last_item_pos + last_item_len)
        end
    end
    reaper.GoToMarker(0, marker_start, false)

    reaper.Undo_EndBlock('Spread to Markers', -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end

-- ===============
-- GUI Interaction
-- ===============
-- On button click
go_button.onclick = function(self, event)
    main()
end

-- Enter key on window focus
window.onkeypresspost = function(self, event)
    if event.keycode == rtk.keycodes.ENTER then
        main()
    end
end

-- ===================
-- Window Construction
-- ===================
child_window_hbox1:add(text_marker_start)
child_window_hbox1:add(entry_marker_start)
child_window_hbox1:add(rtk.Box.FLEXSPACE)
child_window_hbox1:add(text_marker_range)
child_window_hbox1:add(entry_marker_range)

child_window_hbox2:add(go_button)
child_window_hbox2:add(rtk.Box.FLEXSPACE)
child_window_hbox2:add(text_num_items, {halign='right'})

parent_window_vbox:add(child_window_hbox1)
parent_window_vbox:add(child_window_hbox2)

window:add(parent_window_vbox)
window:open{}