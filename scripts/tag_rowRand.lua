function onValueChanged(key)
    if key == 'touch' and self.values[key] == true then
        root:notify('fillRowRandomly', {
            ['y'] = string.match(self.name, "%d+") - 1
        })
    end
end
