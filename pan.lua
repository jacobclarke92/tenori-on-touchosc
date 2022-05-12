local allowNextSend = true
local lastUpdate = getMillis()

function onValueChanged(key)
    if key == 'x' then
        if (allowNextSend) then
            local now = getMillis()
            if (now - lastUpdate > 40) then
                root:notify('trackPan', {
                    ['track'] = string.match(self.name, "%d+") - 1,
                    ['value'] = math.floor(self.values[key] * 127)
                })
            end
        else
            allowNextSend = true
        end
    end
end

function onReceiveNotify(notificationType, data)
    if notificationType == 'value' then
        allowNextSend = false
        self.values['x'] = data / 127
    end
end
