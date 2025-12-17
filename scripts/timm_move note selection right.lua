-- Select Next Note Right.lua
-- Author: timm vibe coded with Gemini
-- Description: Deselects current notes and selects the next single note to the right (chronologically).

function SelectNextNote()
    -- Get the active MIDI editor
    local midi_editor = reaper.MIDIEditor_GetActive()
    if not midi_editor then return end

    -- Get the current take being edited
    local take = reaper.MIDIEditor_GetTake(midi_editor)
    if not take then return end

    -- Count total notes in the take
    local _, note_count = reaper.MIDI_CountEvts(take)
    if note_count == 0 then return end

    -- 1. Find the "Right-Most" selected note
    -- We need to find the selected note with the highest index or latest start position
    local last_selected_index = -1
    local any_selected = false

    -- Iterate through all notes to find the last selected one
    for i = 0, note_count - 1 do
        local _, selected, _, _, _, _, _, _ = reaper.MIDI_GetNote(take, i)
        if selected then
            last_selected_index = i
            any_selected = true
        end
    end

    -- 2. Determine which note to select next
    local target_note_index = -1

    if not any_selected then
        -- If nothing is selected, select the very first note
        target_note_index = 0
    else
        -- If something is selected, select the next note (index + 1)
        if last_selected_index < note_count - 1 then
            target_note_index = last_selected_index + 1
        else
            -- If the last note is already selected, do nothing or keep it selected
            -- Remove this 'return' if you want it to loop back to start (optional)
            return 
        end
    end

    -- 3. Apply the Selection
    reaper.MIDI_DisableSort(take) -- Prevent sorting issues during edits

    -- Deselect all notes first
    reaper.MIDIEditor_OnCommand(midi_editor, 40214)

    -- Select the target note
    local retval, selected, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, target_note_index)
    reaper.MIDI_SetNote(take, target_note_index, true, muted, startppq, endppq, chan, pitch, vel, true)
    
    -- Optional: Move cursor to the start of the new note
reaper.SetEditCurPos(reaper.MIDI_GetProjTimeFromPPQ(take, startppq), true, false)

    reaper.MIDI_Sort(take)
end

-- Begin Undo Block so this action can be undone in one step
reaper.Undo_BeginBlock()
SelectNextNote()
reaper.Undo_EndBlock("Select Next Note Right", -1)
