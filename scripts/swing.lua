-- MIN = -23
-- MAX = 23
MIN = 0
MAX = 46

local lastUpdate = getMillis()
local changedByDevice = false

function onValueChanged(key)
    if key == 'x' then
        if not changedByDevice then
            local now = getMillis()
            if (now - lastUpdate > 40) then
                root:notify(self.name, {
                    ['value'] = math.floor(MIN + self.values[key] * (MAX - MIN))
                })
                lastUpdate = now
            end
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
