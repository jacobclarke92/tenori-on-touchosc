local changedByDevice = false
local lastUpdate = getMillis()

function onValueChanged(key)
    if key == 'x' then
        if not changedByDevice then
            local now = getMillis()
            if (now - lastUpdate > 40) then
                root:notify('trackVolume', {
                    ['track'] = string.match(self.name, "%d+") - 1,
                    ['value'] = math.floor(self.values[key] * 127)
                })
            end
        end
        changedByDevice = false
    end
end

function onReceiveNotify(notificationType, data)
    if notificationType == 'value' then
        changedByDevice = true
        self.values['x'] = data / 127
    end
end
