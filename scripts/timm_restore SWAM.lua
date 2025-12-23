-- WORKFLOW SETTINGS ----------------------------------------------------

-- 1. LEFT DRAG BEHAVIOR
--    true  = Insert note, drag to edit VELOCITY (IDs 19 & 18)
--    false = Insert note, drag to EXTEND/PITCH (IDs 1 & 2 - Default)
local adjust_velocity_drag = false

-- 2. PIANO ROLL MODE
--    true  = Drum Map (Named Notes) + Hide unused rows
--    false = Standard Piano Roll + Show all rows
local drum_mode = false

-------------------------------------------------------------------------

-- CC LANE CONFIGURATION ------------------------------------------------
local inline_h = 32 -- Global height for Inline Editor

-- SLOT 1 (Topmost)
local l1_id   = 128       -- 128 for Pitch Bend
local l1_h    = 110
local l1_name = ""        

-- SLOT 2
local l2_id   = -1        -- -1 for Velocity
local l2_h    = 110
local l2_name = "" 

-- SLOT 3
local l3_id   = 1         -- 1 for CC1 Mod Wheel
local l3_h    = 120
local l3_name = ""

-- SLOT 4
local l4_id   = 11        -- 11 for CC11 Expression
local l4_h    = 70
local l4_name = "Vibrato Amount"

-- SLOT 5
local l5_id   = 19        
local l5_h    = 70
local l5_name = "Vibrato Rate"

-- SLOT 6
local l6_id   = 23     -- 20 for Vibrato Xf
local l6_h    = 70
local l6_name = "Growl"

-- SLOT 7
local l7_id   = 21     -- 3 for Texture Xf
local l7_h    = 70
local l7_name = "Flutter"

-- SLOT 8
local l8_id   = 26
local l8_h    = 70
local l8_name = "Mute Control"

-- SLOT 9
local l9_id   = nil        -- 64 for Sustain Pedal
local l9_h    = 50
local l9_name = ""

-- SLOT 10 (Bottommost)
local l10_id   = 131       -- 131 for Bank/Program Change
local l10_h    = 50
local l10_name = ""
-------------------------------------------------------------------------

-- REAPER DEFAULT NAME DICTIONARY
local default_cc_names = {
    [0]="Bank Select MSB", [1]="Mod Wheel MSB", [2]="Breath MSB", [4]="Foot Pedal MSB", 
    [5]="Portamento MSB", [6]="Data Entry MSB", [7]="Volume MSB", [8]="Balance MSB", 
    [10]="Pan Position MSB", [11]="Expression MSB", [12]="Control 1 MSB", [13]="Control 2 MSB",
    [16]="GP Slider 1", [17]="GP Slider 2", [18]="GP Slider 3", [19]="GP Slider 4",
    [32]="Bank Select LSB", [33]="Mod Wheel LSB", [34]="Breath LSB", [36]="Foot Pedal LSB",
    [37]="Portamento LSB", [38]="Data Entry LSB", [39]="Volume LSB", [40]="Balance LSB",
    [42]="Pan Position LSB", [43]="Expression LSB", [44]="Control 1 LSB", [45]="Control 2 LSB",
    [64]="Hold Pedal (on/off)", [65]="Portamento (on/off)", [66]="Sostenuto (on/off)", 
    [67]="Soft Pedal (on/off)", [68]="Legato Pedal (on/off)", [69]="Hold 2 Pedal (on/off)",
    [70]="Sound Variation", [71]="Timbre/Resonance", [72]="Sound Release", [73]="Sound Attack", 
    [74]="Brightness/Cutoff Freq", [75]="Sound Control 6", [76]="Sound Control 7", 
    [77]="Sound Control 8", [78]="Sound Control 9", [79]="Sound Control 10",
    [80]="GP Button 1 (on/off)", [81]="GP Button 2 (on/off)", [82]="GP Button 3 (on/off)", 
    [83]="GP Button 4 (on/off)",
    [91]="Effects Level", [92]="Tremolo Level", [93]="Chorus Level", [94]="Celeste Level", 
    [95]="Phaser Level", [96]="Data Button Inc", [97]="Data Button Dec", 
    [98]="Non-Reg Parm LSB", [99]="Non-Reg Parm MSB", [100]="Reg Parm LSB", [101]="Reg Parm MSB"
}

function Main()
    reaper.Undo_BeginBlock()
    
    -- STEP 1: SET MOUSE MODIFIERS (Fixed IDs) ---------------------------
    -- Context 26 (MIDI piano roll left drag) via string 'MM_CTX_MIDI_PIANOROLL'
    local ctx = 'MM_CTX_MIDI_PIANOROLL'
    
    if adjust_velocity_drag then
        -- TRUE: Insert note, drag to edit VELOCITY
        -- 19 = Insert note, drag to edit velocity
        -- 35 = Insert note ignoring snap, drag to edit velocity
        reaper.SetMouseModifier(ctx, 0, '19 m')  
        reaper.SetMouseModifier(ctx, 1, '18 m') 
    else
        -- FALSE: Insert note, drag to EXTEND/PITCH (Default)
        -- 1 = Insert note, drag to extend or change pitch
        -- 2 = Insert note ignoring snap, drag to extend or change pitch
        reaper.SetMouseModifier(ctx, 0, '1 m')  
        reaper.SetMouseModifier(ctx, 1, '2 m')  
    end

    -- STEP 2: MIDI EDITOR MODES & HOUSEKEEPING --------------------------
    local editor = reaper.MIDIEditor_GetActive()
    
    if editor then
        -- HOUSEKEEPING
        reaper.MIDIEditor_OnCommand(editor, 40738) -- View: Color notes by velocity
        reaper.MIDIEditor_OnCommand(editor, 41295) -- Set note length to grid
        
        if drum_mode then
            -- DRUM MODE
            reaper.MIDIEditor_OnCommand(editor, 40043) -- Mode: Named notes
            reaper.MIDIEditor_OnCommand(editor, 40454) -- View: Hide unused/unnamed note rows
        else
            -- PIANO ROLL MODE
            reaper.MIDIEditor_OnCommand(editor, 40042) -- Mode: Piano roll
            reaper.MIDIEditor_OnCommand(editor, 40452) -- View: Show all note rows
        end
    end

    -- STEP 3: RESET CC LANES --------------------------------------------
    local lane_config = {
        {id=l1_id, h=l1_h, n=l1_name}, {id=l2_id, h=l2_h, n=l2_name}, 
        {id=l3_id, h=l3_h, n=l3_name}, {id=l4_id, h=l4_h, n=l4_name}, 
        {id=l5_id, h=l5_h, n=l5_name}, {id=l6_id, h=l6_h, n=l6_name}, 
        {id=l7_id, h=l7_h, n=l7_name}, {id=l8_id, h=l8_h, n=l8_name}, 
        {id=l9_id, h=l9_h, n=l9_name}, {id=l10_id, h=l10_h, n=l10_name}
    }

    local new_lane_block = ""
    local active_lanes = 0
    for _, lane in ipairs(lane_config) do
        if lane.id ~= nil then
            new_lane_block = new_lane_block .. string.format("\nVELLANE %d %d %d", lane.id, lane.h, inline_h)
            active_lanes = active_lanes + 1
        end
    end
    if active_lanes == 0 then new_lane_block = "\nVELLANE -1 64 32" end

    local count = reaper.CountSelectedMediaItems(0)
    for i = 0, count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        if take and reaper.TakeIsMIDI(take) then
            -- Renaming (Track Level)
            local track = reaper.GetMediaItemTrack(item)
            if track then
                for _, lane in ipairs(lane_config) do
                    if lane.id and lane.id >= 0 and lane.id <= 127 then
                        local final_name = lane.n
                        if final_name == "" then
                            final_name = default_cc_names[lane.id] or ""
                        end
                        reaper.SetTrackMIDINoteNameEx(0, track, 128 + lane.id, 0, final_name)
                    end
                end
            end
            -- Lane Visibility (Chunk Level)
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

    reaper.Undo_EndBlock("Setup MIDI Editor (Fixed IDs)", -1)
    reaper.UpdateArrange()
end

Main()
