-- @description Select off-beat notes (Smart Scope)
-- @version 1.2
-- @author vibe coded with Gemini
-- @about
--   Selects off-beat notes and deselects on-beat notes.
--   SMART SCOPE:
--   1. If you have notes selected: It only filters your current selection (deselects the on-beats).
--   2. If you have NOTHING selected: It processes the entire item.

local function ProcessTake(take)
    if not take or not reaper.ValidatePtr(take, "MediaItem_Take*") then return end

    local grid_qn = reaper.MIDI_GetGrid(take)
    if grid_qn <= 0 then return end

    local _, note_count = reaper.MIDI_CountEvts(take)
    
    -- STEP 1: Check if there is an existing selection
    local has_selection = false
    for i = 0, note_count - 1 do
        local _, selected = reaper.MIDI_GetNote(take, i)
        if selected then
            has_selection = true
            break
        end
    end

    -- STEP 2: Process Notes
    for i = 0, note_count - 1 do
        local _, selected, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
        
        -- LOGIC:
        -- If we have a selection, we ONLY touch notes that are already selected.
        -- If the note is unselected in that mode, we skip it entirely.
        -- If we have NO selection, we touch everything.
        if not has_selection or selected then
            
            local note_qn = reaper.MIDI_GetProjQNFromPPQPos(take, startppq)
            local grid_index = math.floor((note_qn / grid_qn) + 0.5)
            
            -- Odd index = Off-beat (Select)
            -- Even index = On-beat (Deselect)
            local should_select = (grid_index % 2 ~= 0)
            
            if selected ~= should_select then
                reaper.MIDI_SetNote(take, i, should_select, nil, nil, nil, nil, nil, nil, true)
            end
        end
    end
    
    reaper.MIDI_Sort(take)
end

function main()
    local editor = reaper.MIDIEditor_GetActive()
    if not editor then return end

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    local i = 0
    while true do
        local take = reaper.MIDIEditor_EnumTakes(editor, i, true)
        if not take then break end
        ProcessTake(take)
        i = i + 1
    end

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Select off-beat notes (Smart)", -1)
end

main()
