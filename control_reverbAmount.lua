local changedByDevice = false
local lastUpdate = getMillis()

function onValueChanged(key)
    if key == 'x' then
        if not changedByDevice then
            local now = getMillis()
            if (now - lastUpdate > 40) then
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
