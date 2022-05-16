function onValueChanged(key)
    if key == 'touch' and self.values[key] == true then
        root:notify('gridShift', {
            ['amount'] = 1
        })
    end
end
