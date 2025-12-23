-- @description Duplicate selected MIDI events with 1-bar Overlap
-- @version 1.0
-- @author Gemini

function DuplicateOverlapOneBar()
    local editor = reaper.MIDIEditor_GetActive()
    if not editor then return end

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    -- 1. IDENTIFY TAKES
    local takes = {}
    local t_idx = 0
    while true do
        local take = reaper.MIDIEditor_EnumTakes(editor, t_idx, true)
        if not take then break end
        table.insert(takes, take)
        t_idx = t_idx + 1
    end

    -- 2. READ PHASE
    local min_time = math.huge
    local max_time = -math.huge
    local has_selection = false
    local actions = {} 

    for _, take in ipairs(takes) do
        local take_data = {
            notes = {},
            ccs = {},
            to_deselect_notes = {},
            to_deselect_ccs = {}
        }
        
        local _, num_notes, num_cc, _ = reaper.MIDI_CountEvts(take)
        
        -- Analyze Notes
        for i = 0, num_notes - 1 do
            local _, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
            if sel then
                has_selection = true
                local t_start = reaper.MIDI_GetProjTimeFromPPQPos(take, startppq)
                local t_end = reaper.MIDI_GetProjTimeFromPPQPos(take, endppq)
                
                if t_start < min_time then min_time = t_start end
                if t_end > max_time then max_time = t_end end
                
                table.insert(take_data.notes, {
                    muted=muted, startppq=startppq, endppq=endppq, 
                    chan=chan, pitch=pitch, vel=vel
                })
                table.insert(take_data.to_deselect_notes, i)
            end
        end
        
        -- Analyze CCs
        for i = 0, num_cc - 1 do
            local _, sel, muted, startppq, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, i)
            if sel then
                has_selection = true
                local t_start = reaper.MIDI_GetProjTimeFromPPQPos(take, startppq)
                if t_start < min_time then min_time = t_start end
                if t_start > max_time then max_time = t_start end
                
                local shape, tension = nil, nil
                if chanmsg == 176 or chanmsg == 224 then 
                    local retval
                    retval, shape, tension = reaper.MIDI_GetCCShape(take, i)
                end
                
                table.insert(take_data.ccs, {
                    muted=muted, startppq=startppq, 
                    chanmsg=chanmsg, chan=chan, msg2=msg2, msg3=msg3,
                    shape=shape, tension=tension 
                })
                table.insert(take_data.to_deselect_ccs, i)
            end
        end
        
        actions[take] = take_data
    end

    if not has_selection then 
        reaper.PreventUIRefresh(-1)
        reaper.Undo_EndBlock('Duplicate Overlap One Bar', -1)
        return 
    end

    -- 3. CALCULATE OFFSET (Start vs End - 1 Bar)
    local _, _, bpm = reaper.TimeMap_GetTimeSigAtTime(0, min_time)
    if not bpm or bpm == 0 then bpm = 120 end 
    local tolerance = (60 / bpm) / 8 
    
    -- A. Start Measure Index
    local _, meas_idx_start = reaper.TimeMap2_timeToBeats(0, min_time)
    local meas_start_time = reaper.TimeMap_GetMeasureInfo(0, meas_idx_start)
    local next_meas_time = reaper.TimeMap_GetMeasureInfo(0, meas_idx_start + 1)
    
    local dist_to_next = next_meas_time - min_time
    local effective_start_meas_idx = meas_idx_start
    if dist_to_next <= tolerance then
        effective_start_meas_idx = meas_idx_start + 1
    end

    -- B. End Measure Index
    local _, meas_idx_end = reaper.TimeMap2_timeToBeats(0, max_time)
    local meas_end_start_time = reaper.TimeMap_GetMeasureInfo(0, meas_idx_end)
    
    local effective_end_meas_idx = meas_idx_end
    if (max_time - meas_end_start_time) <= tolerance then
        effective_end_meas_idx = meas_idx_end - 1
    end
    
    -- C. Determine Target (Overlap Logic)
    -- Regular duplicate uses: effective_end_meas_idx + 1
    -- Overlap uses: effective_end_meas_idx
    -- This targets the LAST measure of the current selection, creating the overlap.
    local target_meas_idx = effective_end_meas_idx 
    
    local time_source_start = reaper.TimeMap_GetMeasureInfo(0, effective_start_meas_idx)
    local time_target_start = reaper.TimeMap_GetMeasureInfo(0, target_meas_idx)
    
    local offset_seconds = time_target_start - time_source_start

    -- 4. WRITE PHASE
    for take, data in pairs(actions) do
        reaper.MIDI_DisableSort(take)
        
        -- A. Deselect Originals
        for i = #data.to_deselect_notes, 1, -1 do
            reaper.MIDI_SetNote(take, data.to_deselect_notes[i], false, nil, nil, nil, nil, nil, nil, true)
        end
        for i = #data.to_deselect_ccs, 1, -1 do
            reaper.MIDI_SetCC(take, data.to_deselect_ccs[i], false, nil, nil, nil, nil, nil, nil, true)
        end

        -- B. Insert New Notes
        for _, n in ipairs(data.notes) do
            local start_t = reaper.MIDI_GetProjTimeFromPPQPos(take, n.startppq)
            local end_t = reaper.MIDI_GetProjTimeFromPPQPos(take, n.endppq)
            
            local new_start = reaper.MIDI_GetPPQPosFromProjTime(take, start_t + offset_seconds)
            local new_end = reaper.MIDI_GetPPQPosFromProjTime(take, end_t + offset_seconds)
            
            reaper.MIDI_InsertNote(take, true, n.muted, new_start, new_end, n.chan, n.pitch, n.vel, true)
        end

        -- C. Insert New CCs
        for _, c in ipairs(data.ccs) do
            local start_t = reaper.MIDI_GetProjTimeFromPPQPos(take, c.startppq)
            local new_start = reaper.MIDI_GetPPQPosFromProjTime(take, start_t + offset_seconds)
            
            reaper.MIDI_InsertCC(take, true, c.muted, new_start, c.chanmsg, c.chan, c.msg2, c.msg3)
            
            if c.shape then
                local _, _, current_cc_count, _ = reaper.MIDI_CountEvts(take)
                local new_idx = current_cc_count - 1
                reaper.MIDI_SetCCShape(take, new_idx, c.shape, c.tension)
            end
        end

        reaper.MIDI_Sort(take)
    end

    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock('Duplicate Overlap One Bar', -1)
end

DuplicateOverlapOneBar()
