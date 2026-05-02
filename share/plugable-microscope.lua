-- plugable-microscope.lua
-- Adds a click-to-snap button, SPACE for screenshots, Ctrl+SPACE to toggle
-- recording, and a pulsing REC indicator.

local mp = require 'mp'
local utils = require 'mp.utils'

local IS_WIN = (package.config:sub(1, 1) == '\\')
local HOME   = os.getenv('HOME') or os.getenv('USERPROFILE') or '.'
local ROOT   = os.getenv('PMS_CAPTURES') or (HOME .. '/Pictures/PlugableMicroscope')
local PICS   = ROOT .. '/Pictures'
local VIDS   = ROOT .. '/Videos'

local function mkdir(p)
    if IS_WIN then
        os.execute('cmd /c mkdir "' .. p:gsub('/', '\\') .. '" 2>nul')
    else
        os.execute("mkdir -p '" .. p:gsub("'", "'\\''") .. "'")
    end
end
mkdir(PICS); mkdir(VIDS)

mp.set_property('osc', 'no')
mp.set_property('screenshot-directory', PICS)
mp.set_property('screenshot-format', 'png')

local recording = false
local rec_path  = nil
local overlay   = mp.create_osd_overlay('ass-events')

local BTN_W, BTN_H = 240, 72
local BTN_MARGIN   = 28

local function btn_rect()
    local w = mp.get_property_number('osd-width')  or 1280
    local h = mp.get_property_number('osd-height') or 720
    local x = math.floor((w - BTN_W) / 2)
    local y = h - BTN_H - BTN_MARGIN
    return x, y, BTN_W, BTN_H
end

local function ts() return os.date('%Y%m%d-%H%M%S') end

local function ass_button(x, y, w, h, label, fill_color)
    local fill = fill_color or '00CC44'
    local shape = string.format(
        'm 8 0 l %d 0 b %d 0 %d 8 %d 8 l %d %d b %d %d %d %d %d %d l 8 %d b 0 %d 0 %d 0 %d l 0 8 b 0 0 8 0 8 0',
        w - 8, w, w, w, w, h - 8, w, h, w - 8, h, w - 8, h, h, h - 8, 8, 8, 8
    )
    local bg = string.format(
        '{\\pos(%d,%d)\\an7\\bord3\\3c&H000000&\\1c&H%s&\\1a&H30&\\p1}%s{\\p0}',
        x, y, fill, shape
    )
    local txt = string.format(
        '{\\r}{\\an5\\pos(%d,%d)\\fs36\\bord2\\1c&HFFFFFF&\\3c&H000000&\\b1}%s',
        x + w / 2, y + h / 2, label
    )
    return bg .. '\n' .. txt
end

local function rec_visible()
    -- 1 second on, 2 seconds off (3-second cycle)
    return (mp.get_time() % 3) < 1
end

local function ass_rec()
    if not rec_visible() then return '' end
    return string.format(
        '{\\r}{\\an7\\pos(%d,%d)\\fs28\\bord3\\1c&HFFFFFF&\\3c&H0000CC&\\b1}%s REC',
        24, 24, '●'
    )
end

local function redraw()
    local x, y, w, h = btn_rect()
    local data = ass_button(x, y, w, h, '[ SNAP ]')
    if recording then
        local rec = ass_rec()
        if rec ~= '' then data = data .. '\n' .. rec end
    end
    overlay.data = data
    overlay:update()
end

local function notify(msg, secs)
    -- Two-line OSD popup: bold first line, smaller path on the second.
    -- Disappears after `secs` seconds.
    mp.osd_message(msg, secs or 3)
end

local function snap()
    local path = string.format('%s/microscope-%s.png', PICS, ts())
    mp.commandv('screenshot-to-file', path)
    notify('saved\n' .. path, 3)
end

local function start_record()
    rec_path = string.format('%s/microscope-%s.mkv', VIDS, ts())
    local ok, err = pcall(mp.set_property, 'stream-record', rec_path)
    if not ok then
        notify('record failed: ' .. tostring(err), 3)
        return
    end
    recording = true
    redraw()
    notify('recording started\n' .. rec_path, 2)
end

local function stop_record()
    pcall(mp.set_property, 'stream-record', '')
    recording = false
    redraw()
    if rec_path then notify('saved\n' .. rec_path, 3) end
end

local function toggle_record()
    if recording then stop_record() else start_record() end
end

mp.add_forced_key_binding('SPACE',      'pms-snap',   snap)
mp.add_forced_key_binding('Ctrl+SPACE', 'pms-record', toggle_record)
mp.add_forced_key_binding('MBTN_LEFT',  'pms-click',  function()
    local pos = mp.get_property_native('mouse-pos')
    if not pos then return end
    local x, y, w, h = btn_rect()
    if pos.x and pos.y and pos.x >= x and pos.x <= x + w and pos.y >= y and pos.y <= y + h then
        snap()
    end
end)

mp.observe_property('osd-width',  'number', redraw)
mp.observe_property('osd-height', 'number', redraw)
mp.add_periodic_timer(0.2, function() if recording then redraw() end end)

mp.register_event('file-loaded', redraw)
redraw()
