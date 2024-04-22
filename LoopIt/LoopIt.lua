-- @description LoopIt
-- @author MYK
-- @version 2024.4
-- @about
--   This is an example of a package file. It installs itself as a ReaScript that
--   does nothing but show "Hello World!" in REAPER's scripting console.
--
--   Packages may also include additional files specified using the @provides tag.
--
--   This text is the documentation shown when using ReaPack's "About this package"
--   feature. [Markdown](https://commonmark.org/) *formatting* is supported.

local version = '2024.4'

-- Library load
package.path = reaper.GetResourcePath() .. '/Scripts/rtk/1/?.lua'
local rtk = require('rtk')

-- Checksum
local item_count = reaper.CountSelectedMediaItems(0)

if item_count < 1 then
    reaper.MB('Please select a media item.', 'Error', 0)
    rtk.quit()
    return
end

-- GUI Helpers
-- Box
local function boxWidget(s, p, w, h)
    local setup_vars = {
        spacing = s,
        w = w,
        h = h,
        padding = p
    }
    return setup_vars
end

-- Entry
local function entry_widget(v, w)
    local setup_vars = {
        value = v,
        w = w,
    }
    return setup_vars
end

-- Button
local function button_widget(text, w)
    local setup_vars = {
        tostring(text),
        w = w
    }
    return setup_vars
end

-- Text
local function text_widget(text, fs)
    local setup_vars = {
        text,
        fontsize = fs
    }
    return setup_vars
end

-- Window Alignment
local function window_align(h, v)
    local setup_vars = {
        halign = h,
        valign = v
    }
    return setup_vars
end

-- Widgets --
-- Window
local window = rtk.Window {
    title = 'LoopIt',
    resizable = false,
}

local window_box = rtk.VBox(boxWidget(15, 25))
local h_box_1 = rtk.HBox(boxWidget(15, 5))
local h_box_2 = rtk.HBox(boxWidget(15, 5))

local fade_label = rtk.Text(text_widget('Crossfade Length:'))
local fade_entry = rtk.Entry(entry_widget('2.0', 48))

local go_button = rtk.Button(button_widget('Go', 48))

-- REAPER Variables
local item = reaper.GetSelectedMediaItem(0, 0)
local track = reaper.GetMediaItem_Track(item)

local item_pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
local fin_pos = item_pos
local item_len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')

local function set_trim_cur(pos, dir)
    -- Set cursor position
    reaper.SetEditCurPos(pos, false, false)
    -- Find zero-crossing
    reaper.Main_OnCommand(41995, 0)

    if dir == 'left' then
        reaper.Main_OnCommand(41305, 0) -- Trim left edge to cursor
    elseif dir == 'right' then
        reaper.SetEditCurPos(pos - 0.5, false, false)
        reaper.Main_OnCommand(41311, 0) -- Trim right edge to cursor
    elseif dir == 'center' then
        reaper.Main_OnCommand(40759, 0) -- Split item at cursor (Select right)
    end
end

local function get_set_item_info(item)
    local item_idx = reaper.GetMediaItemInfo_Value(item, 'IP_ITEMNUMBER')
    item_pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    item_len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')

    return reaper.GetTrackMediaItem(track, item_idx - 1)
end


local function main()
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    local fade_len = tonumber(fade_entry.value)

    set_trim_cur(item_pos, 'left')
    set_trim_cur(item_pos + item_len, 'right')
    set_trim_cur(item_pos + item_len / 2, 'center')

    item = get_set_item_info(reaper.GetSelectedMediaItem(0, 0))
    reaper.SetMediaItemInfo_Value(item, 'D_POSITION', (item_pos + item_len) - fade_len)
    reaper.SetMediaItemSelected(item, true)
    reaper.Main_OnCommand(41059, 0) -- Crossfade any overlapping items
    reaper.Main_OnCommand(40362, 0) -- Glue items, ignoring time selection
    reaper.Main_OnCommand(41193, 0) -- Remove fade in and fade out

    item = reaper.GetSelectedMediaItem(0, 0)
    reaper.SetMediaItemInfo_Value(item, 'D_POSITION', fin_pos)

    local item_take = reaper.GetMediaItemTake(item, 0)
    local retval, item_take_name = reaper.GetSetMediaItemTakeInfo_String(item_take, 'P_NAME', '', false)

    item_take_name = item_take_name.gsub(item_take_name, '-glued', '_LOOP')

    reaper.GetSetMediaItemTakeInfo_String(item_take, 'P_NAME', item_take_name, true)

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock('Loop', 0)
    rtk.quit()
end

-- GUI Interaction
-- Button click
go_button.onclick = function(self, event)
    main()
end

-- Enter key on window focus
window.onkeypresspost = function(self, event)
    if event.keycode == rtk.keycodes.ENTER then
        main()
    end
end

-- Box Construct
h_box_1:add(fade_label, window_align('left', 'center'))
h_box_1:add(fade_entry, window_align('right', 'center'))
h_box_2:add(go_button, window_align('right', 'center'))

window_box:add(h_box_1)
window_box:add(h_box_2)

-- Window Build and Open
window:add(window_box)
window:open{
    align = 'center'
}

fade_entry:focus()
