local external_menu_system = {}

local registered_menu_info = {}

function external_menu_system.register(menu_class, register_name, category, entrance_function, other)
    local info = {}
    info.menu_class = menu_class
    info.name = string.format("external_menu:%d_%s", #registered_menu_info + 1, register_name)
    info.register_name = register_name
    info.category = category
    info.entrance_function = entrance_function
    info.other = other or {}
    table.insert(registered_menu_info, info)
    return #registered_menu_info
end

function external_menu_system.get_menuinfo_by_index(index)
    local result = registered_menu_info[index]
    if result then return result else return false end
end

function external_menu_system.sort_menus_by_category(category)
    local result = {}
    for _, info in ipairs(registered_menu_info) do
        if info.category == category then
            table.insert(result, info)
        end
    end
    return result
end

function external_menu_system.debug_print()
    for i, v in ipairs(registered_menu_info) do
        print(i, v.name, v.register_name, v.category)
    end
end

return external_menu_system