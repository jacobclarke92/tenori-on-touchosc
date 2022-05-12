SYSEX_START = {MIDIMessageType.SYSTEMEXCLUSIVE, 0x43, 0x73, 0x01, 0x33, 0x01, 0x00}

-- FADER_MIDI_DEBOUNCE_MS = 40

-- BIT 1
LED_ON = 0x02
LED_ON_DRAW = 0x03
LED_OFF = 0x04
LED_OFF_DRAW = 0x05
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

-- MISC
PLAY = 0x01
PAUSE = 0x00
MUTE = 0x01
UNMUTE = 0x00

function onReceiveNotify(notificationType, data)
    print('notified', notificationType)
    tprint(data)
    if notificationType == 'trackVolume' then
        sendTenoriSysex({LAYER_PARAM, LP_VOLUME, 0x00, data.value, data.track, 0x00})

    elseif notificationType == 'trackPan' then
        sendTenoriSysex({LAYER_PARAM, LP_PAN, 0x00, data.value, data.track, 0x00})

    elseif notificationType == 'trackSelect' then
        sendTenoriSysex({CURRENT_TRACK_CHANGE, data.track, 0x00, 0x00, 0x00, 0x00})
    end
end

function sendTenoriSysex(message)
    local fullMessage = table.concat(table.concat(SYSEX_START, message), {0xF7})
    tprint(fullMessage)
    sendMIDI(fullMessage)
end

function receiveTenoriSysex(message)
    if message[1] == PLAY_PAUSE then
        if message[2] == PLAY then
            print('received PLAY')
        elseif message[2] == PAUSE then
            print('received PAUSE')
        end

    elseif message[1] == COMMON_PARAM then
        if message[2] == CP_VOLUME then
            print('received VOLUME')
        elseif message[2] == CP_TEMPO then
            print('received TEMPO')
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

    elseif message[1] == CURRENT_TRACK_NOTIFY then
        print('received CURRENT_TRACK_NOTIFY')
        print('track', message[2])
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
