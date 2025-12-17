-- Auto-align selected notes or CC/Program events to nearest grid
-- If notes are selected: align notes + aligned CC/PC
-- If no notes selected: align selected CC/PC events
-- Author: vibe coded with chat gpt

-- Get active MIDI editor
local editor = reaper.MIDIEditor_GetActive()
if not editor then return end

reaper.Undo_BeginBlock()

local notes_selected = false
local first_event_start = nil
local first_event_take = nil
local is_note_target = false

------------------------------------------------------------
-- Pass 1: Find earliest selected event (note or CC/PC)
local take_idx = 0
while true do
    local take = reaper.MIDIEditor_EnumTakes(editor, take_idx, true)
    if not take then break end

    -- Check notes
    local i = 0
    while true do
        local retval, sel, _, startppq = reaper.MIDI_GetNote(take, i)
        if not retval then break end
        if sel then
            notes_selected = true
            if not first_event_start or startppq < first_event_start then
                first_event_start = startppq
                first_event_take = take
                is_note_target = true
            end
        end
        i = i + 1
    end

    -- Check CC/PC (only if no notes selected yet)
    if not notes_selected then
        local j = 0
        while true do
            local ret, selCC, _, ppqpos = reaper.MIDI_GetCC(take, j)
            if not ret then break end
            if selCC then
                if not first_event_start or ppqpos < first_event_start then
                    first_event_start = ppqpos
                    first_event_take = take
                    is_note_target = false
                end
            end
            j = j + 1
        end
    end

    take_idx = take_idx + 1
end

if not first_event_start then return end -- nothing selected

------------------------------------------------------------
-- Pass 2: Find nearest grid line
local proj_time = reaper.MIDI_GetProjTimeFromPPQPos(first_event_take, first_event_start)
local grid_time = reaper.BR_GetClosestGridDivision(proj_time)
local grid_ppq = reaper.MIDI_GetPPQPosFromProjTime(first_event_take, grid_time)

local offset = grid_ppq - first_event_start
if offset == 0 then return end -- already aligned

------------------------------------------------------------
-- Pass 3: Apply offset
take_idx = 0
while true do
    local take = reaper.MIDIEditor_EnumTakes(editor, take_idx, true)
    if not take then break end

    reaper.MIDI_DisableSort(take)

    if is_note_target then
        -- Behavior: notes selected → align notes + aligned CC/PC
        local i = 0
        while true do
            local retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
            if not retval then break end

            if sel then
                local new_start = startppq + offset
                if new_start >= 0 and new_start < endppq then
                    reaper.MIDI_SetNote(take, i, true, muted, new_start, endppq, chan, pitch, vel, false)

                    -- Move CC/PC exactly at note start
                    local j = 0
                    while true do
                        local ret, selCC, mutedCC, ppqpos, chanmsg, chan_cc, msg2, msg3 = reaper.MIDI_GetCC(take, j)
                        if not ret then break end
                        if ppqpos == startppq then
                            local new_ppq = ppqpos + offset
                            if new_ppq >= 0 then
                                reaper.MIDI_SetCC(take, j, selCC, mutedCC, new_ppq, chanmsg, chan_cc, msg2, msg3, false)
                            end
                        end
                        j = j + 1
                    end
                end
            end
            i = i + 1
        end
    else
        -- Behavior: only CC/PC selected → align them
        local j = 0
        while true do
            local ret, selCC, mutedCC, ppqpos, chanmsg, chan_cc, msg2, msg3 = reaper.MIDI_GetCC(take, j)
            if not ret then break end
            if selCC then
                local new_ppq = ppqpos + offset
                if new_ppq >= 0 then
                    reaper.MIDI_SetCC(take, j, true, mutedCC, new_ppq, chanmsg, chan_cc, msg2, msg3, false)
                end
            end
            j = j + 1
        end
    end

    reaper.MIDI_Sort(take)
    take_idx = take_idx + 1
end

reaper.Undo_EndBlock("Align selected notes/CC/PC to nearest grid", -1)
