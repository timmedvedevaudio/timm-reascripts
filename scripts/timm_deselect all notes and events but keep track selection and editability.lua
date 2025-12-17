-- @description Global MIDI Deselect (Keep Track Selection)
-- @version 2.0
-- @author vibe coded with Gemini

-- Optimize performance by stopping UI updates while script runs
reaper.PreventUIRefresh(1)

-- Start Undo Block
reaper.Undo_BeginBlock()

-- 1. Count all tracks in the current project
local track_count = reaper.CountTracks(0)

-- 2. Loop through every track
for i = 0, track_count - 1 do
    local track = reaper.GetTrack(0, i)
    local item_count = reaper.CountTrackMediaItems(track)

    -- 3. Loop through every item on the track
    for j = 0, item_count - 1 do
        local item = reaper.GetTrackMediaItem(track, j)
        local take = reaper.GetActiveTake(item)

        -- 4. Check if the Active Take exists and is MIDI
        if take and reaper.TakeIsMIDI(take) then
            -- 5. Force deselect all events (Notes, CC, SysEx) in this take
            -- The 'false' argument clears the selection
            reaper.MIDI_SelectAll(take, false)
        end
    end
end

-- End Undo Block
reaper.Undo_EndBlock("Deselect all MIDI globally", -1)

-- Restore UI and force a refresh
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
