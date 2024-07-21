local menu = {}

local base_menu = plus.Class()
menu.base_menu = base_menu

base_menu.input_active = false
base_menu.render_active = false
base_menu.itemselect_inactive = false --传递参数itemstate为 inactive_selected
base_menu.disable_itemselect = false --所有的itemstate均为 unselected

function base_menu:init()
end

function base_menu:after_init()
end

return menu