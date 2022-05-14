function onValueChanged(key)
    if key == 'touch' and self.values[key] == true then
        root:notify('fullRandom')
    end
end
