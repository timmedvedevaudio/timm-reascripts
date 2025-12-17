-- Move selected notes starts OR CC/Program events by +/- N ms
-- If notes are selected: move notes + aligned CC/PC at starts
-- If no notes selected: move selected CC/PC events
-- Author: vibe coded with Gemini
-- Updated: Fix overlapping notes on left-move (Legato fix)

-- USER SETTINGS
local ms_offset = 5      -- amount in ms
local direction = -1      -- +1 = right (later), -1 = left (earlier)

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
    
    -- Count events for a deterministic loop
    local _, num_notes, _, _ = reaper.MIDI_CountEvts(take)

    if notes_selected then
        --------------------------------------------------------
        -- Behavior: notes selected → move notes + aligned CC/PC
        
        -- Table to track the index of the previous note for each pitch [0-127]
        local last_note_idx_map = {}

        for i = 0, num_notes - 1 do
            local retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
            if not retval then break end

            if sel then
                local new_start = startppq + tick_offset
                
                -- Ensure we don't move before start of item
                if new_start < 0 then new_start = 0 end

                -- Safety check to ensure we don't invert the note (start > end)
                if new_start < endppq then
                    
                    -- 1. MOVE CURRENT NOTE (Extend Start Left)
                    reaper.MIDI_SetNote(take, i, true, muted, new_start, endppq, chan, pitch, vel, false)

                    -- 2. FIX OVERLAP (Only if moving Left)
                    if tick_offset < 0 then
                        local prev_idx = last_note_idx_map[pitch]
                        if prev_idx then
                            -- Get the previous note's details to check its END position
                            local p_ret, p_sel, p_mut, p_start, p_end, p_chan, p_pitch, p_vel = reaper.MIDI_GetNote(take, prev_idx)
                            
                            -- If previous note ends AFTER our new start, trim it
                            if p_end > new_start then
                                -- Ensure we don't trim it past its own start
                                local new_prev_end = math.max(p_start, new_start)
                                reaper.MIDI_SetNote(take, prev_idx, p_sel, p_mut, p_start, new_prev_end, p_chan, p_pitch, p_vel, false)
                            end
                        end
                    end

                    -- 3. MOVE ALIGNED CCs
                    local j = 0
                    while true do
                        local ret, selCC, mutedCC, ppqpos, chanmsg, chan_cc, msg2, msg3 = reaper.MIDI_GetCC(take, j)
                        if not ret then break end
                        -- Check against ORIGINAL startppq
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

            -- Register this note as the "last seen" note for this pitch
            last_note_idx_map[pitch] = i
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
reaper.Undo_EndBlock("Move selected notes/CCs (Legato fix)", -1)
