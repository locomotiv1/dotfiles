local overlay = mp.create_osd_overlay("ass-events")

mp.observe_property("pause", "bool", function(name, is_paused)
    if is_paused then
        -- \an5 centers it. \fs120 sets the font size.
        overlay.data = "{\\an7}{\\fs80}⏸"
        overlay:update()
    else
        overlay:remove()
    end
end)
