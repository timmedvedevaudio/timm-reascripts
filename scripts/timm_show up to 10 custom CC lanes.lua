-- INSTRUCTIONS:
-- 1. Set 'id' (0-127 for CCs, 128 for Pitch, -1 for Velocity).
-- 2. Set 'h' for height.
-- 3. Set 'name'. Will only affect CC 0-127.
--    - If you write a name (e.g., "Vibrato"), it uses that.
--    - If you leave it EMPTY (""), it restores the standard default name.
-- 4. To DISABLE a slot, set id = nil.

-- Common Lane IDs:
--   0 - 127 = Standard MIDI CCs (e.g., 1=ModWheel, 11=Expression, 64=Sustain)
--   128     = Pitch Bend
--   129     = Program Change
--   130     = Channel Pressure (Aftertouch)
--   131     = Bank/Program Select
--   132     = Text Events
--   133     = Sysex
--   -1      = Velocity

-- CONFIGURATION --------------------------------------------------------

local inline_h = 32 -- Global height for Inline Editor

-- SLOT 1 (Topmost)
local l1_id   = nil       -- 128 for Pitch Bend
local l1_h    = 130
local l1_name = ""        

-- SLOT 2
local l2_id   = -1        -- -1 for Velocity
local l2_h    = 130
local l2_name = "" 

-- SLOT 3
local l3_id   = 1         -- 1 for CC1 Mod Wheel
local l3_h    = 130
local l3_name = ""

-- SLOT 4
local l4_id   = 11        -- 11 for CC11 Expression
local l4_h    = 100
local l4_name = ""        

-- SLOT 5
local l5_id   = nil         -- 8 for Timbre Adjust    
local l5_h    = 100
local l5_name = ""        

-- SLOT 6
local l6_id   = nil       -- 20 for Vibrato Xf
local l6_h    = 100
local l6_name = ""

-- SLOT 7
local l7_id   = nil       -- 3 for Texture Xf
local l7_h    = 100
local l7_name = ""

-- SLOT 8
local l8_id   = nil
local l8_h    = 100
local l8_name = ""

-- SLOT 9
local l9_id   = nil        -- 64 for Sustain Pedal
local l9_h    = 50
local l9_name = ""

-- SLOT 10 (Bottommost)
local l10_id   = 131       -- 131 for Bank/Program Change
local l10_h    = 50
local l10_name = ""
-------------------------------------------------------------------------

-- default names:
local default_cc_names = {
    [0]   = "Bank Select MSB",
    [1]   = "Mod Wheel MSB",
    [2]   = "Breath MSB",
    [4]   = "Foot Pedal MSB",
    [5]   = "Portamento MSB",
    [6]   = "Data Entry MSB",
    [7]   = "Volume MSB",
    [8]   = "Balance MSB",
    [10]  = "Pan Position MSB",
    [11]  = "Expression MSB",
    [12]  = "Control 1 MSB",
    [13]  = "Control 2 MSB",
    [16]  = "GP Slider 1",
    [17]  = "GP Slider 2",
    [18]  = "GP Slider 3",
    [19]  = "GP Slider 4",
    [32]  = "Bank Select LSB",
    [33]  = "Mod Wheel LSB",
    [34]  = "Breath LSB",
    [36]  = "Foot Pedal LSB",
    [37]  = "Portamento LSB",
    [38]  = "Data Entry LSB",
    [39]  = "Volume LSB",
    [40]  = "Balance LSB",
    [42]  = "Pan Position LSB",
    [43]  = "Expression LSB",
    [44]  = "Control 1 LSB",
    [45]  = "Control 2 LSB",
    [64]  = "Hold Pedal (on/off)",
    [65]  = "Portamento (on/off)",
    [66]  = "Sostenuto (on/off)",
    [67]  = "Soft Pedal (on/off)",
    [68]  = "Legato Pedal (on/off)",
    [69]  = "Hold 2 Pedal (on/off)",
    [70]  = "Sound Variation",
    [71]  = "Timbre/Resonance",
    [72]  = "Sound Release",
    [73]  = "Sound Attack",
    [74]  = "Brightness/Cutoff Freq",
    [75]  = "Sound Control 6",
    [76]  = "Sound Control 7",
    [77]  = "Sound Control 8",
    [78]  = "Sound Control 9",
    [79]  = "Sound Control 10",
    [80]  = "GP Button 1 (on/off)",
    [81]  = "GP Button 2 (on/off)",
    [82]  = "GP Button 3 (on/off)",
    [83]  = "GP Button 4 (on/off)",
    [91]  = "Effects Level",
    [92]  = "Tremolo Level",
    [93]  = "Chorus Level",
    [94]  = "Celeste Level",
    [95]  = "Phaser Level",
    [96]  = "Data Button Inc",
    [97]  = "Data Button Dec",
    [98]  = "Non-Reg Parm LSB",
    [99]  = "Non-Reg Parm MSB",
    [100] = "Reg Parm LSB",
    [101] = "Reg Parm MSB"
}

function ResetLanesAndName()
    reaper.Undo_BeginBlock()

    -- Pack variables into a table
    local lane_config = {
        {id=l1_id, h=l1_h, n=l1_name}, {id=l2_id, h=l2_h, n=l2_name}, 
        {id=l3_id, h=l3_h, n=l3_name}, {id=l4_id, h=l4_h, n=l4_name}, 
        {id=l5_id, h=l5_h, n=l5_name}, {id=l6_id, h=l6_h, n=l6_name}, 
        {id=l7_id, h=l7_h, n=l7_name}, {id=l8_id, h=l8_h, n=l8_name}, 
        {id=l9_id, h=l9_h, n=l9_name}, {id=l10_id, h=l10_h, n=l10_name}
    }

    -- Build the VELLANE string
    local new_lane_block = ""
    local active_lanes = 0
    for _, lane in ipairs(lane_config) do
        if lane.id ~= nil then
            new_lane_block = new_lane_block .. string.format("\nVELLANE %d %d %d", lane.id, lane.h, inline_h)
            active_lanes = active_lanes + 1
        end
    end
    if active_lanes == 0 then new_lane_block = "\nVELLANE -1 64 32" end

    -- Loop selected items
    local count = reaper.CountSelectedMediaItems(0)
    for i = 0, count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        
        if take and reaper.TakeIsMIDI(take) then
            -- 1. Handle CC Renaming (Track Level)
            local track = reaper.GetMediaItemTrack(item)
            if track then
                for _, lane in ipairs(lane_config) do
                    -- Check if it's a standard CC (0-127)
                    if lane.id and lane.id >= 0 and lane.id <= 127 then
                        local final_name = lane.n
                        
                        -- LOGIC: If name is empty, try to find default in dictionary
                        if final_name == "" then
                            if default_cc_names[lane.id] then
                                final_name = default_cc_names[lane.id]
                            else
                                -- If no default known (e.g. undefined CC 20), make it empty string to clear any previous custom name
                                final_name = "" 
                            end
                        end
                        
                        -- Apply the name (API uses 128 + CC_ID)
                        reaper.SetTrackMIDINoteNameEx(0, track, 128 + lane.id, 0, final_name)
                    end
                end
            end

            -- 2. Handle Lane Visibility (Item Chunk)
            local _, chunk = reaper.GetItemStateChunk(item, "", false)
            while chunk:find("\nVELLANE [^\n]+") do
                chunk = chunk:gsub("\nVELLANE [^\n]+", "")
            end
            if chunk:find("IGNTEMPO") then
                chunk = chunk:gsub("(IGNTEMPO [^\n]+)", "%1" .. new_lane_block)
            else
                chunk = chunk:gsub(">", new_lane_block .. "\n>", 1)
            end
            reaper.SetItemStateChunk(item, chunk, false)
        end
    end

    reaper.Undo_EndBlock("Reset CC Lanes (Clean Defaults)", -1)
    reaper.UpdateArrange()
end

ResetLanesAndName()
