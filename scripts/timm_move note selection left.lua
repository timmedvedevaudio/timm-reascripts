-- Select Previous Note Left.lua
-- Author: vibe coded with Gemini
-- Description: Deselects current notes and selects the previous single note to the left.

function SelectPreviousNote()
    -- Get the active MIDI editor
    local midi_editor = reaper.MIDIEditor_GetActive()
    if not midi_editor then return end

    -- Get the current take being edited
    local take = reaper.MIDIEditor_GetTake(midi_editor)
    if not take then return end

    -- Count total notes in the take
    local _, note_count = reaper.MIDI_CountEvts(take)
    if note_count == 0 then return end

    -- 1. Find the "Left-Most" selected note
    -- We need to find the selected note with the lowest index
    local first_selected_index = -1
    local any_selected = false

    for i = 0, note_count - 1 do
        local _, selected, _, _, _, _, _, _ = reaper.MIDI_GetNote(take, i)
        if selected then
            first_selected_index = i
            any_selected = true
            break -- We found the first one, no need to check the rest
        end
    end

    -- 2. Determine which note to select next
    local target_note_index = -1

    if not any_selected then
        -- If nothing is selected, select the very last note (logical reverse of the other script)
        target_note_index = note_count - 1
    else
        -- If something is selected, select the previous note (index - 1)
        if first_selected_index > 0 then
            target_note_index = first_selected_index - 1
        else
            -- If the first note (index 0) is already selected, do nothing
            return 
        end
    end

    -- 3. Apply the Selection
    reaper.MIDI_DisableSort(take)

    -- Deselect all notes (Command ID 40214)
    reaper.MIDIEditor_OnCommand(midi_editor, 40214)

    -- Select the target note
    local retval, selected, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, target_note_index)
    reaper.MIDI_SetNote(take, target_note_index, true, muted, startppq, endppq, chan, pitch, vel, true)

    -- Optional: Move cursor to the start of the new note
    -- reaper.SetEditCurPos(reaper.MIDI_GetProjTimeFromPPQ(take, startppq), true, false)

    reaper.MIDI_Sort(take)
end

reaper.Undo_BeginBlock()
SelectPreviousNote()
reaper.Undo_EndBlock("Select Previous Note Left", -1)
