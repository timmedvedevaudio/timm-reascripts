--[[
ReaScript Name: Toggle Specific CC Lane for Selected Items
Description: Toggles the visibility of a specific CC lane (defined in config) for all selected items.
Author: vibe coded with Gemini based on genius script by Julian Sader
]]

-- CONFIGURATION --------------------------------------------------------
-- Common Lane IDs:
--   0 - 127 = Standard MIDI CCs (e.g., 1=ModWheel, 11=Expression, 64=Sustain)
--   128     = Pitch Bend
--   129     = Program Change
--   130     = Channel Pressure (Aftertouch)
--   131     = Bank/Program Select
--   132     = Text Events
--   133     = Sysex
--   -1      = Velocity

local lane_id       = 11 -- The ID of the lane to toggle
local editor_height = 95  -- Height of the lane in the main MIDI Editor (pixels)
local inline_height = 32  -- Height of the lane in the Inline Editor (pixels)
-------------------------------------------------------------------------

function ToggleCCLane()
    reaper.Undo_BeginBlock()

    -- Loop through all selected items
    local count = reaper.CountSelectedMediaItems(0)
    if count == 0 then return end

    for i = 0, count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        
        -- Check if it is a MIDI item
        local take = reaper.GetActiveTake(item)
        if take and reaper.TakeIsMIDI(take) then
            
            -- Get the Item State Chunk
            local _, chunk = reaper.GetItemStateChunk(item, "", false)
            
            -- Define the search pattern for this specific lane ID
            -- Pattern: VELLANE [ID] [Height1] [Height2]
            local pattern = string.format("VELLANE %d [%%d]+ [%%d]+", lane_id)
            
            if chunk:find(pattern) then
                -- HIDE: The lane exists, so we remove it
                chunk = chunk:gsub("\n" .. pattern, "")
                chunk = chunk:gsub(pattern, "") -- Fallback cleanup for edge cases
            else
                -- SHOW: The lane does not exist, so we add it using your config variables
                local new_lane_string = string.format("\nVELLANE %d %d %d", lane_id, editor_height, inline_height)
                
                -- Insert this new lane definition after the IGNTEMPO tag
                if chunk:find("IGNTEMPO") then
                    chunk = chunk:gsub("(IGNTEMPO [%d]+ [%d]+)", "%1" .. new_lane_string)
                else
                    -- Fallback if IGNTEMPO is missing
                    chunk = chunk:gsub(">", new_lane_string .. "\n>", 1)
                end
            end
            
            -- Apply the modified chunk back to the item
            reaper.SetItemStateChunk(item, chunk, false)
        end
    end

    reaper.Undo_EndBlock("Toggle CC Lane Visibility", -1)
    reaper.UpdateArrange()
end

ToggleCCLane()
