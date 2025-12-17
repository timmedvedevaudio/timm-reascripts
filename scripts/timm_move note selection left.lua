-- Select Previous Note Left.lua
-- Author: vibe coded with Gemini
-- Description: Deselects current notes and selects the previous single note to the left.

function SelectPreviousNote()
    local midi_editor = reaper.MIDIEditor_GetActive()
    if not midi_editor then return end

    local take = reaper.MIDIEditor_GetTake(midi_editor)
    if not take then return end

    local note_count = reaper.MIDI_CountEvts(take)
    if note_count == 0 then return end

    local first_selected_index = -1
    local any_selected = false

    -- Find first selected note
    for i = 0, note_count - 1 do
        local _, selected = reaper.MIDI_GetNote(take, i)
        if selected then
            first_selected_index = i
            any_selected = true
            break
        end
    end

    local target_note_index = -1

    if not any_selected then
        target_note_index = note_count - 1
    else
        if first_selected_index > 0 then
            target_note_index = first_selected_index - 1
        else
            return -- Already at the first note
        end
    end

    reaper.MIDI_DisableSort(take)
    reaper.MIDIEditor_OnCommand(midi_editor, 40214) -- Deselect all

    local retval, selected, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, target_note_index)

    if retval then
        reaper.MIDI_SetNote(take, target_note_index, true, muted, startppq, endppq, chan, pitch, vel, true)
        
        -- FIX: Use Native Action to move cursor to the selected note
        -- 40440 = Navigate: Move edit cursor to start of selected events
        reaper.MIDIEditor_OnCommand(midi_editor, 40440)
    end

    reaper.MIDI_Sort(take)
end

reaper.Undo_BeginBlock()
SelectPreviousNote()
reaper.Undo_EndBlock("Select Previous Note Left", -1)
