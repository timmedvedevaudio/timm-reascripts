-- Move selected notes starts OR CC/Program events by +/- N ms
-- If notes are selected: move notes + aligned CC/PC at starts
-- If no notes selected: move selected CC/PC events
-- Author: vibe coded with Gemini

-- USER SETTINGS
local ms_offset = 5      -- amount in ms
local direction = 1      -- +1 = right (later), -1 = left (earlier)

------------------------------------------------------------
-- Setup
local editor = reaper.MIDIEditor_GetActive()
if not editor then return end

reaper.Undo_BeginBlock()

-- Function: ms → ticks for this take
local function ms_to_ticks(ms, take)
    local ppq0 = reaper.MIDI_GetPPQPosFromProjTime(take, 0)
    local ppq_ms = reaper.MIDI_GetPPQPosFromProjTime(take, ms/1000)
    return math.abs(ppq_ms - ppq0)
end

local notes_selected = false

------------------------------------------------------------
-- Pass 1: check if there are selected notes anywhere
local take_idx = 0
while true do
    local take = reaper.MIDIEditor_EnumTakes(editor, take_idx, true)
    if not take then break end

    local i = 0
    while true do
        local retval, sel = reaper.MIDI_GetNote(take, i)
        if not retval then break end
        if sel then
            notes_selected = true
            break
        end
        i = i + 1
    end

    if notes_selected then break end
    take_idx = take_idx + 1
end

------------------------------------------------------------
-- Pass 2: perform operation
take_idx = 0
while true do
    local take = reaper.MIDIEditor_EnumTakes(editor, take_idx, true)
    if not take then break end

    reaper.MIDI_DisableSort(take)
    local tick_offset = ms_to_ticks(ms_offset, take) * direction

    if notes_selected then
        --------------------------------------------------------
        -- Behavior: notes selected → move notes + aligned CC/PC
        local i = 0
        while true do
            local retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
            if not retval then break end

            if sel then
                local new_start = startppq + tick_offset
                if new_start >= 0 and new_start < endppq then
                    reaper.MIDI_SetNote(take, i, true, muted, new_start, endppq, chan, pitch, vel, false)

                    -- Move CCs/PCs exactly at this note start
                    local j = 0
                    while true do
                        local ret, selCC, mutedCC, ppqpos, chanmsg, chan_cc, msg2, msg3 = reaper.MIDI_GetCC(take, j)
                        if not ret then break end
                        if ppqpos == startppq then
                            local new_ppq = ppqpos + tick_offset
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
        --------------------------------------------------------
        -- Behavior: no notes selected → move selected CC/PC
        local j = 0
        while true do
            local ret, selCC, mutedCC, ppqpos, chanmsg, chan_cc, msg2, msg3 = reaper.MIDI_GetCC(take, j)
            if not ret then break end

            if selCC then
                local new_ppq = ppqpos + tick_offset
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

------------------------------------------------------------
reaper.Undo_EndBlock("Move selected notes or CC/PC events by "..(direction*ms_offset).."ms", -1)
