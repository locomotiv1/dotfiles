local speedup_timer = nil
local saved_speed = 1.0
local is_speeding = false
local was_paused = false

-- You can tweak these two values:
local HOLD_DELAY = 0.25  -- Seconds you have to hold before it speeds up
local FAST_SPEED = 2.0   -- The speed multiplier

mp.add_key_binding("SPACE", "space_action", function(e)
    if e.event == "down" then
        if not speedup_timer and not is_speeding then
            speedup_timer = mp.add_timeout(HOLD_DELAY, function()
                saved_speed = mp.get_property_native("speed")
                was_paused = mp.get_property_native("pause")
                
                mp.set_property("speed", FAST_SPEED)
                if was_paused then
                    mp.set_property("pause", false)
                end
                mp.osd_message("▶▶ " .. FAST_SPEED .. "x")
                is_speeding = true
            end)
        end
    elseif e.event == "up" then
        if speedup_timer then
            speedup_timer:kill()
            speedup_timer = nil
        end
        
        if is_speeding then
            mp.set_property("speed", saved_speed)
            if was_paused then
                mp.set_property("pause", true)
            end
            mp.osd_message("Speed: " .. saved_speed .. "x")
            is_speeding = false
        else
            -- It was a short tap: toggle pause normally
            local pause = mp.get_property_native("pause")
            mp.set_property("pause", not pause)
        end
    end
end, {complex = true})
