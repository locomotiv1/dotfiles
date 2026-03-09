-- Automatically loops videos shorter than 5 minutes

local THRESHOLD_SECONDS = 300

local function check_duration_and_loop()
	local duration = mp.get_property_number("duration")

	if duration == nil then
		return
	end

	if duration < THRESHOLD_SECONDS then
		mp.set_property("loop-file", "inf")
	else
		mp.set_property("loop-file", "no")
	end
end

mp.register_event("file-loaded", check_duration_and_loop)
