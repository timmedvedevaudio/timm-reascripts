--[[
ReaScript Name: Double CC Lane Heights
Description: Doubles the height of all currently visible CC lanes for selected items.
Author: Generated based on user request
]]

function DoubleLanes()
    reaper.Undo_BeginBlock()

    local count = reaper.CountSelectedMediaItems(0)
    if count == 0 then return end

    for i = 0, count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        
        if take and reaper.TakeIsMIDI(take) then
            local _, chunk = reaper.GetItemStateChunk(item, "", false)
            
            -- Find every VELLANE line and apply math to the height numbers
            chunk = chunk:gsub("(VELLANE %S+) (%d+) (%d+)", function(prefix, h1, h2)
                -- Calculate new heights
                local new_h1 = math.floor(tonumber(h1) * 2)
                local new_h2 = math.floor(tonumber(h2) * 2)
                
                -- Optional: Cap max height if you want (e.g., math.min(500, new_h1))
                -- Currently uncapped.
                
                return string.format("%s %d %d", prefix, new_h1, new_h2)
            end)
            
            reaper.SetItemStateChunk(item, chunk, false)
        end
    end

    reaper.Undo_EndBlock("Double CC Lane Heights", -1)
    reaper.UpdateArrange()
end

DoubleLanes()
