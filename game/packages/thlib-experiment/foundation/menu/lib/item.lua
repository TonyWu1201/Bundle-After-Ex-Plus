local item = {}

local base_item = plus.Class()
item.base_item = base_item

base_item.x = 0
base_item.y = 0

function base_item:init(menu)
end

function base_item:process_input(menu, keystate, itemstate) --itemstate selected unselected inactive_selected
end

function base_item:update_interpolation(menu, itemstate)
end

local simple_text_item = plus.Class(base_item)
item.simple_text_item = simple_text_item

function simple_text_item:init(text, font, inactive_color, active_color, on_confirm)
    self.text = text
    self.font = font
    self.inactive_color = inactive_color
    self.active_color = active_color
    self.color = inactive_color
    self.align = {"centerpoint"}
    self.size = 1
    self.t = 0
    self.max_lerp = 15
    self.x, self.y = 0, 0
    self.on_confirm = on_confirm
    self.select_timer = 0
end

function simple_text_item:process_input(menu, keystate, itemstate)
    if itemstate == "selected" then
        self.select_timer = self.select_timer + 1
    else
        self.select_timer = 0
    end
    if itemstate == "selected" and keystate["shoot"] then
        if self.on_confirm then
            self:on_confirm(menu)
        end
    end
end

function simple_text_item:stabilize(menu, itemstate)
    if itemstate == "selected" or itemstate == "inactive_selected" then
        self.t = self.max_lerp
    else
        self.t = 0
    end
    self.color = self.inactive_color * ((self.max_lerp - self.t) / self.max_lerp) + self.active_color * (self.t / self.max_lerp)
    if menu.alpha then
        self.color = self.color * Color(menu.alpha, 255, 255, 255)
    end
end

function simple_text_item:update_interpolation(menu, itemstate)
    if itemstate == "selected" or itemstate == "inactive_selected" then
        self.t = min(self.t + 3, self.max_lerp)
    else
        self.t = max(self.t - 1, 0)
    end
    self.color = self.inactive_color * ((self.max_lerp - self.t) / self.max_lerp) + self.active_color * (self.t / self.max_lerp)
    if menu.alpha then
        self.color = self.color * Color(menu.alpha, 255, 255, 255)
    end
end

function simple_text_item:render(menu)
    local x_offset, y_offset = 0, 0
    if self.render_offset then
        x_offset = self.render_offset.x or 0
        y_offset = self.render_offset.y or 0
    end
    RenderTTF2(self.font, self.text, self.x + x_offset, self.x + x_offset, self.y + y_offset, self.y + y_offset, self.size, self.color, unpack(self.align))
end

local simple_scroll_list_text_item = plus.Class(simple_text_item)
item.simple_scroll_list_text_item = simple_scroll_list_text_item

function simple_scroll_list_text_item:init(text, font, inactive_color, active_color, on_confirm, fade_distance)
    simple_text_item.init(self, text, font, inactive_color, active_color, on_confirm)
    self.distance_t = 0
    self.fade_distance = fade_distance
end

function simple_scroll_list_text_item:stabilize(menu, itemstate, distance)
    simple_text_item.stabilize(self, menu, itemstate)
    self.distance_t = min(1, distance / self.fade_distance)
    self.color = self.color * Color((1 - self.distance_t) * 255, 255, 255, 255)
end

function simple_scroll_list_text_item:update_interpolation(menu, itemstate, distance)
    simple_text_item.update_interpolation(self, menu, itemstate)
    self.distance_t = min(1, distance / self.fade_distance)
    self.color = self.color * Color((1 - self.distance_t) * 255, 255, 255, 255)
end

return item