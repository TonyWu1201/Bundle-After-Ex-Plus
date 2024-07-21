local utility = {}

utility.se = {}

function utility.se.play_confirm()
    PlaySound('ok00', 0.3)
end

function utility.se.play_select()
    PlaySound('select00', 0.3)
end

function utility.se.play_cancel()
    PlaySound('cancel00', 0.3)
end

function utility.se.play_invalid()
    PlaySound('invalid', 0.6)
end

function utility.quick_layout(itemlist, st_x, st_y, x_increment, y_increment, properties) --eg alignment
    local x, y = st_x, st_y
    for i, item in ipairs(itemlist) do
        item.x, item.y = x, y
        x, y = x + x_increment, y + y_increment
        item.index = i
        local _properties = sp.copy(properties, true)
        for k, v in pairs(_properties) do
            item[k] = v
        end
    end
end

return utility