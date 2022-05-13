SYSEX_START = {MIDIMessageType.SYSTEMEXCLUSIVE, 0x43, 0x73, 0x01, 0x33, 0x01, 0x00}

-- FADER_MIDI_DEBOUNCE_MS = 40

-- BIT 1
LED_ON = 0x02
LED_ON_DRAW = 0x03
LED_OFF = 0x04
LED_OFF_UNDRAW = 0x05
LED_HOLD = 0x06 -- in score or random mode
ROTATION = 0x07 -- no idea what this is for
PLAY_PAUSE = 0x08
LOOP_CONTROL = 0x09
CLEAR = 0x0A
COPY = 0x0B
COMMON_PARAM = 0x0C -- used for muting, idk what else
LAYER_PARAM = 0x0D
CURRENT_BLOCK = 0x0F
CURRENT_TRACK_CHANGE = 0x10 -- we tell it
CURRENT_TRACK_NOTIFY = 0x11 -- it tells us

-- BIT 2 - Common params
CP_VOLUME = 0x00
CP_TEMPO = 0x01
CP_SCALE = 0x02
CP_TRANSPOSE = 0x03
CP_LOOP_SPEED = 0x04
CP_LOOP_START = 0x05
CP_LOOP_END = 0x06
CP_LOOP_RESTART = 0x07
CP_MUTE = 0x08
CP_SWING = 0x09
CP_REVERB_TYPE = 0x0A
CP_REVERB_AMOUNT = 0x0B
CP_CHORUS_TYPE = 0x0C
CP_CHORUS_AMOUNT = 0x0D

-- BIT 2 - Layer params
LP_INSTRUMENT = 0x00
LP_SOUND_LENGTH = 0x01
LP_LOOP_SPEED = 0x02
LP_LOOP = 0x03
LP_VOLUME = 0x04
LP_PAN = 0x05
LP_OCTAVE = 0x09

-- BIT 2 - Clear
CLEAR_BLOCK = {0x00, 0x01}
CLEAR_LAYER = {0x00, 0x41}
CLEAR_ALL_BLOCKS = {0x01, 0x01}
CLEAR_EVERYTHING = {0x01, 0x07}

-- MISC
PLAY = 0x01
PAUSE = 0x00
MUTE = 0x01
UNMUTE = 0x00
ALL_BLOCKS = 0x11
ALL_LAYERS = 0x11
DRAW_ON = 0x00
DRAW_OFF = 0x01

local currentTrack = 0
local trackSelectButtons = root:findAllByProperty('tag', 'trackSelect')
local gridRows = root:findAllByProperty('tag', 'gridRow')
local panPots = root.children.panPots:findAllByProperty('tag', 'pan')

local bpm = 70
local drawState = {}
function initDrawState()
    for track = 1, 16 do
        drawState[track] = {}
        for y = 1, 16 do
            drawState[track][y] = {}
            for x = 1, 16 do
                drawState[track][y][x] = false
            end
        end
    end
end
function resetTrackState(track)
    for y = 1, 16 do
        for x = 1, 16 do
            drawState[track][y][x] = false
        end
    end
end
initDrawState()

-- reset track select state
for i = 1, #trackSelectButtons do
    trackSelectButtons[i]:notify(i == 1 and 'on' or 'off')
end

-- reset pan panPots
for i = 1, #panPots do
    panPots[i]:notify('value', 64)
end

-- reset grid
function resetGridRows()
    for i = 1, #gridRows do
        gridRows[i]:notify('reset')
    end
end
resetGridRows()

function onReceiveNotify(action, data)
    print('notified', action)
    tprint(data)
    if action == 'bpm' then
        local bit1 = data.bpm < 128 and 0x00 or 0x01
        local bit2 = data.bpm < 128 and data.bpm or data.bpm - 128
        sendTenoriSysex({COMMON_PARAM, CP_TEMPO, bit1, bit2, 0x00, 0x00})

    elseif action == 'trackVolume' then
        sendTenoriSysex({LAYER_PARAM, LP_VOLUME, 0x00, data.value, data.track, 0x00})

    elseif action == 'trackPan' then
        sendTenoriSysex({LAYER_PARAM, LP_PAN, 0x00, data.value, data.track, 0x00})

    elseif action == 'trackSelect' then
        for i = 1, #trackSelectButtons do
            if (i ~= data.track + 1) then
                self.children['trackSelect' .. i]:notify('off')
            end
        end
        sendTenoriSysex({CURRENT_TRACK_CHANGE, data.track, 0x00, 0x00, 0x00, 0x00})

    elseif action == 'ledOn' then
        sendTenoriSysex({LED_ON, data.x, data.y, currentTrack, 0x00, 0x00})

    elseif action == 'ledOff' then
        sendTenoriSysex({LED_OFF, data.x, data.y, currentTrack, 0x00, 0x00})

    elseif action == 'fillRowRandomly' then
        for x = 1, 16 do
            local value = drawState[currentTrack + 1][data.y + 1][x]
            local newValue = math.random(0, 1) == 1 and true or false
            print(x, value, newValue)
            sendTenoriSysex({LED_HOLD, x - 1, data.y, currentTrack, newValue == true and DRAW_ON or DRAW_OFF, 0x00})
            self.children['y' .. (data.y + 1)]:notify('draw', {
                ['x'] = x,
                ['value'] = newValue
            })
        end

    end
end

function sendTenoriSysex(message)
    local fullMessage = table.concat(table.concat(SYSEX_START, message), {0xF7})
    -- tprint(fullMessage)
    sendMIDI(fullMessage)
end

function receiveTenoriSysex(message)
    if message[1] == PLAY_PAUSE then
        if message[2] == PLAY then
            print('received PLAY')
        elseif message[2] == PAUSE then
            print('received PAUSE')
        end

    elseif message[1] == CURRENT_TRACK_NOTIFY then
        print('received CURRENT_TRACK_NOTIFY')
        currentTrack = message[2]
        self.children['trackSelect' .. (currentTrack + 1)]:notify('on')
        for i = 1, #trackSelectButtons do
            if (i ~= currentTrack + 1) then
                self.children['trackSelect' .. i]:notify('off')
            end
        end

    elseif message[1] == CLEAR then
        local block = message[2]
        local track = message[3]
        local b1 = message[4]
        local b2 = message[5]
        if (b1 == CLEAR_LAYER[1] and b2 == CLEAR_LAYER[2]) or (b1 == CLEAR_BLOCK[1] and b2 == CLEAR_BLOCK[2]) then
            print('received CLEAR_LAYER')
            resetTrackState(track + 1)
            if (track == currentTrack) then
                resetGridRows()
            end

            -- elseif b1 == CLEAR_BLOCK[1] and b2 == CLEAR_BLOCK[2] then
            --     print('received CLEAR_BLOCK')

        elseif b1 == CLEAR_ALL_BLOCKS[1] and b2 == CLEAR_ALL_BLOCKS[2] then
            print('received CLEAR_ALL_BLOCKS')
            initDrawState()
            resetGridRows()

        elseif b1 == CLEAR_EVERYTHING[1] and b2 == CLEAR_EVERYTHING[2] then
            print('received CLEAR_EVERYTHING')
        end

    elseif message[1] == LED_ON then
        print('received LED_ON')
        if message[4] == currentTrack then
            local x = message[2] + 1
            local y = message[3] + 1
            self.children['y' .. y]:notify('on', {
                ['x'] = x
            })
        end

    elseif message[1] == LED_OFF then
        print('received LED_OFF')
        if message[4] == currentTrack then
            local x = message[2] + 1
            local y = message[3] + 1
            self.children['y' .. y]:notify('off', {
                ['x'] = x
            })
        end

    elseif message[1] == LED_HOLD then
        print('received LED_HOLD')
        local x = message[2] + 1
        local y = message[3] + 1
        local track = message[4]
        print('track', track, 'x', x, 'y', y)
        if (message[5] == DRAW_ON) then
            drawState[track + 1][y][x] = true
        elseif (message[5] == DRAW_OFF) then
            drawState[track + 1][y][x] = false
        end
        if track == currentTrack then
            self.children['y' .. y]:notify('draw', {
                ['x'] = x,
                ['value'] = drawState[track + 1][y][x]
            })
        end

        -- elseif message[1] == LED_ON_DRAW then
        --     print('received LED_ON_DRAW')
        -- end

        -- elseif message[1] == LED_OFF_UNDRAW then
        --     print('received LED_OFF_UNDRAW')
        -- end

    elseif message[1] == COMMON_PARAM then
        local bit1 = message[3]
        local bit2 = message[4]
        if message[2] == CP_VOLUME then
            print('received VOLUME')
        elseif message[2] == CP_TEMPO then
            print('received TEMPO')
            bpm = bit1 == 0x00 and (bit2) or (128 + bit2)
            print('bpm', bpm)
            self.children['bpmLabel'].values.text = bpm
            self.children['bpm']:notify('bpm', {
                ['bpm'] = bpm
            })

        elseif message[2] == CP_SCALE then
            print('received SCALE')
        elseif message[2] == CP_TRANSPOSE then
            print('received TRANSPOSE')
        elseif message[2] == CP_MUTE then
            if message[4] == MUTE then
                print('received MUTE')
            elseif message[4] == UNMUTE then
                print('received UNMUTE')
            end
        elseif message[2] == CP_LOOP_SPEED then
            print('received LOOP_SPEED')
        elseif message[2] == CP_LOOP_START then
            print('received LOOP_START')
        elseif message[2] == CP_LOOP_END then
            print('received LOOP_END')
        elseif message[2] == CP_LOOP_RESTART then
            print('received LOOP_RESTART')
        elseif message[2] == CP_SWING then
            print('received SWING')
        elseif message[2] == CP_REVERB_TYPE then
            print('received REVERB_TYPE')
        elseif message[2] == CP_REVERB_AMOUNT then
            print('received REVERB_AMOUNT')
        elseif message[2] == CP_CHORUS_TYPE then
            print('received CHORUS_TYPE')
        elseif message[2] == CP_CHORUS_AMOUNT then
            print('received CHORUS_AMOUNT')
        end

    elseif message[1] == LAYER_PARAM then
        if message[2] == LP_INSTRUMENT then
            print('received INSTRUMENT')
        elseif message[2] == LP_VOLUME then
            print('received VOLUME')
            local track = message[5]
            local value = message[4]
            self.children.trackFaders.children['fader' .. (track + 1)]:notify('value', value)
        elseif message[2] == LP_PAN then
            print('received PAN')
            local track = message[5]
            local value = message[4]
            self.children.panPots.children['pan' .. (track + 1)]:notify('value', value)
        elseif message[2] == LP_SOUND_LENGTH then
            print('received SOUND_LENGTH')
        elseif message[2] == LP_LOOP_SPEED then
            print('received LOOP_SPEED')
        elseif message[2] == LP_LOOP then
            print('received LOOP')
        elseif message[2] == LP_OCTAVE then
            print('received OCTAVE')
        end

    end
end

function onReceiveMIDI(message)
    if message[1] == MIDIMessageType.SYSTEMEXCLUSIVE and #message == 14 then
        if table.isSame(SYSEX_START, table.slice(message, 1, 7)) then
            local sysexMessage = table.slice(message, 8, 13)
            receiveTenoriSysex(sysexMessage)
        else
            print('received unknown sysex')
            print(unpack(SYSEX_START))
            print(unpack(table.slice(message, 1, 7)))
        end
    end
end

----------------------------------
-- Here down be UTILITY dragons --
----------------------------------

function table.slice(tbl, first, last, step)
    local sliced = {}
    for i = first or 1, last or #tbl, step or 1 do
        sliced[#sliced + 1] = tbl[i]
    end

    return sliced
end

function table.concat(t1, t2)
    local newT = {}
    for _, v in ipairs(t1) do
        table.insert(newT, v)
    end
    for _, v in ipairs(t2) do
        table.insert(newT, v)
    end
    return newT
end

function table.isSame(a1, a2) -- algorithm is O(n log n), due to table growth.
    -- Check length, or else the loop isn't valid.
    if #a1 ~= #a2 then
        return false
    end

    -- Check each element.
    for i, v in ipairs(a1) do
        if v ~= a2[i] then
            return false
        end
    end
    return true
end

function strjoin(delimiter, list)
    local len = getn(list)
    if len == 0 then
        return ""
    end
    local string = list[1]
    for i = 2, len do
        string = string .. delimiter .. list[i]
    end
    return string
end

function tprint(tbl, indent)
    if not indent then
        indent = 0
    end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            tprint(v, indent + 1)
        elseif type(v) == 'boolean' then
            print(formatting .. tostring(v))
        else
            print(formatting .. v)
        end
    end
end
