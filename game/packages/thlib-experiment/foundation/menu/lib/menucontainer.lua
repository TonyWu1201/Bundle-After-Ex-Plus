local menucontainer = {}

local base_menustack = plus.Class()
menucontainer.base_menustack = base_menustack

function base_menustack:init()
    self.stack = {}
    self.menus = {}
    self.ordered_menus = {}
    self.layer_update = false
end

function base_menustack:get_menu(name)
    if self.menus[name] then
        return self.menus[name]
    else
        return false
    end
end

function base_menustack:create_menus(menu_list)
    for _, v in ipairs(menu_list) do
        self.menus[v[1]] = v[2](self)
    end
    for _, o in pairs(self.menus) do
        if o.after_init then o:after_init(self) end
    end
    self.layer_update = true
end

function base_menustack:push_stack(menu, callback_func)
    local info = {menu = menu, callback_func = callback_func}
    table.insert(self.stack, info)
end

function base_menustack:pop_stack()
    if #self.stack > 0 then
        return table.remove(self.stack, #self.stack)
    else
        return false
    end
end

function base_menustack:lastmenu_flyback()
    local lastmenu_info = self:pop_stack()
    if lastmenu_info then
        lastmenu_info.callback_func(lastmenu_info.menu)
    end
end

function base_menustack:set_layer(menu, layer)
    menu.layer = layer
    self.layer_update = true
end

function base_menustack:frame()
    for _, o in pairs(self.menus) do
        if o.frame then o:frame() end
    end
    if self.layer_update then
        self.layer_update = false
        local tmp = {}
        for _, o in pairs(self.menus) do
            if not o.layer then
                o.layer = 0
            end
            table.insert(tmp, o)
        end
        table.sort(tmp, function (a, b)
            return a.layer < b.layer
        end)
        self.ordered_menus = tmp
    end
end

function base_menustack:render()
    SetViewMode("ui")
    for _, o in ipairs(self.ordered_menus) do
        if o.render then o:render() end
    end
    SetViewMode("world")
end

return menucontainer