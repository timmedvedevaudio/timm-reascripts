-- Select Next Note Right.lua
-- Author: timm vibe coded with Gemini
-- Description: Deselects current notes and selects the next single note to the right (chronologically).

function SelectNextNote()
    local midi_editor = reaper.MIDIEditor_GetActive()
    if not midi_editor then return end

    local take = reaper.MIDIEditor_GetTake(midi_editor)
    if not take then return end

    local note_count = reaper.MIDI_CountEvts(take)
    if note_count == 0 then return end

    local last_selected_index = -1
    local any_selected = false

    -- Find last selected note
    for i = 0, note_count - 1 do
        local _, selected = reaper.MIDI_GetNote(take, i)
        if selected then
            last_selected_index = i
            any_selected = true
        end
    end

    local target_note_index = -1

    if not any_selected then
        target_note_index = 0
    else
        if last_selected_index < note_count - 1 then
            target_note_index = last_selected_index + 1
        else
            return -- Already at the last note
        end
    end

    reaper.MIDI_DisableSort(take)
    reaper.MIDIEditor_OnCommand(midi_editor, 40214) -- Deselect all

    -- Select the target note
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
SelectNextNote()
reaper.Undo_EndBlock("Select Next Note Right", -1)
