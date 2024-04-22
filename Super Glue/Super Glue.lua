-- @description MYKScripts Super Glue
-- @author MYK
-- @version 2024.4
-- @changelog
--  v2024.4
--      + Initial Release
-- @donation https://www.paypal.com/donate/?hosted_button_id=P3YG2YNZWAMAC
-- @about
--  Bounce-in-place groups of media items and
--  track FX to a new track while muting the originals.
--  Requires [REAPER Toolkit GUI library](https://reapertoolkit.dev/index.html).

-- Library load
package.path = reaper.GetResourcePath() .. '/Scripts/rtk/1/?.lua'
local rtk = require('rtk')

-- Checksum
if reaper.CountSelectedMediaItems(0) < 1 then
    reaper.ShowMessageBox('Please select media item(s)', 'Error', 0)
    rtk.quit()
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
    title = 'Super Glue',
    resizable = false,
}

local window_box = rtk.VBox(boxWidget(15, 25))
local h_box_1 = rtk.HBox(boxWidget(15, 5))
local h_box_2 = rtk.HBox(boxWidget(15, 5))

local tail_label = rtk.Text(text_widget('Tail Length:'))
local tail_entry = rtk.Entry(entry_widget('0.0', 48))

local go_button = rtk.Button(button_widget('Go', 48))

-- Functions
local function get_channel_count(i)
    local media_item = reaper.GetSelectedMediaItem(0, i)
    local media_take = reaper.GetMediaItemTake(media_item, 0)
    local media_source = reaper.GetMediaItemTake_Source(media_take)
    local channel_count = reaper.GetMediaSourceNumChannels(media_source)

    return channel_count
end

local function set_channel_count(n)
    local channels = 0
    for i = 0, n - 1 do
        local channel_count = get_channel_count(i)

        if channel_count > channels then
            channels = channel_count
        end
    end

    if channels == 2 then
        return 2
    elseif channels > 2 then
        return 3
    else
        return 1
    end
end

local function select_tracks(n)
    for i = 0, n - 1 do
        local media_item = reaper.GetSelectedMediaItem(0, i)
        local track = reaper.GetMediaItem_Track(media_item)
        reaper.SetTrackSelected(track, true)
    end
end

-- Main
local function main()
    local media_item_count = reaper.CountSelectedMediaItems(0)
    local channel_count = set_channel_count(media_item_count)
    local tail_len = tonumber(tail_entry.value)

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    
    select_tracks(media_item_count)

    reaper.Main_OnCommand(40290, 0) -- Set time selection to items
    reaper.Main_OnCommand(40631, 0) -- Go to end of time selection
    reaper.editcursor = reaper.SetEditCurPos(reaper.GetCursorPosition() + tail_len, false, false)
    reaper.Main_OnCommand(40626, 0) -- Set end point of time selection

    if channel_count == 1 then
        reaper.Main_OnCommand(41718, 0) -- Render area to mono
    elseif channel_count == 2 then
        reaper.Main_OnCommand(41716, 0) -- Render area to stereo
    else
        reaper.Main_OnCommand(41717, 0) -- Render area to multichannel
    end

    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    reaper.Main_OnCommand(40718, 0) -- Select all items on selected tracks in current time selection
    reaper.Main_OnCommand(40644, 0) -- Implode items across tracks
    reaper.Main_OnCommand(42434, 0) -- Glue items
    reaper.SetTrackSelected(reaper.GetSelectedTrack(0, 0), false)
    reaper.Main_OnCommand(40005, 0) -- Remove tracks
    reaper.Main_OnCommand(40635, 0) -- Remove time selection

    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock('Super Glue', -1)
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
h_box_1:add(tail_label, window_align('left', 'center'))
h_box_1:add(tail_entry, window_align('right', 'center'))
h_box_2:add(go_button, window_align('right', 'center'))

window_box:add(h_box_1)
window_box:add(h_box_2)

-- Window Build and Open
window:add(window_box)
window:open{
    align = 'center'
}

tail_entry:focus()