SYSEX_START = {MIDIMessageType.SYSTEMEXCLUSIVE, 0x43, 0x73, 0x01, 0x33, 0x01, 0x00}

REVERB_TYPES = {
    [0x00] = 'NONE',
    [0x01] = 'HALL1',
    [0x02] = 'HALL2',
    [0x03] = 'ROOM1',
    [0x04] = 'ROOM2',
    [0x05] = 'ROOM3',
    [0x06] = 'STAGE1',
    [0x07] = 'STAGE2',
    [0x08] = 'PLATE1',
    [0x09] = 'PLATE2'
}

CHORUS_TYPES = {
    [0x00] = 'NONE',
    [0x01] = 'CHORUS1',
    [0x02] = 'CHORUS2',
    [0x03] = 'FLANGER1',
    [0x04] = 'FLANGER2'
}

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

-- MISC for readability
PLAY = 0x01
PAUSE = 0x00
MUTE = 0x01
UNMUTE = 0x00
ALL_BLOCKS = 0x11
ALL_LAYERS = 0x11
DRAW_ON = 0x00
DRAW_OFF = 0x01

-- APP STATE VARIABLES --
local bpm = 70
local currentTrack = 0
local currentBlock = 0
-------------------------

-- copy scripts for track select buttons
local trackSelectButtons = root:findAllByProperty('tag', 'trackSelect')
-- local trackSelectScript = root:findByName('trackSelectTemplate').script
-- for i = 1, #trackSelectButtons do
--     trackSelectButtons[i].script = trackSelectScript
-- end

-- copy scripts for track volume controls
local trackVolumeControls = root:findAllByProperty('tag', 'trackVolume')
-- local trackVolumeScript = root:findByName('trackVolumeTemplate').script
-- for i = 1, #trackVolumeControls do
--     trackVolumeControls[i].script = trackVolumeScript
-- end

-- copy scripts for track pan controls
local trackPanControls = root:findAllByProperty('tag', 'trackPan')
-- local trackPanScript = root:findByName('trackPanTemplate').script
-- for i = 1, #trackPanControls do
--     trackPanControls[i].script = trackPanScript
-- end

-- copy scripts for matrix cells
local cellMatrix = {}
for y = 1, 16 do
    cellMatrix[y] = {}
end
local cells = root:findAllByProperty('tag', 'cell')
-- local cellScript = root:findByName('cellTemplate').script
for i = 1, #cells do
    local cell = cells[i]
    local col = math.floor((cell.frame.x - GRID_START_X) / CELL_SIZE) + 1
    local row = math.floor((cell.frame.y - GRID_START_Y) / CELL_SIZE) + 1
    -- cell.script = cellScript
    cellMatrix[row][col] = cell
end

-- copy scripts for matrix row clear buttons
local clearRowButtons = {}
local clearRowButtonsRef = root:findAllByProperty('tag', 'clearRow')
-- local clearRowScript = root:findByName('clearRowTemplate').script
for i = 1, #clearRowButtonsRef do
    local elem = clearRowButtonsRef[i]
    local index = math.floor((elem.frame.y - GRID_START_Y) / CELL_SIZE) + 1
    -- print(elem.name .. ' -> ' .. index)
    elem.name = 'clearRow' .. index
    -- elem.script = clearRowScript
    clearRowButtons[index] = elem
end

-- copy scripts for matrix row fill buttons
local fillRowButtons = {}
local fillRowButtonsRef = root:findAllByProperty('tag', 'fillRow')
-- local fillRowScript = root:findByName('fillRowTemplate').script
for i = 1, #fillRowButtonsRef do
    local elem = fillRowButtonsRef[i]
    local index = math.floor((elem.frame.y - GRID_START_Y) / CELL_SIZE) + 1
    -- print(elem.name .. ' -> ' .. index)
    elem.name = 'fillRow' .. index
    -- elem.script = fillRowScript
    fillRowButtons[index] = elem
end

-- copy scripts for matrix row row randomize buttons
local randRowButtons = {}
local randRowButtonsRef = root:findAllByProperty('tag', 'randRow')
-- local randRowScript = root:findByName('randRowTemplate').script
for i = 1, #randRowButtonsRef do
    local elem = randRowButtonsRef[i]
    local index = math.floor((elem.frame.y - GRID_START_Y) / CELL_SIZE) + 1
    -- print(elem.name .. ' -> ' .. index)
    elem.name = 'randRow' .. index
    -- elem.script = randRowScript
    randRowButtons[index] = elem
end

-- reset track select state
for i = 1, #trackSelectButtons do
    trackSelectButtons[i]:notify(i == 1 and 'on' or 'off')
end

-- reset voume faders
for i = 1, #trackVolumeControls do
    trackVolumeControls[i]:notify('value', 107)
end

-- reset pan pots
for i = 1, #trackPanControls do
    trackPanControls[i]:notify('value', 64)
end

-- set up track loop state
local trackLoopPoints = {}
for i = 1, 16 do
    trackLoopPoints[i] = {0, 15}
end

-- set up grid state 
local drawState = {}
function initDrawState()
    for track = 1, 16 do
        drawState[track] = {}
        for block = 1, 16 do
            drawState[track][block] = {}
            for y = 1, 16 do
                drawState[track][block][y] = {}
                for x = 1, 16 do
                    drawState[track][block][y][x] = false
                end
            end
        end
    end
end
function resetTrackBlock(track, block)
    for y = 1, 16 do
        for x = 1, 16 do
            drawState[track][block][y][x] = false
        end
    end
end
initDrawState()

-- reset grid
function zeroOutGrid()
    for i = 1, #cells do
        cells[i]:notify('off')
    end
end
zeroOutGrid()

-- update 
function renderLoopPoints()
    self.children.loopStart:notify('loopStart', {
        ['value'] = trackLoopPoints[currentTrack + 1][1]
    })
    self.children.loopEnd:notify('loopEnd', {
        ['value'] = trackLoopPoints[currentTrack + 1][2]
    })
end

function renderGrid()
    print('rendering grid! track', currentTrack + 1, 'block', currentBlock + 1)
    tprint(drawState[currentTrack + 1][currentBlock + 1])
    for y = 1, 16 do
        for x = 1, 16 do
            local on = drawState[currentTrack + 1][currentBlock + 1][y][x]
            cellMatrix[y][x]:notify(on == true and 'on' or 'off')
        end
    end
end

function renderTrackChange()
    renderGrid()
    renderLoopPoints()
end

function onReceiveNotify(action, data)
    print('notified', action)
    if data then
        tprint(data)
    end
    if action == 'bpm' then
        local bit1 = data.value < 128 and 0x00 or 0x01
        local bit2 = data.value < 128 and data.value or data.value - 128
        sendTenoriSysex({COMMON_PARAM, CP_TEMPO, bit1, bit2, 0x00, 0x00})

    elseif action == 'swing' then
        sendTenoriSysex({COMMON_PARAM, CP_SWING, 0x00, data.value, 0x00, 0x00})

    elseif action == 'trackVolume' then
        sendTenoriSysex({LAYER_PARAM, LP_VOLUME, 0x00, data.value, data.track, 0x00})

    elseif action == 'trackPan' then
        sendTenoriSysex({LAYER_PARAM, LP_PAN, 0x00, data.value, data.track, 0x00})

    elseif action == 'loopStart' then
        local loopEnd = trackLoopPoints[currentTrack + 1][2] or 15
        local loopStart = data.value > loopEnd and loopEnd or data.value
        trackLoopPoints[currentTrack + 1][1] = loopStart
        sendTenoriSysex({LAYER_PARAM, LP_LOOP, loopStart, loopEnd, currentTrack, 0x00})

    elseif action == 'loopEnd' then
        local loopStart = trackLoopPoints[currentTrack + 1][1] or 0
        local loopEnd = data.value < loopStart and loopStart or data.value
        trackLoopPoints[currentTrack + 1][2] = loopEnd
        sendTenoriSysex({LAYER_PARAM, LP_LOOP, loopStart, loopEnd, currentTrack, 0x00})

    elseif action == 'trackSelect' then
        for i = 1, #trackSelectButtons do
            if (i ~= data.track + 1) then
                self.children['trackSelect' .. i]:notify('off')
            end
        end
        currentTrack = data.track
        renderTrackChange()
        sendTenoriSysex({CURRENT_TRACK_CHANGE, data.track, 0x00, 0x00, 0x00, 0x00})

    elseif action == 'ledOn' then
        sendTenoriSysex({LED_ON, data.x, data.y, currentTrack, 0x00, 0x00})

    elseif action == 'ledOff' then
        sendTenoriSysex({LED_OFF, data.x, data.y, currentTrack, 0x00, 0x00})

    elseif action == 'fillRowRandomly' then
        for x = 1, 16 do
            local newValue = math.random(0, 1) == 1 and true or false
            sendTenoriSysex({LED_HOLD, x - 1, data.y, currentTrack, newValue == true and DRAW_ON or DRAW_OFF, 0x00})
            drawState[currentTrack + 1][currentBlock + 1][data.y + 1][x] = newValue
            cellMatrix[data.y + 1][x]:notify('draw', {
                ['value'] = newValue
            })
        end

    elseif action == 'fillRow' then
        for x = 1, 16 do
            sendTenoriSysex({LED_HOLD, x - 1, data.y, currentTrack, DRAW_ON, 0x00})
            drawState[currentTrack + 1][currentBlock + 1][data.y + 1][x] = true
            cellMatrix[data.y + 1][x]:notify('draw', {
                ['value'] = true
            })
        end

    elseif action == 'clearRow' then
        for x = 1, 16 do
            sendTenoriSysex({LED_HOLD, x - 1, data.y, currentTrack, DRAW_OFF, 0x00})
            drawState[currentTrack + 1][currentBlock + 1][data.y + 1][x] = false
            cellMatrix[data.y + 1][x]:notify('draw', {
                ['value'] = false
            })
        end

    elseif action == 'clearGrid' then
        sendTenoriSysex({CLEAR, currentBlock, currentTrack, CLEAR_BLOCK[1], CLEAR_BLOCK[2], 0x00})
        resetTrackBlock(currentTrack + 1, currentBlock + 1)
        zeroOutGrid()

    elseif action == 'fullRandom' then
        for x = 1, 16 do
            local y = math.random(1, 16) -- maybe add some cool noise stuff here ???
            sendTenoriSysex({LED_HOLD, x - 1, y - 1, currentTrack, DRAW_ON, 0x00})
            drawState[currentTrack + 1][currentBlock + 1][y][x] = true
            cellMatrix[y][x]:notify('draw', {
                ['value'] = true
            })
        end

    elseif action == 'reverbType' then
        sendTenoriSysex({COMMON_PARAM, CP_REVERB_TYPE, 0x00, data.value, 0x00, 0x00})

    elseif action == 'reverbAmount' then
        sendTenoriSysex({COMMON_PARAM, CP_REVERB_AMOUNT, 0x00, data.value, 0x00, 0x00})

    elseif action == 'chorusType' then
        sendTenoriSysex({COMMON_PARAM, CP_CHORUS_TYPE, 0x00, data.value, 0x00, 0x00})

    elseif action == 'chorusAmount' then
        sendTenoriSysex({COMMON_PARAM, CP_CHORUS_AMOUNT, 0x00, data.value, 0x00, 0x00})

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
        trackSelectButtons[currentTrack + 1]:notify('on')
        for i = 1, #trackSelectButtons do
            if (i ~= currentTrack + 1) then
                trackSelectButtons[i]:notify('off')
            end
        end
        currentTrack = message[2]
        renderTrackChange()

    elseif message[1] == CLEAR then
        local block = message[2]
        local track = message[3]
        local b1 = message[4]
        local b2 = message[5]
        if (b1 == CLEAR_BLOCK[1] and b2 == CLEAR_BLOCK[2]) then
            print('received CLEAR_BLOCK')
            print('track', track + 1, 'block', block + 1)
            resetTrackBlock(track + 1, block + 1)
            if track == currentTrack and block == currentBlock then
                zeroOutGrid()
            end

            -- elseif (b1 == CLEAR_LAYER[1] and b2 == CLEAR_LAYER[2]) then
            --     print('received CLEAR_LAYER')

        elseif b1 == CLEAR_ALL_BLOCKS[1] and b2 == CLEAR_ALL_BLOCKS[2] then
            print('received CLEAR_ALL_BLOCKS')
            initDrawState()
            zeroOutGrid()

        elseif b1 == CLEAR_EVERYTHING[1] and b2 == CLEAR_EVERYTHING[2] then
            print('received CLEAR_EVERYTHING')
        end

    elseif message[1] == LED_ON then
        print('received LED_ON')
        if message[4] == currentTrack then
            local x = message[2] + 1
            local y = message[3] + 1
            cellMatrix[y][x]:notify('on')
        end

    elseif message[1] == LED_OFF then
        print('received LED_OFF')
        if message[4] == currentTrack then
            local x = message[2] + 1
            local y = message[3] + 1
            cellMatrix[y][x]:notify('off')
        end

    elseif message[1] == LED_HOLD then
        print('received LED_HOLD')
        local x = message[2] + 1
        local y = message[3] + 1
        local track = message[4]
        print('track', track, 'x', x, 'y', y, message[5] == DRAW_ON and 'on' or 'off')
        local newValue = message[5] == DRAW_ON and true or false
        drawState[track + 1][currentBlock + 1][y][x] = newValue
        if track == currentTrack then
            cellMatrix[y][x]:notify('draw', {
                ['value'] = newValue
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
                ['value'] = bpm
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
            self.children.swing:notify('value', {
                ['value'] = bit2
            })

        elseif message[2] == CP_REVERB_TYPE then
            print('received REVERB_TYPE')
            self.children.reverbType:notify('reverbType', {
                ['value'] = bit2
            })

        elseif message[2] == CP_REVERB_AMOUNT then
            print('received REVERB_AMOUNT')
            self.children.reverbAmount:notify('reverbAmount', {
                ['value'] = bit2
            })

        elseif message[2] == CP_CHORUS_TYPE then
            print('received CHORUS_TYPE')
            self.children.chorusType:notify('chorusType', {
                ['value'] = bit2
            })

        elseif message[2] == CP_CHORUS_AMOUNT then
            print('received CHORUS_AMOUNT')
            self.children.chorusAmount:notify('chorusAmount', {
                ['value'] = bit2
            })

        end

    elseif message[1] == LAYER_PARAM then
        local track = message[5]
        local value = message[4]
        if message[2] == LP_INSTRUMENT then
            print('received INSTRUMENT')
        elseif message[2] == LP_VOLUME then
            print('received VOLUME')
            self.children['trackVolume' .. (track + 1)]:notify('value', value)
        elseif message[2] == LP_PAN then
            print('received PAN')
            self.children['trackPan' .. (track + 1)]:notify('value', value)
        elseif message[2] == LP_SOUND_LENGTH then
            print('received SOUND_LENGTH')
        elseif message[2] == LP_LOOP_SPEED then
            print('received LOOP_SPEED')
        elseif message[2] == LP_LOOP then
            print('received LOOP')
            local loopStart = message[3]
            local loopEnd = message[4]
            trackLoopPoints[track + 1][1] = loopStart
            trackLoopPoints[track + 1][2] = loopEnd
            if track == currentTrack then
                renderLoopPoints()
            end
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
