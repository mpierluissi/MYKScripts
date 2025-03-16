-- @description MYKScripts Track Renamer
-- @author MYK
-- @version 2025.2.1
-- @changelog
--      + Simplified widget creation helper functions
--      + Made the script more readable
--      + Reduced overall code size
--  v2025.2.1
--      + Variable optimization
--  v2024.4.1
--      + Initial Release
-- @about
--  Single or batch renaming of tracks
--  
--  Requires [REAPER Toolkit GUI library](https://reapertoolkit.dev/index.html).

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
local function new_container(initializer, s, p, w, h, t)
    return initializer {
        spacing = s,
        w = w,
        h = h,
        padding = p,
    }
end

-- Spacer
local function new_spacer(w)
    return rtk.Spacer {
        w = w,
    }
end

-- CheckBox
local function new_checkbox(str)
    return rtk.CheckBox {
        tostring(str),
    }
end

-- Entry
local function new_entry(placeholder, w)
    return rtk.Entry {
        placeholder = tostring(placeholder),
        w = w,
    }
end

-- Button
local function new_button(text, w)
    return rtk.Button {
        tostring(text),
        w = w
    }
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
                local new_track_name = ''
                if insert_var == -1 then
                    new_track_name = track_name .. insert_str
                else
                    new_track_name = track_name:sub(1, insert_var) .. insert_str .. track_name:sub(insert_var + 1, #track_name)
                end
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
-- Widgets
-- Widgets --
-- Window
local window = rtk.Window {
    title = 'Rename Tracks',
    resizable = false,
}

-- Box
local widget_box = new_container(rtk.VBox, 10, nil, 400)
local replace_hbox = new_container(rtk.HBox, nil, 10)
local find_hbox = new_container(rtk.HBox, nil, 10)
local find_replace_hbox = new_container(rtk.HBox, nil, 10)
local insert_str_hbox = new_container(rtk.HBox, nil, 10)
local insert_idx_hbox = new_container(rtk.HBox, nil, 10)
local trim_start_hbox = new_container(rtk.HBox, nil, 10)
local trim_end_hbox = new_container(rtk.HBox, nil, 10)
local numbering_start_hbox = new_container(rtk.HBox, nil, 10)
local numbering_end_hbox = new_container(rtk.HBox, nil, 10)
local button_hbox = new_container(rtk.HBox, nil, 10)

-- Replace
local replace_check = new_checkbox('Replace')
local replace_entry = new_entry('New track name', 1)

-- Find and Replace
local find_check = new_checkbox('Find and Replace')
local find_entry = new_entry('Find', 1)
local find_replace_entry = new_entry('Replace', 1)

-- Insert
local insert_check = new_checkbox('Insert at Index')
local insert_entry = new_entry('Insertion', 1)
local insert_index = new_entry('Index (#)', .5)

-- Trim
local trim_check = new_checkbox('Trim From')
local trim_start_entry = new_entry('Start (#)', .5)
local trim_end_entry = new_entry('End (#)', .5)

-- Numbering
local numbering_check = new_checkbox('Numbering')
local numbering_start = new_entry('Start (#)', .5)
local numbering_delim = new_entry('Delimiter', .5)

-- Button
local go_button = new_button('Go', .25)

-- Spacers
local spacer = rtk.Spacer(new_spacer(.5))
-- /Widgets --

-- Checkbox fill
replace_hbox:add(replace_check, widget_align('left', 'center'))
replace_hbox:add(replace_entry, widget_align('right', 'center'))

find_hbox:add(find_check, widget_align('left', 'center'))
find_hbox:add(find_entry, widget_align('right', 'center'))

find_replace_hbox:add(spacer, widget_align('left'))
find_replace_hbox:add(find_replace_entry, widget_align('right', 'center'))

insert_str_hbox:add(insert_check, widget_align('left', 'center'))
insert_str_hbox:add(insert_entry, widget_align('right', 'center'))

insert_idx_hbox:add(spacer, widget_align('left'))
insert_idx_hbox:add(insert_index, widget_align('left', 'center'))

trim_start_hbox:add(trim_check, widget_align('left', 'center'))
trim_start_hbox:add(trim_start_entry, widget_align('left', 'center'))

trim_end_hbox:add(spacer, widget_align('left'))
trim_end_hbox:add(trim_end_entry, widget_align('left', 'center'))

numbering_start_hbox:add(numbering_check, widget_align('left', 'center'))
numbering_start_hbox:add(numbering_start, widget_align('left', 'center'))

numbering_end_hbox:add(spacer, widget_align('left'))
numbering_end_hbox:add(numbering_delim, widget_align('left', 'center'))

button_hbox:add(go_button, widget_align('right', 'bottom'))

-- Construct widget_box
widget_box:add(replace_hbox)
widget_box:add(find_hbox)
widget_box:add(find_replace_hbox)
widget_box:add(insert_str_hbox)
widget_box:add(insert_idx_hbox)
widget_box:add(trim_start_hbox)
widget_box:add(trim_end_hbox)
widget_box:add(numbering_start_hbox)
widget_box:add(numbering_end_hbox)
widget_box:add(button_hbox)

-- GUI Interaction
-- Checkmark interaction
local disable_bool = false

local function checkbox_onchange_focus(w, w2)
    w.onchange = function(self, event)
        if not disable_bool then
            w2:focus()
        else
            replace_entry:focus()
        end
    end
end

replace_check.onchange = function(self, event)
    if not disable_bool then
        disable_bool = true
    else
        disable_bool = false
    end

    find_entry.disabled = disable_bool
    find_replace_entry.disabled = disable_bool
    insert_entry.disabled = disable_bool
    insert_index.disabled = disable_bool
    trim_start_entry.disabled = disable_bool
    trim_end_entry.disabled = disable_bool
    numbering_start.disabled = disable_bool
    numbering_delim.disabled = disable_bool

    replace_entry:focus()
end

checkbox_onchange_focus(find_check, find_entry)
checkbox_onchange_focus(insert_check, insert_entry)
checkbox_onchange_focus(trim_check, trim_start_entry)
checkbox_onchange_focus(numbering_check, numbering_start)

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

-- Tab Key
window.onkeypress = function(self, event)
    if event.keycode == rtk.keycodes.TAB and event.shift == false then
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

    if event.shift then
        if replace_entry:focused() then
            numbering_delim:focus()
        elseif find_entry:focused() then
            replace_entry:focus()
        elseif find_replace_entry:focused() then
            find_entry:focus()
        elseif insert_entry:focused() then
            find_replace_entry:focus()
        elseif insert_index:focused() then
            insert_entry:focus()
        elseif trim_start_entry:focused() then
            insert_index:focus()
        elseif trim_end_entry:focused() then
            trim_start_entry:focus()
        elseif numbering_start:focused() then
            trim_end_entry:focus()
        elseif numbering_delim:focused() then
            numbering_start:focus()
        end
    end
end

-- Window Build and Open
window:add(widget_box)
window:open{
    align = 'center'
}

replace_entry:focus()