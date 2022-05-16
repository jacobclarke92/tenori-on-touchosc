local changedByDevice = false
local lastUpdate = getMillis()

function onValueChanged(key)
    if key == 'x' then
        self.parent.children[self.name .. 'Label'].values.text = math.floor(self.values[key] * 127)
        if not changedByDevice then
            local now = getMillis()
            if (now - lastUpdate > 100) then
                root:notify(self.name, {
                    ['value'] = math.floor(self.values[key] * 127)
                })
                lastUpdate = now
            end
        end
        changedByDevice = false
    end
end

function onReceiveNotify(action, data)
    if action == 'value' then
        changedByDevice = true
        self.values['x'] = data / 127
    end
end
