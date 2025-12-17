-- @description Create 4 copies of selected notes (descending 4ths)
-- @version 1.0
-- @author vibe coded with Gemini

function main()
    -- Get the active MIDI editor and the current take
    local midi_editor = reaper.MIDIEditor_GetActive()
    if not midi_editor then return end
    
    local take = reaper.MIDIEditor_GetTake(midi_editor)
    if not take or not reaper.ValidatePtr2(0, take, "MediaItem_Take*") then return end

    -- Start Undo Block
    reaper.Undo_BeginBlock()

    -- 1. Collect selected notes first
    -- We do this to avoid issues with note indices changing while we insert new notes
    local notes_to_process = {}
    local idx = -1
    
    while true do
        idx = reaper.MIDI_EnumSelNotes(take, idx)
        if idx == -1 then break end
        
        local retval, selected, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, idx)
        
        table.insert(notes_to_process, {
            muted = muted,
            startppq = startppq,
            endppq = endppq,
            chan = chan,
            pitch = pitch,
            vel = vel
        })
    end

    -- If no notes selected, exit
    if #notes_to_process == 0 then
        reaper.Undo_EndBlock("Create 4ths below", -1)
        return
    end

    -- 2. Create the copies
    for _, note in ipairs(notes_to_process) do
        for i = 1, 4 do
            -- Calculate new pitch (5 semitones down per iteration)
            local new_pitch = note.pitch - (5 * i)
            
            -- Only insert if the pitch is valid (0-127)
            if new_pitch >= 0 then
                reaper.MIDI_InsertNote(
                    take,
                    false,          -- selected (set to false so we don't process them if run again immediately)
                    note.muted,
                    note.startppq,
                    note.endppq,
                    note.chan,
                    new_pitch,
                    note.vel,
                    true            -- noSort (true for speed, we sort at the end)
                )
            end
        end
    end

    -- 3. Finalize
    reaper.MIDI_Sort(take) -- Sort events (required after using noSort=true)
    reaper.Undo_EndBlock("Create 4ths below", -1)
end

-- Run the function
main()
