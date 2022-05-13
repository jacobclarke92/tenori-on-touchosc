local y = string.match(self.name, "%d+") - 1

local drawState = {}
for i = 1, 16 do
    drawState[i] = false
end

function onReceiveNotify(action, data)
    print('ledButtonRow', action)
    if action == 'xSelect' then
        root:notify('ledOn', {
            ['x'] = data.x,
            ['y'] = y
        })

    elseif action == 'on' then
        if (drawState[data.x] == false) then
            self.children['x' .. data.x]:notify('on')
        end

    elseif action == 'off' then
        if (drawState[data.x] == false) then
            self.children['x' .. data.x]:notify('off')
        end

    elseif action == 'draw' then
        drawState[data.x] = data.value
        self.children['x' .. data.x]:notify(drawState[data.x] == true and 'on' or 'off')

    elseif action == 'reset' then
        for i = 1, 16 do
            drawState[i] = false
            self.children['x' .. i]:notify('off')
        end

    end
end
