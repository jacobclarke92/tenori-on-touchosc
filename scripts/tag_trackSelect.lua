local switchedOnByDevice = false

function onValueChanged(key)
    if key == 'x' and self.values[key] == 1 then
        if switchedOnByDevice == false then
            root:notify('trackSelect', {
                ['track'] = string.match(self.name, "%d+") - 1
            })
        end
        switchedOnByDevice = false
    end
end

function onReceiveNotify(notificationType, data)
    if notificationType == 'on' then
        switchedOnByDevice = true
        self.values['x'] = 1

    elseif notificationType == 'off' then
        self.values['x'] = 0
    end
end
