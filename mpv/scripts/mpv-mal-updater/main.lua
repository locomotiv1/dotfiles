local utils = require 'mp.utils'
local mpoptions = require("mp.options")
local correction_overlay = require("correction_overlay")

local conf_name = "malUpdater.conf"
local script_dir = (debug.getinfo(1).source:match("@?(.*/)") or "./")

local function get_mpv_config_dir()
    return os.getenv("APPDATA") and utils.join_path(os.getenv("APPDATA"), "mpv") or
            os.getenv("HOME") and utils.join_path(utils.join_path(os.getenv("HOME"), ".config"), "mpv") or nil
end

local function normalize_path(p)
    p = p:gsub("\\", "/")
    if p:sub(-1) == "/" then
        p = p:sub(1, -2)
    end
    return p
end

local function parse_directory_string(dir_string)
    if type(dir_string) == "string" and dir_string ~= "" then
        local dirs = {}
        for dir in string.gmatch(dir_string, "([^,;]+)") do
            local trimmed = (dir:gsub("^%s*(.-)%s*$", "%1"):gsub('[\'"]', '')) 
            table.insert(dirs, normalize_path(trimmed))
        end
        return dirs
    else
        return {}
    end
end

local default_conf = [[# malUpdater Configuration
DIRECTORIES=
EXCLUDED_DIRECTORIES=
UPDATE_PERCENTAGE=85
SET_COMPLETED_TO_REWATCHING_ON_FIRST_EPISODE=no
UPDATE_PROGRESS_WHEN_REWATCHING=yes
SET_TO_COMPLETED_AFTER_LAST_EPISODE_CURRENT=yes
SET_TO_COMPLETED_AFTER_LAST_EPISODE_REWATCHING=yes
ADD_ENTRY_IF_MISSING=no
CACHE_REFRESH_RATE=24
CACHE_MODE=NORMAL
SILENT_MODE=no
]]

local script_opts_dir = script_dir:match("^(.-)[/\\]scripts[/\\]")
if script_opts_dir then
    script_opts_dir = utils.join_path(script_opts_dir, "script-opts")
else
    local mpv_conf_dir = get_mpv_config_dir()
    script_opts_dir = mpv_conf_dir and utils.join_path(mpv_conf_dir, "script-opts") or nil
end

local script_opts_path = script_opts_dir and utils.join_path(script_opts_dir, conf_name) or nil
local script_path = utils.join_path(script_dir, conf_name)
local mpv_conf_dir = get_mpv_config_dir()
local mpv_conf_path = mpv_conf_dir and utils.join_path(mpv_conf_dir, conf_name) or nil
local conf_paths = {script_opts_path, script_path, mpv_conf_path}

local conf_path = nil
for _, path in ipairs(conf_paths) do
    if path then
        local f = io.open(path, "r")
        if f then
            f:close()
            conf_path = path
            break
        end
    end
end

if not conf_path then
    for _, path in ipairs(conf_paths) do
        if path then
            local f = io.open(path, "w")
            if f then
                f:write(default_conf)
                f:close()
                conf_path = path
                break
            end
        end
    end
end

if not conf_path then
    mp.msg.warn("Could not find or create malUpdater.conf in any known location! Using default options.")
end

local options = {
    DIRECTORIES = "",
    EXCLUDED_DIRECTORIES = "",
    UPDATE_PERCENTAGE = 85,
    SET_COMPLETED_TO_REWATCHING_ON_FIRST_EPISODE = false,
    UPDATE_PROGRESS_WHEN_REWATCHING = true,
    SET_TO_COMPLETED_AFTER_LAST_EPISODE_CURRENT = true,
    SET_TO_COMPLETED_AFTER_LAST_EPISODE_REWATCHING = true,
    ADD_ENTRY_IF_MISSING = false,
    CACHE_REFRESH_RATE = 24,
    CACHE_MODE = "NORMAL",
    SILENT_MODE = false
}

mpoptions.read_options(options, "malUpdater")
options.DIRECTORIES = parse_directory_string(options.DIRECTORIES)
options.EXCLUDED_DIRECTORIES = parse_directory_string(options.EXCLUDED_DIRECTORIES)

local python_options = {
    SET_COMPLETED_TO_REWATCHING_ON_FIRST_EPISODE = options.SET_COMPLETED_TO_REWATCHING_ON_FIRST_EPISODE,
    UPDATE_PROGRESS_WHEN_REWATCHING = options.UPDATE_PROGRESS_WHEN_REWATCHING,
    SET_TO_COMPLETED_AFTER_LAST_EPISODE_CURRENT = options.SET_TO_COMPLETED_AFTER_LAST_EPISODE_CURRENT,
    SET_TO_COMPLETED_AFTER_LAST_EPISODE_REWATCHING = options.SET_TO_COMPLETED_AFTER_LAST_EPISODE_REWATCHING,
    ADD_ENTRY_IF_MISSING = options.ADD_ENTRY_IF_MISSING,
    CACHE_REFRESH_RATE = tonumber(options.CACHE_REFRESH_RATE) or 24,
    CACHE_MODE = tostring(options.CACHE_MODE or "NORMAL")
}

local python_options_json = utils.format_json(python_options)
DIRECTORIES = options.DIRECTORIES
EXCLUDED_DIRECTORIES = options.EXCLUDED_DIRECTORIES
UPDATE_PERCENTAGE = tonumber(options.UPDATE_PERCENTAGE) or 85
local current_anime_info = nil

local function path_starts_with_any(path, directories)
    local norm_path = normalize_path(path)
    for _, dir in ipairs(directories) do
        if norm_path:sub(1, #dir) == dir then
            return true
        end
    end
    return false
end

local function parse_detected_info(result)
    if not result or not result.stdout then
        return nil
    end
    for line in result.stdout:gmatch("[^\r\n]+") do
        local json_part = line:match("^INFO:%s*(.+)$")
        if json_part then
            local info = utils.parse_json(json_part)
            if info and type(info) == "table" then
                return info
            end
        end
    end
    return nil
end

function callback(success, result, error)
    local is_success = success and result and result.status == 0
    if is_success then
        if current_anime_info and current_anime_info.episode then
            current_anime_info.current_progress = current_anime_info.episode
        end
    end

    if options.SILENT_MODE and is_success then return end
    
    local messages = {}
    if result and result.stdout then
        for line in result.stdout:gmatch("[^\r\n]+") do
            local msg = line:match("^OSD:%s*(.-)%s*$")
            if msg then
                table.insert(messages, msg)
            else
                print(line)
            end
        end
    end
    
    if is_success then
        if #messages == 0 then
            table.insert(messages, "Updated anime correctly.")
        end
    end
    if #messages > 0 then
        mp.osd_message(table.concat(messages, "\n"), 5)
    end
end

local function get_python_command()
    local platform = mp.get_property("platform")
    if platform == "windows" then
        return "python"
    else
        return "python3"
    end
end

local function open(target)
    local platform = mp.get_property("platform")
    local args
    if platform == "windows" then
        args = {"cmd", "/c", "start", "", target}
    elseif platform == "darwin" then
        args = {"open", target}
    else
        args = {"xdg-open", target}
    end
    mp.command_native({name = "subprocess", args = args, detach = true})
end

local function is_ani_cli_compatible()
    local directory = mp.get_property("working-directory") or ""
    local file_path = mp.get_property("path") or ""
    local full_path = utils.join_path(directory, file_path)
    return full_path:match("https?://") ~= nil
end

local function get_path()
    local directory = mp.get_property("working-directory")
    directory = (directory:sub(-1) == '/' or directory:sub(-1) == '\\') and directory or directory .. '/'
    local file_path = mp.get_property("path")
    local path = utils.join_path(directory, file_path)

    if path:match("https?://") then
        local media_title = mp.get_property("media-title")
        if media_title and media_title ~= "" then
            return media_title
        end
    end
    if path:match("([^/\\]+)$"):lower() == "file.mp4" then
        path = mp.get_property("media-title")
    end
    return path
end

local python_command = get_python_command()
local isPaused = false
local is_file_eligible = false
local is_fetching = false

local function fetch_anime_info(cb)
    if is_fetching then return end
    is_fetching = true
    local path = get_path()
    mp.command_native_async({
        name = "subprocess",
        args = {python_command, script_dir .. "malUpdater.py", path, "info", python_options_json},
        capture_stdout = true
    }, function(success, result)
        is_fetching = false
        if success and result and result.status == 0 then
            current_anime_info = parse_detected_info(result)
            if current_anime_info then
                print("Detected anime: " .. (current_anime_info.anime_name or "?") .. " #" .. (current_anime_info.episode or "?"))
            end
        end
        if cb then
            cb(current_anime_info)
        end
    end)
end

local triggered = false
local UPDATE_INTERVAL = 1
local progress_timer = mp.add_periodic_timer(UPDATE_INTERVAL, function()
    if triggered then return end
    
    local percent_pos = mp.get_property_number("percent-pos")
    if not percent_pos then return end
    if percent_pos >= UPDATE_PERCENTAGE then
        update_mal()
        triggered = true
        if progress_timer then
            progress_timer:stop()
        end
        return
    end
end)
progress_timer:stop()

function on_pause_change(name, value)
    isPaused = value
    if value then
        progress_timer:stop()
    else
        if is_file_eligible and not triggered then
            progress_timer:resume()
        end
    end
end

local function update(info)
    local path = get_path()
    local info_json = utils.format_json(info)
    mp.command_native_async({
        name = "subprocess",
        args = {python_command, script_dir .. "malUpdater.py", path, "update_with_info", python_options_json, info_json},
        capture_stdout = true
    }, callback)
end

function update_mal()
    if current_anime_info then
        update(current_anime_info)
    else
        fetch_anime_info(function(info)
            if info then
                update(info)
            else
                if not options.SILENT_MODE then
                    mp.osd_message("Error: Anime info not loaded yet.", 3)
                end
            end
        end)
    end
end

mp.observe_property("pause", "bool", on_pause_change)

mp.register_event("file-loaded", function()
    triggered = false
    is_file_eligible = false
    current_anime_info = nil
    is_fetching = false
    progress_timer:stop()

    if not is_ani_cli_compatible() and #DIRECTORIES > 0 then
        local path = get_path()
        if not path_starts_with_any(path, DIRECTORIES) then
            return
        else
            if #EXCLUDED_DIRECTORIES > 0 and path_starts_with_any(path, EXCLUDED_DIRECTORIES) then
                return
            end
        end
    end

    is_file_eligible = true
    fetch_anime_info()
    if not isPaused then
        progress_timer:resume()
    end
end)

mp.add_key_binding("ctrl+a", 'update_mal', update_mal)

local function launch(info)
    local url = "https://myanimelist.net/anime/" .. info.anime_id
    if not options.SILENT_MODE then
        mp.osd_message('Opening MAL for "' .. (info.anime_name or "?") .. '"', 3)
    end
    open(url)
end

local function launch_mal()
    if current_anime_info and current_anime_info.anime_id then
        launch(current_anime_info)
    else
        fetch_anime_info(function(info)
            if info and info.anime_id then
                launch(info)
            else
                if not options.SILENT_MODE then
                    mp.osd_message("Error: Anime info not loaded yet.", 3)
                end
            end
        end)
    end
end
mp.add_key_binding("ctrl+b", 'launch_mal', launch_mal)

function open_folder()
    local path = mp.get_property("path")
    local directory
    if not path then
        mp.msg.warn("No file is currently playing.")
        return
    end
    directory = path:match("(.+)[/\\]") or mp.get_property("working-directory")
    open(directory)
end
mp.add_key_binding("ctrl+d", 'open_folder', open_folder)

correction_overlay.init({
    python_command = python_command,
    python_options_json = python_options_json,
    callback = callback,
    get_current_anime_info = function() return current_anime_info end,
    set_current_anime_info = function(info) current_anime_info = info end
})

mp.add_key_binding("c", 'correct_anime_id', function()
    correction_overlay.correct_anime_id(get_path)
end)
