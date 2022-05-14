function onValueChanged(key)
    if key == 'touch' and self.values[key] == true then
        root:notify('fillRow', {
            ['y'] = string.match(self.name, "%d+") - 1
        })
    end
end
