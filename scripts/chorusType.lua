local changedByDevice = false

function onValueChanged(key)
    if key == 'x' then
        if not changedByDevice then
            local value = self.values[key]
            root:notify('reverbType', {
                ['value'] = value
            })
        end
        changedByDevice = false
    end
end

function onReceiveNotify(action, data)
    if action == 'reverbType' then
        changedByDevice = true
        self.values['x'] = data.value
    end
end