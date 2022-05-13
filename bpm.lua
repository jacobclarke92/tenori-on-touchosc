MIN = 40
MAX = 240

local changedByDevice = false

function onValueChanged(key)
    if key == 'x' then
        if not changedByDevice then
            local bpm = math.floor(MIN + self.values[key] * (MAX - MIN))
            self.parent.children.bpmLabel.values.text = bpm
            root:notify('bpm', {
                ['bpm'] = bpm
            })
        end
        changedByDevice = false
    end
end

function onReceiveNotify(action, data)
    if action == 'bpm' then
        changedByDevice = true
        self.values['x'] = (data.bpm - MIN) / (MAX - MIN)
    end
end
