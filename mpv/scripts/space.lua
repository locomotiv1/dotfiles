local speedup_timer = nil
local saved_speed = 1.0
local is_speeding = false
local was_paused = false

local HOLD_DELAY = 0.25
local FAST_SPEED = 2.0

mp.add_forced_key_binding("SPACE", "space_action", function(e)
    if e.event == "down" then
        if not speedup_timer and not is_speeding then
            speedup_timer = mp.add_timeout(HOLD_DELAY, function()
                saved_speed = mp.get_property_native("speed")
                was_paused = mp.get_property_native("pause")
                -- Use _native so mpv correctly accepts the boolean and number
                mp.set_property_native("speed", FAST_SPEED)
                if was_paused then
                    mp.set_property_native("pause", false)
                end
                is_speeding = true
            end)
        end
    elseif e.event == "up" then
        if speedup_timer then
            speedup_timer:kill()
            speedup_timer = nil
        end
        if is_speeding then
            mp.set_property_native("speed", saved_speed)
            if was_paused then
                mp.set_property_native("pause", true)
            end
            mp.osd_message("Speed: " .. saved_speed .. "x")
            is_speeding = false
        else
            -- Short tap: tell mpv to toggle pause natively, avoiding silent crashes
            mp.commandv("cycle", "pause")
        end
    end
end, {complex = true})
