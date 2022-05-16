MIN = 40
MAX = 240

local changedByDevice = false

function onValueChanged(key)
    if key == 'x' then
        local value = math.floor(MIN + self.values[key] * (MAX - MIN))
        self.parent.children[self.name .. 'Label'].values.text = value
        if not changedByDevice then
            root:notify(self.name, {
                ['value'] = value
            })
        end
        changedByDevice = false
    end
end

function onReceiveNotify(action, data)
    if action == self.name then
        changedByDevice = true
        self.values['x'] = (data.value - MIN) / (MAX - MIN)
    end
end
