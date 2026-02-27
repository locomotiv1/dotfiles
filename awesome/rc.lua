pcall(require, "luarocks.loader")

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

-- {{{ Error handling (Unchanged)
if awesome.startup_errors then
	naughty.notify({
		preset = naughty.config.presets.critical,
		title = "Oops, there were errors during startup!",
		text = awesome.startup_errors,
	})
end

do
	local in_error = false
	awesome.connect_signal("debug::error", function(err)
		if in_error then
			return
		end
		in_error = true
		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, an error happened!",
			text = tostring(err),
		})
		in_error = false
	end)
end
-- }}}

-- {{{ Variable definitions & Autostart
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

-- i3 Visuals: 4px border
beautiful.border_width = 4

-- i3 Variables
terminal = "alacritty"
browser = "firefox"
editor = os.getenv("EDITOR") or "nvim"
editor_cmd = terminal .. " -e " .. editor
modkey = "Mod4"

local autostart_cmds = {
	"dex --autostart --environment awesome",
	"nm-applet",
	"picom -b --backend glx",
	"feh --randomize --bg-fill ~/wallpapers/*",
	"xss-lock --transfer-sleep-lock -- i3lock --nofork",
	"xrandr --output HDMI-A-0 --mode 2560x1440 --rate 144 --primary --output DisplayPort-2 --mode 1920x1080 --rate 60 --right-of HDMI-A-0",
}

for _, cmd in ipairs(autostart_cmds) do
	awful.spawn.with_shell(cmd)
end

awful.layout.layouts = {
	awful.layout.suit.spiral.dwindle, -- Halves the space successively (what you asked for)
}
-- }}}

-- {{{ Menu & Wibar (Mostly default, abbreviated for space)
myawesomemenu = {
	{
		"hotkeys",
		function()
			hotkeys_popup.show_help(nil, awful.screen.focused())
		end,
	},
	{ "manual", terminal .. " -e man awesome" },
	{ "edit config", editor_cmd .. " " .. awesome.conffile },
	{ "restart", awesome.restart },
	{
		"quit",
		function()
			awesome.quit()
		end,
	},
}
mymainmenu = awful.menu({
	items = {
		{ "awesome", myawesomemenu, beautiful.awesome_icon },
		{ "open terminal", terminal },
	},
})
mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = mymainmenu })
menubar.utils.terminal = terminal
mykeyboardlayout = awful.widget.keyboardlayout()
mytextclock = wibox.widget.textclock()

-- Screen Setup
awful.screen.connect_for_each_screen(function(s)
	-- Wallpaper
	if beautiful.wallpaper then
		local wallpaper = beautiful.wallpaper
		if type(wallpaper) == "function" then
			wallpaper = wallpaper(s)
		end
		gears.wallpaper.maximized(wallpaper, s, true)
	end

	-- Workspaces (Tags)
	awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" }, s, awful.layout.layouts[1])

	s.mypromptbox = awful.widget.prompt()
	s.mylayoutbox = awful.widget.layoutbox(s)
	s.mylayoutbox:buttons(gears.table.join(
		awful.button({}, 1, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 3, function()
			awful.layout.inc(-1)
		end),
		awful.button({}, 4, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 5, function()
			awful.layout.inc(-1)
		end)
	))

	-- Default taglist/tasklist setup... (Kept standard to ensure your bar works)
	s.mytaglist = awful.widget.taglist({ screen = s, filter = awful.widget.taglist.filter.all })
	s.mytasklist = awful.widget.tasklist({ screen = s, filter = awful.widget.tasklist.filter.currenttags })

	s.mywibox = awful.wibar({ position = "top", screen = s })
	s.mywibox:setup({
		layout = wibox.layout.align.horizontal,
		{ layout = wibox.layout.fixed.horizontal, mylauncher, s.mytaglist, s.mypromptbox },
		s.mytasklist,
		{
			layout = wibox.layout.fixed.horizontal,
			mykeyboardlayout,
			wibox.widget.systray(),
			mytextclock,
			s.mylayoutbox,
		},
	})
end)
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
	awful.key({ modkey }, "s", hotkeys_popup.show_help, { description = "show help", group = "awesome" }),

	-- i3: Focus via Vim Keys (missing 'up' since 'l' is lock)
	awful.key({ modkey }, "j", function()
		awful.client.focus.bydirection("left")
	end, { description = "focus left", group = "client" }),
	awful.key({ modkey }, "k", function()
		awful.client.focus.bydirection("down")
	end, { description = "focus down", group = "client" }),
	awful.key({ modkey }, "semicolon", function()
		awful.client.focus.bydirection("right")
	end, { description = "focus right", group = "client" }),

	-- i3: Focus via Arrow Keys
	awful.key({ modkey }, "Left", function()
		awful.client.focus.bydirection("left")
	end, { description = "focus left", group = "client" }),
	awful.key({ modkey }, "Down", function()
		awful.client.focus.bydirection("down")
	end, { description = "focus down", group = "client" }),
	awful.key({ modkey }, "Up", function()
		awful.client.focus.bydirection("up")
	end, { description = "focus up", group = "client" }),
	awful.key({ modkey }, "Right", function()
		awful.client.focus.bydirection("right")
	end, { description = "focus right", group = "client" }),

	-- Layout manipulation
	awful.key({ modkey }, "space", function()
		awful.layout.inc(1)
	end, { description = "select next layout", group = "layout" }),
	awful.key({ modkey, "Shift" }, "space", function()
		awful.layout.inc(-1)
	end, { description = "select previous layout", group = "layout" }),

	-- i3: System Control
	awful.key({ modkey, "Shift" }, "c", awesome.restart, { description = "reload awesome", group = "awesome" }),
	awful.key({ modkey, "Shift" }, "e", awesome.quit, { description = "quit awesome", group = "awesome" }),
	awful.key({ modkey }, "l", function()
		awful.spawn("loginctl lock-session")
	end, { description = "lock screen", group = "system" }),

	-- i3: Application Launchers
	awful.key({ modkey }, "z", function()
		awful.spawn(terminal)
	end, { description = "open terminal", group = "launcher" }),
	awful.key({ modkey }, "f", function()
		awful.spawn(browser)
	end, { description = "open browser", group = "launcher" }),
	awful.key({ modkey }, "a", function()
		awful.spawn("rofi -show drun -show-icons")
	end, { description = "rofi launcher", group = "launcher" }),

	-- Screenshots
	-- Full screen to clipboard (Mod + Shift + P)
	awful.key({ modkey, "Shift" }, "p", function()
		local geo = awful.screen.focused().geometry
		local geom_str = string.format("%dx%d+%d+%d", geo.width, geo.height, geo.x, geo.y)
		awful.spawn.with_shell("maim -g " .. geom_str .. " | xclip -selection clipboard -t image/png")
	end, { description = "capture current monitor to clipboard", group = "screenshot" }),

	-- Full screen to file (Mod + Ctrl + P)
	awful.key({ modkey, "Control" }, "p", function()
		local geo = awful.screen.focused().geometry
		local geom_str = string.format("%dx%d+%d+%d", geo.width, geo.height, geo.x, geo.y)
		awful.spawn.with_shell(
			"mkdir -p ~/Pictures/Screenshots && maim -g "
				.. geom_str
				.. " ~/Pictures/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png"
		)
	end, { description = "capture current monitor to file", group = "screenshot" }),

	-- Selection to clipboard (Mod + Shift + S)
	awful.key({ modkey, "Shift" }, "s", function()
		awful.spawn.with_shell("maim -s | xclip -selection clipboard -t image/png")
	end, { description = "capture selection to clipboard", group = "screenshot" }),

	-- Selection to file (Mod + Ctrl + S)
	awful.key({ modkey, "Control" }, "s", function()
		awful.spawn.with_shell(
			"mkdir -p ~/Pictures/Screenshots && maim -s ~/Pictures/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png"
		)
	end, { description = "capture selection to file", group = "screenshot" }),

	-- i3: Audio Controls
	awful.key({}, "XF86AudioRaiseVolume", function()
		awful.spawn.with_shell(
			"pactl set-sink-volume @DEFAULT_SINK@ +5% && paplay /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga"
		)
	end),
	awful.key({}, "XF86AudioLowerVolume", function()
		awful.spawn.with_shell(
			"pactl set-sink-volume @DEFAULT_SINK@ -5% && paplay /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga"
		)
	end),
	awful.key({}, "XF86AudioMute", function()
		awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")
	end)
)

clientkeys = gears.table.join(
	awful.key({ "Mod1" }, "Return", function(c)
		c.fullscreen = not c.fullscreen
		c:raise()
	end, { description = "toggle fullscreen", group = "client" }),
	awful.key({ modkey }, "q", function(c)
		c:kill()
	end, { description = "close", group = "client" }),
	awful.key(
		{ modkey, "Shift" },
		"space",
		awful.client.floating.toggle,
		{ description = "toggle floating", group = "client" }
	),
	awful.key({ modkey, "Control" }, "Return", function(c)
		c:swap(awful.client.getmaster())
	end, { description = "move to master", group = "client" }),
	awful.key({ modkey }, "o", function(c)
		c:move_to_screen()
	end, { description = "move to screen", group = "client" })
)

-- Bind all key numbers to tags.
for i = 1, 10 do
	local key = tostring(i == 10 and 0 or i) -- Map 10 to 0
	globalkeys = gears.table.join(
		globalkeys,
		awful.key({ modkey }, key, function()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				tag:view_only()
			end
		end, { description = "view tag #" .. i, group = "tag" }),

		awful.key({ modkey, "Shift" }, key, function()
			if client.focus then
				local tag = client.focus.screen.tags[i]
				if tag then
					client.focus:move_to_tag(tag)
				end
			end
		end, { description = "move focused client to tag #" .. i, group = "tag" })
	)
end

clientbuttons = gears.table.join(
	awful.button({}, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
	end),
	awful.button({ modkey }, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.move(c)
	end),
	awful.button({ modkey }, 3, function(c)
		c:emit_signal("request::activate", "mouse_click", { raise = true })
		awful.mouse.client.resize(c)
	end)
)

root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
	-- All clients will match this rule.
	{
		rule = {},
		properties = {
			border_width = beautiful.border_width,
			border_color = beautiful.border_normal,
			focus = awful.client.focus.filter,
			raise = true,
			keys = clientkeys,
			buttons = clientbuttons,
			screen = awful.screen.preferred,
			placement = awful.placement.no_overlap + awful.placement.no_offscreen,
			titlebars_enabled = false, -- i3: Tiled windows get no titlebar
		},
	},

	-- Floating clients.
	{
		rule_any = {
			class = {
				"Arandr",
				"Blueman-manager",
				"Gpick",
				"Kruler",
				"MessageWin",
				"Sxiv",
				"Tor Browser",
				"Wpa_gui",
				"veromix",
				"xtightvncviewer",
			},
			name = { "Event Tester" },
			role = { "AlarmWindow", "ConfigManager", "pop-up" },
		},
		properties = { floating = true },
	},
}
-- }}}

-- {{{ Signals
client.connect_signal("manage", function(c)
	if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
		awful.placement.no_offscreen(c)
	end
end)

-- i3 visual logic: Add a titlebar ONLY if the window is floating
client.connect_signal("property::floating", function(c)
	if c.floating then
		awful.titlebar.show(c)
	else
		awful.titlebar.hide(c)
	end
end)

client.connect_signal("request::titlebars", function(c)
	local buttons = gears.table.join(
		awful.button({}, 1, function()
			c:emit_signal("request::activate", "titlebar", { raise = true })
			awful.mouse.client.move(c)
		end),
		awful.button({}, 3, function()
			c:emit_signal("request::activate", "titlebar", { raise = true })
			awful.mouse.client.resize(c)
		end)
	)

	awful.titlebar(c):setup({
		{ -- Left
			awful.titlebar.widget.iconwidget(c),
			buttons = buttons,
			layout = wibox.layout.fixed.horizontal,
		},
		{ -- Middle
			{ -- Title
				align = "center",
				widget = awful.titlebar.widget.titlewidget(c),
			},
			buttons = buttons,
			layout = wibox.layout.flex.horizontal,
		},
		{ -- Right
			awful.titlebar.widget.floatingbutton(c),
			awful.titlebar.widget.maximizedbutton(c),
			awful.titlebar.widget.stickybutton(c),
			awful.titlebar.widget.ontopbutton(c),
			awful.titlebar.widget.closebutton(c),
			layout = wibox.layout.fixed.horizontal(),
		},
		layout = wibox.layout.align.horizontal,
	})
end)

client.connect_signal("mouse::enter", function(c)
	c:emit_signal("request::activate", "mouse_enter", { raise = false })
end)

client.connect_signal("focus", function(c)
	c.border_color = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
end)
-- }}}
