local menucontroller = {}

local no_item = plus.Class()
menucontroller.no_item = no_item

function no_item:init(menu)
    self.menu = menu
end

function no_item.create(menu)
    return no_item(menu)
end

function no_item:process_input(keystate)
    local menu = self.menu
    if menu.input_active then
        if keystate["shoot"] and menu.on_confirm then
            menu:on_confirm()
        end
        if keystate["spell"] and menu.on_cancel then
            menu:on_cancel()
        end
        if keystate["special"] and menu.on_special then
            menu:on_special()
        end
        if keystate["slow"] and menu.on_shift then
            menu:on_shift()
        end
    end
end

function no_item:frame(keystate)
    self:process_input(keystate)
end

local simple_list = plus.Class(no_item)
menucontroller.simple_list = simple_list

function simple_list:init(menu, pos_keyname, itemlist_keyname, next_key, previous_key, is_loop, select_se)
    self.menu = menu
    self.pos_keyname = pos_keyname
    self.itemlist_keyname = itemlist_keyname
    if type(menu[pos_keyname]) ~= "number" then
        menu[pos_keyname] = 1
    end
    if type(next_key) == "string" then
        self.next_key = {next_key}
    elseif type(next_key) == "table" then
        self.next_key = next_key
    else
        error("next_key 必须是string或者table类型")
    end
    if type(previous_key) == "string" then
        self.previous_key = {previous_key}
    elseif type(previous_key) == "table" then
        self.previous_key = previous_key
    else
        error("previous_key 必须是string或者table类型")
    end
    self.is_loop = is_loop
    self.select_se = select_se
end

function simple_list.create(menu, pos_keyname, itemlist_keyname, next_key, previous_key, is_loop, select_se)
    return simple_list(menu, pos_keyname, itemlist_keyname, next_key, previous_key, is_loop, select_se)
end

function simple_list:stabilize()
    --确定pos的值
    local menu = self.menu
    local itemlist = menu[self.itemlist_keyname]
    -- local item_num = #itemlist
    local pos_keyname = self.pos_keyname
    local pos = menu[pos_keyname]

    local map_index = {}
    local map_pos = 1
    for i, item in ipairs(itemlist) do
        if not item.unselectable then
            table.insert(map_index, i)
            if pos == i then
                map_pos = #map_index
            end
        end
    end
    menu[pos_keyname] = map_index[map_pos] or 0
    pos = menu[pos_keyname]
    for i, item in ipairs(itemlist) do
        if item.stabilize then
            local itemstate
            if menu.disable_itemselect then
                itemstate = "unselected"
            else
                if i == menu[pos_keyname] then
                    if not menu.itemselect_inactive then
                        itemstate = "selected"
                    else
                        itemstate = "inactive_selected"
                    end
                else
                    itemstate = "unselected"
                end
            end
            item:stabilize(menu, itemstate)
        end
    end
end

function simple_list:process_input(keystate)
    local menu = self.menu
    local itemlist = menu[self.itemlist_keyname]
    -- local item_num = #itemlist
    local pos_keyname = self.pos_keyname
    local pos = menu[pos_keyname]

    local map_index = {}
    local map_pos = 1
    for i, item in ipairs(itemlist) do
        if not item.unselectable then
            table.insert(map_index, i)
            if pos == i then
                map_pos = #map_index
            end
        end
    end
    local selectable_item_num = #map_index

    if menu.input_active then
        if selectable_item_num > 0 then
            local next_pos = map_pos - 1  --因为有取模运算，所以要先-1，之后再加1
            local pos_change = 0
            for _, k in ipairs(self.next_key) do
                if keystate[k] then
                    next_pos = next_pos + 1
                    if self.select_se then
                        self.select_se()
                    end
                    pos_change = 1
                    break
                end
            end
            for _, k in ipairs(self.previous_key) do
                if keystate[k] then
                    next_pos = next_pos - 1
                    if self.select_se then
                        self.select_se()
                    end
                    pos_change = -1
                    break
                end
            end
            if self.is_loop then
                next_pos = ((next_pos % selectable_item_num) + selectable_item_num) % selectable_item_num + 1
            else
                if menu.on_exceed then 
                    if next_pos < 1 then
                        menu:on_exceed("upper")
                    end
                    if next_pos > selectable_item_num then
                        menu:on_exceed("bottom")
                    end
                end
                next_pos = min(max(next_pos, 1), selectable_item_num)
            end
            menu[pos_keyname] = map_index[next_pos] or 0
            if pos_change ~= 0 then
                if menu.on_pos_change then
                    menu:on_pos_change(pos_change)
                end
            end
        else
            menu[pos_keyname] = 0
        end
        for i, item in ipairs(itemlist) do
            if item.process_input then
                local itemstate
                if i == menu[pos_keyname] then
                    if not menu.itemselect_inactive then
                        itemstate = "selected"
                    else
                        itemstate = "inactive_selected"
                    end
                else
                    itemstate = "unselected"
                end
                item:process_input(menu, keystate, itemstate)
            end
        end
        if not menu.no_call_menu_keyevents then
            no_item.process_input(self, keystate)
        end
    end
end

function simple_list:update_interpolation()
    local menu = self.menu
    local itemlist = menu[self.itemlist_keyname]
    local item_num = #itemlist
    local pos_keyname = self.pos_keyname
    local pos = menu[pos_keyname]

    for i, item in ipairs(itemlist) do
        if item.update_interpolation then
            local itemstate
            if menu.disable_itemselect then
                itemstate = "unselected"
            else
                if i == menu[pos_keyname] then
                    if not menu.itemselect_inactive then
                        itemstate = "selected"
                    else
                        itemstate = "inactive_selected"
                    end
                else
                    itemstate = "unselected"
                end
            end
            item:update_interpolation(menu, itemstate)
        end
    end
end

function simple_list:frame(keystate)
    self:process_input(keystate)
    self:update_interpolation()
end

function simple_list:render()
    local menu = self.menu
    local itemlist = menu[self.itemlist_keyname]
    if menu.render_active then
        for i, item in ipairs(itemlist) do
            if item.render then
                item:render(menu)
            end
        end
    end
end

local scroll_list = plus.Class(simple_list)
menucontroller.scroll_list = scroll_list

function scroll_list:init(menu, pos_keyname, itemlist_keyname, next_key, previous_key, is_loop, select_se, upper, bottom, length, layout_function, layout_parameters)
    simple_list.init(self, menu, pos_keyname, itemlist_keyname, next_key, previous_key, is_loop, select_se)
    --[[
        关于layout
        可以通过两种方式来设置layout 当layout_function, layout_parameters都填了的时候优先使用layout_function
        layout_function传入一个函数, 调用该函数时传入参数n来计算坐标，返回x, y
        eg.
        layout_function = function(n)
            return 100, 400 - (n - 1) * 50
        end
        layout_parameters为一个表
        layout_parameters = {
            x_initial = 0, --x坐标的初始值
            y_initial = 0, --y坐标的初始值
            x_increment = 0, --x坐标的增量
            y_increment = 0 --y坐标的增量
        }
    ]]
    self.upper = upper
    self.bottom = bottom
    self.length = length
    self.layout_type = nil
    self.layout = nil
    if type(layout_function) == "function" then
        self.layout_type = "function"
        self.layout = layout_function
    elseif type(layout_parameters) == "table" then
        self.layout_type = "parameters"
        self.layout = layout_parameters
        assert(type(layout_parameters.x_initial) == "number" and type(layout_parameters.y_initial) == "number" and type(layout_parameters.x_increment) == "number" and type(layout_parameters.y_increment) == "number",
            "[assertion failed] 参数layout_parameters无效, 如有疑问请查阅menucontroller.lua中的相关注释"
        )
    end
    if not self.layout_type then
        error("[assertion failed] 对于滚动菜单请指定有效的layout, 如有疑问请查阅menucontroller.lua中的相关注释")
    end
    self.offset = 0
    self.offset_interpolation = 0
end

function scroll_list.create(menu, pos_keyname, itemlist_keyname, next_key, previous_key, is_loop, select_se, upper, bottom, length, layout_function, layout_parameters)
    return scroll_list(menu, pos_keyname, itemlist_keyname, next_key, previous_key, is_loop, select_se, upper, bottom, length, layout_function, layout_parameters)
end

function scroll_list:stabilize()
    --确定pos的值
    local menu = self.menu
    local itemlist = menu[self.itemlist_keyname]
    local item_num = #itemlist
    local pos_keyname = self.pos_keyname
    local pos = menu[pos_keyname]

    local map_index = {}
    local map_pos = 1
    for i, item in ipairs(itemlist) do
        if not item.unselectable then
            table.insert(map_index, i)
            if pos == i then
                map_pos = #map_index
            end
        end
    end
    menu[pos_keyname] = map_index[map_pos] or 0
    pos = menu[pos_keyname]

    self.offset = 0
    local upper = self.upper
    local bottom = self.bottom
    local length = self.length
    local max_offset = max(item_num - length, 0)
    while (pos >= 1 + self.offset + length - bottom and self.offset < max_offset) do self.offset = self.offset + 1 end
    self.offset_interpolation = self.offset

    for i, item in ipairs(itemlist) do
        if item.stabilize then
            local itemstate
            if menu.disable_itemselect then
                itemstate = "unselected"
            else
                if i == menu[pos_keyname] then
                    if not menu.itemselect_inactive then
                        itemstate = "selected"
                    else
                        itemstate = "inactive_selected"
                    end
                else
                    itemstate = "unselected"
                end
            end
            local distance = 0
            local upper_bound = 1 + self.offset_interpolation
            local bottom_bound = length + self.offset_interpolation
            if upper_bound <= i and i <= bottom_bound then
                distance = 0
            else
                distance = max(upper_bound - i, i - bottom_bound)
            end
            item:stabilize(menu, itemstate, distance)
        end
    end
end

function scroll_list:update_interpolation()
    local menu = self.menu
    local itemlist = menu[self.itemlist_keyname]
    local item_num = #itemlist
    local pos_keyname = self.pos_keyname
    local pos = menu[pos_keyname]

    local upper = self.upper
    local bottom = self.bottom
    local length = self.length
    local max_offset = max(item_num - length, 0)

    while (pos <= self.offset + upper and self.offset > 0) do self.offset = self.offset - 1 end
    while (pos >= 1 + self.offset + length - bottom and self.offset < max_offset) do self.offset = self.offset + 1 end

    local gap = self.offset - self.offset_interpolation
    if (abs(gap) * (1 / 3) < 0.05) then
        self.offset_interpolation = self.offset
    else
        self.offset_interpolation = self.offset_interpolation + min(abs(gap) * (1 / 3), 1) * sign(gap)
    end

    for i, item in ipairs(itemlist) do
        local offset_index = i - self.offset_interpolation
        local item_x, item_y
        if self.layout_type == "function" then
            item_x, item_y = self.layout(offset_index)
        else
            item_x = self.layout.x_initial + self.layout.x_increment * (offset_index - 1)
            item_y = self.layout.y_initial + self.layout.y_increment * (offset_index - 1)
        end
        item.x, item.y = item_x, item_y
    end
    
    for i, item in ipairs(itemlist) do
        if item.update_interpolation then
            local itemstate
            if menu.disable_itemselect then
                itemstate = "unselected"
            else
                if i == menu[pos_keyname] then
                    if not menu.itemselect_inactive then
                        itemstate = "selected"
                    else
                        itemstate = "inactive_selected"
                    end
                else
                    itemstate = "unselected"
                end
            end
            local distance = 0
            local upper_bound = 1 + self.offset_interpolation
            local bottom_bound = length + self.offset_interpolation
            if upper_bound <= i and i <= bottom_bound then
                distance = 0
            else
                distance = max(upper_bound - i, i - bottom_bound)
            end
            item:update_interpolation(menu, itemstate, distance)
        end
    end
end

function scroll_list:frame(keystate)
    simple_list.process_input(self, keystate)
    self:update_interpolation()
end

function scroll_list:render()
    local menu = self.menu
    local itemlist = menu[self.itemlist_keyname]
    if menu.render_active then
        for i, item in ipairs(itemlist) do
            if item.render then
                item:render(menu)
            end
        end
    end
end

return menucontroller