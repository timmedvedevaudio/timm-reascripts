--[[
ReaScript Name: Set MIDI Editor to Velocity Mode (Linked)
Description: Sets Left Drag to Velocity Edit (19/18). Force-updates toolbar state.
]]

-- PASTE THE COMMAND ID OF THE *OTHER* SCRIPT (MELODIC MODE) HERE:
-- Example: local other_script_id = "_RS1234567890abcdef"
local other_script_id = "_RS7d3c_b24f742b833f5d035609e12034a306eb2ddb76ff" 
---------------------------------------------------------------------

local ctx = 'MM_CTX_MIDI_PIANOROLL'

function Main()
    -- 1. SET MODIFIERS TO VELOCITY
    -- 19 = Insert note, drag to edit velocity
    -- 35 = Insert note ignoring snap, drag to edit velocity (Corrected ID)
    reaper.SetMouseModifier(ctx, 0, '19 m')
    reaper.SetMouseModifier(ctx, 1, '35 m')
    
    -- 2. TURN *THIS* BUTTON ON
    local _, _, section_id, command_id = reaper.get_action_context()
    reaper.SetToggleCommandState(section_id, command_id, 1)
    reaper.RefreshToolbar2(section_id, command_id)
    
    -- 3. TURN *OTHER* BUTTON OFF (If ID is provided)
    if other_script_id ~= "" then
        -- We need the numeric ID from the string ID
        local other_cmd = reaper.NamedCommandLookup(other_script_id)
        if other_cmd > 0 then
            reaper.SetToggleCommandState(section_id, other_cmd, 0)
            reaper.RefreshToolbar2(section_id, other_cmd)
        end
    end
end

Main()
