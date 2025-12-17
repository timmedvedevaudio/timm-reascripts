-- Stretch selected MIDI notes so that they fit into the next beat division
-- First note position is kept, last note end is aligned to next beat

function main()
    -- CONFIGURATION
    -- Tolerance in Quarter Notes (QN). 
    -- 0.05 is roughly 1/20th of a beat. 
    -- If a note is within this range of a beat, it snaps to it for calculation.
    local tolerance = 0.05 

    local editor = reaper.MIDIEditor_GetActive()
    if not editor then return end
    local take = reaper.MIDIEditor_GetTake(editor)
    if not take or not reaper.TakeIsMIDI(take) then return end

    -- Count selected notes
    local _, noteCount = reaper.MIDI_CountEvts(take)
    local selNotes = {}

    for i = 0, noteCount-1 do
        local retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
        if sel then
            table.insert(selNotes, {idx=i, start=startppq, endppq=endppq})
        end
    end

    if #selNotes < 2 then return end

    -- Sort by start position
    table.sort(selNotes, function(a,b) return a.start < b.start end)

    local firstStart = selNotes[1].start
    local lastEnd    = selNotes[#selNotes].endppq

    -- Get beat position for first note
    local firstQN = reaper.MIDI_GetProjQNFromPPQPos(take, firstStart)

    -- SMART GRID DETECTION
    -- 1. Find the nearest whole beat
    local nearestBeat = math.floor(firstQN + 0.5)
    
    -- 2. Determine the "calculation base". 
    -- If we are within tolerance of the nearest beat, use that beat as our anchor.
    -- Otherwise, use the actual messy float value.
    local calculationBaseQN = firstQN
    if math.abs(firstQN - nearestBeat) < tolerance then
        calculationBaseQN = nearestBeat
    end

    -- Find next beat based on the corrected position
    local nextBeatQN = math.floor(calculationBaseQN + 1.0)

    local targetEnd = reaper.MIDI_GetPPQPosFromProjQN(take, nextBeatQN)

    local origSpan = lastEnd - firstStart
    local newSpan  = targetEnd - firstStart
    if origSpan <= 0 then return end

    local scale = newSpan / origSpan

    -- Apply scaling
    reaper.MIDI_DisableSort(take)
    for _, n in ipairs(selNotes) do
        local newStart = firstStart + (n.start - firstStart) * scale
        local newEnd   = firstStart + (n.endppq - firstStart) * scale
        reaper.MIDI_SetNote(take, n.idx, true, nil, newStart, newEnd, nil, nil, nil, true)
    end
    reaper.MIDI_Sort(take)

    reaper.Undo_OnStateChange("Stretch selected notes to next beat")
end

main()
