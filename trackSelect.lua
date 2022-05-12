function onValueChanged(key)
    if key == 'x' and self.values[key] == 1 then
        root:notify('trackSelect', {
            ['track'] = string.match(self.name, "%d+") - 1
        })
    end
end
