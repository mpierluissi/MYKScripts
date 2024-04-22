-- Track Renamer by Michael Pierluissi
local version = '2024.4'

-- Library load
package.path = reaper.GetResourcePath() .. '/Scripts/rtk/1/?.lua'
local rtk = require('rtk')

-- Checksum
local track_count = reaper.CountSelectedTracks(0)

if track_count < 1 then
    reaper.MB('Please select 1 or more tracks.', 'Error', 0)
    rtk.quit()
end

-- GUI Helpers
-- Boxes
local function box_widget(s, p, w, h, t)
    local widget_settings = {
        spacing = s,
        w = w,
        h = h,
        padding = p
    }
    return widget_settings
end

-- Spacers
local function spacer_widget(w)
    local widget_settings = {
        w = w,
    }
    return widget_settings
end

-- CheckBox
local function checkbox_widget(str)
    local widget_settings = {
        tostring(str),
    }
    return widget_settings
end

-- Entry
local function entry_widget(placeholder, w)
    local widget_settings = {
        placeholder = tostring(placeholder),
        w = w,
    }
    return widget_settings
end

-- Button
local function button_widget(text, w)
    local widget_settings = {
        tostring(text),
        w = w
    }
    return widget_settings
end

-- Text
local function text_widget(text)
    local widget_settings = {
        text,
    }
    return widget_settings
end

-- Widget Alignment
local function widget_align(h, v)
    local widget_settings = {
        halign = h,
        valign = v,
        fillw = true
    }
    return widget_settings
end
-- /Helpers --

-- Widgets --
-- Window
local window = rtk.Window {
    title = 'Rename Tracks',
    resizable = false,
}
-- Box
local parent_window_vbox = rtk.VBox(box_widget(10, nil, 400))
local child_window_hbox1 = rtk.HBox(box_widget(nil, 10))
local child_window_hbox2 = rtk.HBox(box_widget(nil, 10))
local child_window_hbox3 = rtk.HBox(box_widget(nil, 10))
local child_window_hbox4 = rtk.HBox(box_widget(nil, 10))
local child_window_hbox5 = rtk.HBox(box_widget(nil, 10))
local child_window_hbox6 = rtk.HBox(box_widget(nil, 10))
local child_window_hbox7 = rtk.HBox(box_widget(nil, 10))
local child_window_hbox8 = rtk.HBox(box_widget(nil, 10))
local child_window_hbox9 = rtk.HBox(box_widget(nil, 10))
local child_window_hbox10 = rtk.HBox(box_widget(nil, 10))
local child_window_hbox11 = rtk.HBox(box_widget(nil, 10))

-- Replace
local replace_check = rtk.CheckBox(checkbox_widget('Replace'))
local replace_entry = rtk.Entry(entry_widget('Replace All', 1))

-- Find and Replace
local find_check = rtk.CheckBox(checkbox_widget('Find and Replace'))
local find_entry = rtk.Entry(entry_widget('Find', 1))
local find_replace_entry = rtk.Entry(entry_widget('Replace', 1))

-- Insert
local insert_check = rtk.CheckBox(checkbox_widget('Insert at Index'))
local insert_entry = rtk.Entry(entry_widget('Insertion', 1))
local insert_index = rtk.Entry(entry_widget('Index (#)', .5))

-- Trim
local trim_check = rtk.CheckBox(checkbox_widget('Trim From'))
local trim_start_entry = rtk.Entry(entry_widget('Start (#)', .5))
local trim_end_entry = rtk.Entry(entry_widget('End (#)', .5))

-- Numbering
local numbering_check = rtk.CheckBox(checkbox_widget('Numbering'))
local numbering_start = rtk.Entry(entry_widget('Start (#)', .5))
local numbering_delim = rtk.Entry(entry_widget('Delimiter', .5))

-- Button
local go_button = rtk.Button(button_widget('Go', .25))

-- Labels
local version_label = rtk.Text(text_widget('Track Renamer v' .. version))

-- Spacers
local spacer1 = rtk.Spacer(spacer_widget(.5))
local spacer2 = rtk.Spacer(spacer_widget(.5))
local spacer3 = rtk.Spacer(spacer_widget(.5))
local spacer4 = rtk.Spacer(spacer_widget(.5))
-- /Widgets --

local function main()
    reaper.Undo_BeginBlock()
    -- Get Values
    -- Strings
    local replace_str = replace_entry.value
    local find_str = find_entry.value
    local find_replace_str = find_replace_entry.value
    local insert_str = insert_entry.value
    local numbering_str = numbering_delim.value
    -- Variables
    local insert_var = tonumber(insert_index.value) or 0
    local trim_start_var = tonumber(trim_start_entry.value) or 0
    local trim_end_var = tonumber(trim_end_entry.value) or 0
    local numbering_var = tonumber(numbering_start.value) or 0

    for i = 0, track_count - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        if replace_check.value == rtk.CheckBox.CHECKED then
            local track = reaper.GetSelectedTrack(0, i)
            reaper.GetSetMediaTrackInfo_String(track, "P_NAME", replace_str, true)
        else
            if find_check.value == rtk.CheckBox.CHECKED then
                local retval, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
                local new_track_name = track_name:gsub(find_str, find_replace_str)
                reaper.GetSetMediaTrackInfo_String(track, "P_NAME", new_track_name, true)
            end
            if insert_check.value == rtk.CheckBox.CHECKED then
                local retval, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
                local new_track_name = track_name:sub(1, insert_var) .. insert_str .. track_name:sub(insert_var + 1, #track_name)
                reaper.GetSetMediaTrackInfo_String(track, "P_NAME", new_track_name, true)
            end
            if trim_check.value == rtk.CheckBox.CHECKED then
                local retval, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
                local new_track_name = track_name:sub(trim_start_var + 1, #track_name - trim_end_var)
                reaper.GetSetMediaTrackInfo_String(track, "P_NAME", new_track_name, true)
            end
        end
        if numbering_check.value == rtk.CheckBox.CHECKED then
            local retval, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
            local new_track_name = track_name .. numbering_str .. numbering_var + i
            reaper.GetSetMediaTrackInfo_String(track, "P_NAME", new_track_name, true)
        end
    end
    reaper.UpdateArrange()
    rtk.quit()
    reaper.Undo_EndBlock('Rename Tracks', 1)
end

-- GUI Interaction
-- Tab Key
window.onkeypress = function(self, event)
    if event.keycode == rtk.keycodes.TAB then
        if replace_entry:focused() then
            find_entry:focus()
        elseif find_entry:focused() then
            find_replace_entry:focus()
        elseif find_replace_entry:focused() then
            insert_entry:focus()
        elseif insert_entry:focused() then
            insert_index:focus()
        elseif insert_index:focused() then
            trim_start_entry:focus()
        elseif trim_start_entry:focused() then
            trim_end_entry:focus()
        elseif trim_end_entry:focused() then
            numbering_start:focus()
        elseif numbering_start:focused() then
            numbering_delim:focus()
        elseif numbering_delim:focused() then
            replace_entry:focus()
        end
    end
end

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

-- Container Build
-- Widgets
child_window_hbox1:add(replace_check, widget_align('left', 'center'))
child_window_hbox1:add(replace_entry, widget_align('right', 'center'))

child_window_hbox2:add(find_check, widget_align('left', 'center'))
child_window_hbox2:add(find_entry, widget_align('right', 'center'))

child_window_hbox3:add(spacer1, widget_align('left'))
child_window_hbox3:add(find_replace_entry, widget_align('right', 'center'))

child_window_hbox4:add(insert_check, widget_align('left', 'center'))
child_window_hbox4:add(insert_entry, widget_align('right', 'center'))

child_window_hbox5:add(spacer2, widget_align('left'))
child_window_hbox5:add(insert_index, widget_align('left', 'center'))

child_window_hbox6:add(trim_check, widget_align('left', 'center'))
child_window_hbox6:add(trim_start_entry, widget_align('left', 'center'))

child_window_hbox7:add(spacer3, widget_align('left'))
child_window_hbox7:add(trim_end_entry, widget_align('left', 'center'))

child_window_hbox8:add(numbering_check, widget_align('left', 'center'))
child_window_hbox8:add(numbering_start, widget_align('left', 'center'))

child_window_hbox9:add(spacer4, widget_align('left'))
child_window_hbox9:add(numbering_delim, widget_align('left', 'center'))

child_window_hbox10:add(go_button, widget_align('right', 'bottom'))
-- Label
child_window_hbox11:add(version_label, widget_align('right', 'bottom'))

-- Construct parent_window_vbox
parent_window_vbox:add(child_window_hbox1)
parent_window_vbox:add(child_window_hbox2)
parent_window_vbox:add(child_window_hbox3)
parent_window_vbox:add(child_window_hbox4)
parent_window_vbox:add(child_window_hbox5)
parent_window_vbox:add(child_window_hbox6)
parent_window_vbox:add(child_window_hbox7)
parent_window_vbox:add(child_window_hbox8)
parent_window_vbox:add(child_window_hbox9)
parent_window_vbox:add(child_window_hbox10)
parent_window_vbox:add(child_window_hbox11)

-- Window Build and Open
window:add(parent_window_vbox)
window:open{
    align = 'center'
}