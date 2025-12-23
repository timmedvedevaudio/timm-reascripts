--[[
ReaScript Name: Set MIDI Editor to Melodic Mode (Linked)
Description: Sets Left Drag to Default (1/2). Force-updates toolbar state.
]]

-- PASTE THE COMMAND ID OF THE *OTHER* SCRIPT (VELOCITY MODE) HERE:
-- Example: local other_script_id = "_RS0987654321fedcba"
local other_script_id = "_RS7d3c_dcb314ba9991094fde7676af76ad818de78d9181"
---------------------------------------------------------------------

local ctx = 'MM_CTX_MIDI_PIANOROLL'

function Main()
    -- 1. SET MODIFIERS TO DEFAULT MELODIC
    -- 1 = Insert note, drag to extend or change pitch
    -- 2 = Insert note ignoring snap, drag to extend or change pitch
    reaper.SetMouseModifier(ctx, 0, '1 m')
    reaper.SetMouseModifier(ctx, 1, '2 m')
    
    -- 2. TURN *THIS* BUTTON ON
    local _, _, section_id, command_id = reaper.get_action_context()
    reaper.SetToggleCommandState(section_id, command_id, 1)
    reaper.RefreshToolbar2(section_id, command_id)
    
    -- 3. TURN *OTHER* BUTTON OFF (If ID is provided)
    if other_script_id ~= "" then
        local other_cmd = reaper.NamedCommandLookup(other_script_id)
        if other_cmd > 0 then
            reaper.SetToggleCommandState(section_id, other_cmd, 0)
            reaper.RefreshToolbar2(section_id, other_cmd)
        end
    end
end

Main()
