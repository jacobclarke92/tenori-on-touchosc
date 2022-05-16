function init()
    local yIndex = math.floor((self.frame.y - GRID_START_Y) / CELL_SIZE) + 1
    self.name = self.tag .. yIndex
end

function onValueChanged(key)
    if key == 'touch' and self.values[key] == true then
        root:notify('rowShift', {
            ['y'] = string.match(self.name, "%d+") - 1,
            ['amount'] = 1
        })
    end
end
