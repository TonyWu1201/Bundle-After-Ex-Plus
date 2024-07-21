local menulib = {}

local path = "foundation.menu.lib."

menulib.item = require(path .. "item")
menulib.menucontroller = require(path .. "menucontroller")
menulib.menucontainer = require(path .. "menucontainer")
menulib.menu = require(path .. "menu")
menulib.utility = require(path .. "utility")
menulib.external_menu_system = require(path .. "external_menu_system")

return menulib