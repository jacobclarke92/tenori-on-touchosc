local y, x = string.match(self.name, 'cell_y(%d+)x(%d+)')

local switchedByDevice = false

function onValueChanged(key)
    if key == 'x' and self.values[key] == 1 then
        if switchedByDevice == false then
            root:notify('cellSelect', {
                ['x'] = x,
                ['y'] = y
            })
        end
        switchedByDevice = false
    end
end

function onReceiveNotify(action, data)
    if action == 'on' then
        switchedByDevice = true
        self.values['x'] = 1

    elseif action == 'off' then
        self.values['x'] = 0

    elseif action == 'draw' then
        switchedByDevice = true
        self.values['x'] = data.value == true and 1 or 0

    else
        print('UNKNOWN ACTION', action)
    end
end
