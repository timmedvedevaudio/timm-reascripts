--[[
ReaScript Name: Halve CC Lane Heights
Description: Reduces the height of all currently visible CC lanes by 50% for selected items.
Author: Generated based on user request
]]

function HalveLanes()
    reaper.Undo_BeginBlock()

    local count = reaper.CountSelectedMediaItems(0)
    if count == 0 then return end

    for i = 0, count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        
        if take and reaper.TakeIsMIDI(take) then
            local _, chunk = reaper.GetItemStateChunk(item, "", false)
            
            -- Pattern explanation:
            -- (VELLANE %S+) -> Captures "VELLANE" and the ID (e.g., "VELLANE 128")
            -- (%d+)         -> Captures the Editor Height
            -- (%d+)         -> Captures the Inline Height
            chunk = chunk:gsub("(VELLANE %S+) (%d+) (%d+)", function(prefix, h1, h2)
                -- Calculate new heights
                local new_h1 = math.floor(tonumber(h1) / 2)
                local new_h2 = math.floor(tonumber(h2) / 2)
                
                -- Safety clamp: Don't let them get smaller than 8 pixels
                new_h1 = math.max(8, new_h1)
                new_h2 = math.max(8, new_h2)
                
                return string.format("%s %d %d", prefix, new_h1, new_h2)
            end)
            
            reaper.SetItemStateChunk(item, chunk, false)
        end
    end

    reaper.Undo_EndBlock("Halve CC Lane Heights", -1)
    reaper.UpdateArrange()
end

HalveLanes()
