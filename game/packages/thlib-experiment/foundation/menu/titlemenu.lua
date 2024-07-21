local menulib = require("foundation.menu.lib.menulib")

local keys = {"up", "down", "left", "right", "slow", "shoot", "spell", "special"}
local function get_keystate()
    local keystate = {}
    for _, v in ipairs(keys) do
        keystate[v] = KeyIsPressed(v)
    end
    return keystate
end

local function exit_game()
    for i = 19, 0, -1 do
        SetBGMVolume('menu', i / 20)
        task.Wait(1)
    end
    stage.Set("stage.quit")
end

local function default_fade_in(menu)
    task.New(menu, function ()
        menu.render_active = true
        for i = 0, 15 do
            menu.alpha = 255 * i / 15
            task.Wait(1)
        end
        menu.input_active = true
    end)
end

local function default_fade_out(menu)
    task.New(menu, function ()
        menu.input_active = false
        for i = 15, 0, -1 do
            menu.alpha = 255 * i / 15
            task.Wait(1)
        end
        menu.render_active = false
    end)
end

local function get_stage_display_name(s)
    local index = 0
    while true do
        local next = string.find(s, '@', index + 1)
        if next == nil then
            break
        else
            index = next
        end
    end
    return string.sub(s, 1, index - 1)
end

local function is_weekend()
    return type(ui.lstg_weekly) == "table"
end

local title = {}

local startup_info = {
    --[[
        mode : stage_group  stage  sc_practice replay
        sc_practice_mode : legacy new weekend
        stage_group_name = xxx
        stage_name = xxx
        sc_index = xxx
        replay_info = xxx
        player_info = xxx
        practice_properties = xxx
    ]]
}

local last_time_startup_info = {}

local function start_game()
    if startup_info.mode == "replay" then
        stage.Set(startup_info.replay_info.stage_name, 'load', startup_info.replay_info.replay_path)
    else
        lstg.var.player_name = startup_info.player_info.classname
        lstg.var.rep_player = startup_info.player_info.replayname
        if startup_info.mode == "stage_group" then
            stage.group.Start(startup_info.stage_group_name)
        elseif startup_info.mode == "stage" then
            stage.group.PracticeStart(startup_info.stage_name)
        elseif startup_info.mode == "sc_practice" then
            if not is_weekend() then
                lstg.var.sc_index = startup_info.sc_index
            else
                lstg.var.sc_pr = {
                    class_name = startup_info.weekend_scpr.class_name,
                    index = startup_info.weekend_scpr.index,
                    perform = startup_info.weekend_scpr.perform,
                }
            end
            stage.group.PracticeStart("Spell Practice@Spell Practice")
        end
    end
    last_time_startup_info = sp.copy(startup_info, true)
    startup_info = {}
end

local load_resources = function ()
    LoadImageFromFile("menu_bg", "THlib/UI/menu_bg.png")
    MusicRecord("menu", 'THlib/music/luastg 0.08.540 - 1.27.800.ogg', 87.8, 79.26)
    MusicRecord("spellcard", 'THlib/music/spellcard.ogg', 75, 0xc36e80 / 44100 / 4)
    LoadMusicRecord("menu")
    LoadTTF("menu_ttf", "assets/font/SourceHanSansCN-Bold.otf", 36)
    LoadTTF("menu_ttf_mono", "assets/font/wqy-microhei-mono.ttf", 36)
end
title.load_resources = load_resources

local select_sc_practice_weekend_menu_index = 0

--[[
通过此函数来注册周末活动的符卡练习菜单
请在LuaSTG_Weekend_Extension中编写菜单以便读取信息

以下为编写说明

关于注册
1.加载menulib
local menulib = require("foundation.menu.lib.menulib")

2.注册外部菜单
local index = menulib.external_menu_system.register(menu_class, register_name, category, entrance_function, other)
other可以为空  category为'title'

3.注册符卡练习
local title = require("foundation.menu.titlemenu")
title.register_select_sc_practice_weekend_menu(index)
index即为上一步中的index

关于回调函数和必须的行为
menu.init 传入两个参数 menu(self)和stack  其中stack即下面的titlestack对象

menu.after_init 传入一个参数 menu(self)

menu.frame 传入一个参数 menu(self)

menu.render 传入一个参数 menu(self)

default_entrance_function 传入三个参数 menu(self) startup_info call_next_menu
*注意 请在startup_info.weekend_scpr(下文记作info)中写入相关信息
info.class_name Boss类在_editor_class中的键值
info.index 符卡在boss.cards中的键值
info.perform 是否有前置动作
完成以上操作后调用call_next_menu使下一个菜单进入 不需要传入参数  *注意该函数不会使符卡练习菜单退出

menu.set_pos 传入两个参数 menu(self) last_time_startup_info
此函数用于在练习结束重新进入菜单时设置光标 last_time_startup_info即上一次设置的startup_info

如果要返回符卡练习上一个菜单，需要调用 stack:lastmenu_flyback()
]]
local register_select_sc_practice_weekend_menu = function (index)
    select_sc_practice_weekend_menu_index = index
end
title.register_select_sc_practice_weekend_menu = register_select_sc_practice_weekend_menu

local title_bg = plus.Class(menulib.menu.base_menu)

function title_bg:init(stack)
    stack:set_layer(self, -100)
    self.t = 0
    task.New(self, function ()
        for i = 1, 15 do
            self.t = i
            task.Wait(1)
        end
    end)
end

function title_bg:frame()
    task.Do(self)
end

function title_bg:render()
    SetImageState("menu_bg", "", Color(255 * (self.t / 15), 255, 255, 255))
    Render("menu_bg", 320, 240)
end

local info_display = plus.Class(menulib.menu.base_menu)

function info_display:init(stack)
    stack:set_layer(self, -99)
end

function info_display:render()
    local major, minor, patch = GetVersionNumber()
    RenderTTF2("menu_ttf", string.format("引擎版本: %d.%d.%d", major, minor, patch), 640 - 10, 640 - 10, 90, 90, 0.6, Color(255, 255, 255, 255), "right", "bottom")
    RenderTTF2("menu_ttf", string.format("脚本包版本: %s", gconfig.bundle_version), 640 - 10, 640 - 10, 70, 70, 0.6, Color(255, 255, 255, 255), "right", "bottom")
    RenderTTF2("menu_ttf", string.format("当前mod: %s", setting.mod), 640 - 10, 640 - 10, 50, 50, 0.6, Color(255, 255, 255, 255), "right", "bottom")
    RenderTTF2("menu_ttf", string.format("%d obj", GetnObj()), 640 - 10, 640 - 10, 30, 30, 0.6, Color(255, 255, 255, 255), "right", "bottom")
    RenderTTF2("menu_ttf", string.format("%.1f fps", GetFPS()), 640 - 10, 640 - 10, 10, 10, 0.6, Color(255, 255, 255, 255), "right", "bottom")
end

local top_menu = plus.Class(menulib.menu.base_menu)

function top_menu:init(stack)
    self.alpha = 0
    self.pos = 1
    stack:set_layer(self, 0)
    self.menustack = stack
    self.itemlist ={
        --text, font, inactive_color, active_color, on_confirm
        menulib.item.simple_text_item("选择关卡组开始游戏", "menu_ttf", Color(255, 255, 255, 255), Color(255, 255, 222, 89), function (self, menu)
            menulib.utility.se.play_confirm()
            default_fade_out(menu)
            local select_stage_group_menu = menu.menustack:get_menu("select_stage_group")
            select_stage_group_menu:set_type_and_refresh("stage_group")
            startup_info = {}
            startup_info.mode = "stage_group"
            select_stage_group_menu:fade_in()
            menu.menustack:push_stack(menu, default_fade_in)
        end),
        menulib.item.simple_text_item("选择关卡进行练习", "menu_ttf", Color(255, 255, 255, 255), Color(255, 255, 222, 89), function (self, menu)
            menulib.utility.se.play_confirm()
            default_fade_out(menu)
            local select_stage_group_menu = menu.menustack:get_menu("select_stage_group")
            select_stage_group_menu:set_type_and_refresh("stage")
            startup_info = {}
            startup_info.mode = "stage"
            select_stage_group_menu:fade_in()
            menu.menustack:push_stack(menu, default_fade_in)
        end),
        menulib.item.simple_text_item("选择符卡进行练习(legacy)", "menu_ttf", Color(255, 255, 255, 255), Color(255, 255, 222, 89), function (self, menu)
            if is_weekend() then
                menulib.utility.se.play_invalid()
            else
                menulib.utility.se.play_confirm()
                default_fade_out(menu)
                local select_sc_practice_legacy_menu = menu.menustack:get_menu("select_sc_practice_legacy")
                startup_info = {}
                startup_info.mode = "sc_practice"
                startup_info.sc_practice_mode = "legacy"
                select_sc_practice_legacy_menu:set_index(1)
                default_fade_in(select_sc_practice_legacy_menu)
                menu.menustack:push_stack(menu, default_fade_in)
            end
        end),
        menulib.item.simple_text_item("选择符卡进行练习(weekend)", "menu_ttf", Color(255, 255, 255, 255), Color(255, 255, 222, 89), function (self, menu)
            if is_weekend() then
                local select_sc_practice_weekend_menu_info = menulib.external_menu_system.get_menuinfo_by_index(select_sc_practice_weekend_menu_index)
                Print(select_sc_practice_weekend_menu_info)
                if select_sc_practice_weekend_menu_info then
                    local select_sc_practice_weekend_menu = menu.menustack:get_menu(select_sc_practice_weekend_menu_info.name)
                    local entrance_function = select_sc_practice_weekend_menu_info.entrance_function
                    if select_sc_practice_weekend_menu then
                        menulib.utility.se.play_confirm()
                        default_fade_out(menu)
                        menu.menustack:push_stack(menu, default_fade_in)
                        startup_info = {}
                        startup_info.mode = "sc_practice"
                        startup_info.sc_practice_mode = "weekend"
                        local select_player_menu = menu.menustack:get_menu("select_player")
                        entrance_function(select_sc_practice_weekend_menu, startup_info, function ()
                            default_fade_in(select_player_menu)
                        end)
                    end
                else
                    menulib.utility.se.play_invalid()
                end
            else
                menulib.utility.se.play_invalid()
            end
        end),
        menulib.item.simple_text_item("选择符卡进行练习(new) 以后再说", "menu_ttf", Color(255, 255, 255, 255), Color(255, 255, 222, 89), function (self, menu)
            menulib.utility.se.play_confirm()
        end),
        menulib.item.simple_text_item("播放录像", "menu_ttf", Color(255, 255, 255, 255), Color(255, 255, 222, 89), function (self, menu)
            menulib.utility.se.play_confirm()
            local select_replay_menu = menu.menustack:get_menu("select_replay")
            startup_info = {}
            startup_info.mode = "replay"
            select_replay_menu:set_mode("view")
            default_fade_in(select_replay_menu)
            default_fade_out(menu)
            menu.menustack:push_stack(menu, default_fade_in)
        end),
        menulib.item.simple_text_item("设置", "menu_ttf", Color(255, 255, 255, 255), Color(255, 255, 222, 89), function (self, menu)
            menulib.utility.se.play_confirm()
        end),
        menulib.item.simple_text_item("关于", "menu_ttf", Color(255, 255, 255, 255), Color(255, 255, 222, 89), function (self, menu)
            menulib.utility.se.play_confirm()
        end),
        menulib.item.simple_text_item("选择其他mod", "menu_ttf", Color(255, 255, 255, 255), Color(255, 255, 222, 89), function (self, menu)
            menulib.utility.se.play_confirm()
        end),
        menulib.item.simple_text_item("退出", "menu_ttf", Color(255, 255, 255, 255), Color(255, 255, 80, 80), function (self, menu)
            menulib.utility.se.play_cancel()
            default_fade_out(menu)
            task.New(menu, function ()
                exit_game()
            end)
        end)
    }
    menulib.utility.quick_layout(self.itemlist, 60, 400, 0, -25, {
        align = {"left", "vcenter"}
    })
    --menu, pos_keyname, itemlist_keyname, next_key, previous_key, is_loop, select_se
    self.controller = menulib.menucontroller.simple_list.create(self, "pos", "itemlist", "down", "up", true, menulib.utility.se.play_select)
end

function top_menu:frame()
    task.Do(self)
    self.controller:frame(get_keystate())
end

function top_menu:render()
    if self.render_active then
        SetImageState("white", "", Color(160 * (self.alpha / 255), 0, 0, 0))
        Render4V("white",
            40, 420, 0.5,
            320, 420, 0.5,
            320, 140, 0.5,
            40, 140, 0.5
        )
    end
    self.controller:render()
end

function top_menu:on_cancel()
    if self.pos ~= #self.itemlist then
        self.pos = #self.itemlist
        menulib.utility.se.play_cancel()
    else
        self.itemlist[self.pos]:on_confirm(self)
    end
end

local select_stage_group = plus.Class(menulib.menu.base_menu)

function select_stage_group:init(stack)
    self.menustack = stack
    stack:set_layer(self, 1)
    self.pos = 1
    self.itemlist = {}
    for _, name in ipairs(stage.groups) do
        if name ~= 'Spell Practice' then --以后要改一下
            --text, font, inactive_color, active_color, on_confirm, fade_distance
            local item = menulib.item.simple_scroll_list_text_item(name, "menu_ttf", Color(255, 255, 255, 255), Color(255, 255, 222, 89), function (self, menu) end, 2)
            item.align = {"left", "vcenter"}
            item.stage_group_name = name
            table.insert(self.itemlist, item)
        end
    end
    --menu, pos_keyname, itemlist_keyname, next_key, previous_key, is_loop, select_se, upper, bottom, length, layout_function, layout_parameters
    self.controller = menulib.menucontroller.scroll_list.create(self, 'pos', 'itemlist', 'down', 'up', true,
        menulib.utility.se.play_select, 2, 2, 8, nil,
        {x_initial = 60, y_initial = 360, x_increment = 0, y_increment = -25}
    )
    self.type = "stage_group" --stage_group或者是stage
    self.screen_input = false
end

function select_stage_group:after_init()
    self.select_stage_menu = self.menustack:get_menu("select_stage")
end

function select_stage_group:set_type_and_refresh(type)
    self.type = type
    self.pos = 1
    self:on_pos_change()
end

function select_stage_group:frame()
    task.Do(self)
    if self.screen_input then
        self.controller:frame({})
        self.screen_input = false
    else
        self.controller:frame(get_keystate())
    end
end

function select_stage_group:render()
    if self.render_active then
        SetImageState("white", "", Color(160 * (self.alpha / 255), 0, 0, 0))
        Render4V("white",
            40, 420, 0.5,
            200, 420, 0.5,
            200, 120, 0.5,
            40, 120, 0.5
        )
    end
    self.controller:render()
end

function select_stage_group:fade_in()
    if self.type == "stage_group" then
        default_fade_in(self)
    else
        default_fade_in(self)
        self.select_stage_menu:show()
    end
end

function select_stage_group:fade_out()
    if self.type == "stage_group" then
        default_fade_out(self)
    else
        default_fade_out(self)
        self.select_stage_menu:hide()
    end
end

function select_stage_group:enable_input()
    self.input_active = true
    self.itemselect_inactive = false
end

function select_stage_group:disable_input()
    self.input_active = false
    self.itemselect_inactive = true
end

function select_stage_group:show()
    task.New(self, function ()
        self.render_active = true
        for i = 0, 15 do
            self.alpha = 255 * i / 15
            task.Wait(1)
        end
    end)
end

function select_stage_group:hide()
    task.New(self, function ()
        for i = 15, 0, -1 do
            self.alpha = 255 * i / 15
            task.Wait(1)
        end
        self.render_active = false
    end)
end

function select_stage_group:on_pos_change()
    if self.type == "stage" then
        local item = self.itemlist[self.pos]
        if item then
            self.select_stage_menu:load_stage_list(item.stage_group_name)
        end
    end
end

function select_stage_group:on_confirm()
    local item = self.itemlist[self.pos]
    if item then
        menulib.utility.se.play_confirm()
        startup_info.stage_group_name = item.stage_group_name
        if self.type == "stage_group" then
            self:fade_out()
            self.menustack:push_stack(self, self.fade_in)
            local select_player_menu = self.menustack:get_menu("select_player")
            default_fade_in(select_player_menu)
        else
            self:disable_input()
            self.select_stage_menu.screen_input = true
            self.select_stage_menu:enable_input()
        end
    end
end

function select_stage_group:on_cancel()
    menulib.utility.se.play_cancel()
    self:fade_out()
    self.menustack:lastmenu_flyback()
end

local select_stage = plus.Class(menulib.menu.base_menu)

function select_stage:init(stack)
    self.menustack = stack
    stack:set_layer(self, 1)
    self.pos = 1
    self.itemlist = {}
    self.controller = menulib.menucontroller.scroll_list.create(self, 'pos', 'itemlist', 'down', 'up', true,
        menulib.utility.se.play_select, 2, 2, 8, nil,
        {x_initial = 320, y_initial = 360, x_increment = 0, y_increment = -25}
    )
    self.disable_itemselect = true
    self.screen_input = false
end

function select_stage:load_stage_list(stage_group_name)
    self.itemlist = {}
    local sg = stage.group.Find(stage_group_name)
    assert(type(sg) == "table")
    for _, stage in ipairs(sg.stages) do
        local name = stage.stage_name
        -- local display_name = string.match(name, "^[%w_][%w_ ]*")
        local display_name = get_stage_display_name(name)
        local item = menulib.item.simple_scroll_list_text_item(display_name, "menu_ttf", Color(255, 255, 255, 255), Color(255, 255, 222, 89), function (self, menu) end, 2)
        item.align = {"left", "vcenter"}
        item.stage_name = name
        table.insert(self.itemlist, item)
    end
    self.pos = 1
    self.controller:update_interpolation()
end

function select_stage:after_init()
    self.select_stage_group_menu = self.menustack:get_menu("select_stage_group")
end

function select_stage:frame()
    task.Do(self)
    if self.screen_input then
        self.controller:frame({})
        self.screen_input = false
    else
        self.controller:frame(get_keystate())
    end
end

function select_stage:render()
    if self.render_active then
        SetImageState("white", "", Color(160 * (self.alpha / 255), 0, 0, 0))
        Render4V("white",
            300, 420, 0.5,
            480, 420, 0.5,
            480, 120, 0.5,
            300, 120, 0.5
        )
    end
    self.controller:render()
end

function select_stage:show()
    task.New(self, function ()
        self.render_active = true
        for i = 0, 15 do
            self.alpha = 255 * i / 15
            task.Wait(1)
        end
    end)
end

function select_stage:hide()
    task.New(self, function ()
        for i = 15, 0, -1 do
            self.alpha = 255 * i / 15
            task.Wait(1)
        end
        self.render_active = false
    end)
end

function select_stage:enable_input()
    self.input_active = true
    self.disable_itemselect = false
end

function select_stage:disable_input()
    self.input_active = false
    self.disable_itemselect = true
end

function select_stage:on_confirm()
    local item = self.itemlist[self.pos]
    if item then
        menulib.utility.se.play_confirm()
        startup_info.stage_name = item.stage_name
        self.select_stage_group_menu:hide()
        default_fade_out(self)
        self.menustack:push_stack(self, function (_self)
            _self.select_stage_group_menu:show()
            default_fade_in(_self)
        end)
        local select_player_menu = self.menustack:get_menu("select_player")
        default_fade_in(select_player_menu)
    end
end

function select_stage:on_cancel()
    menulib.utility.se.play_cancel()
    self:disable_input()
    self.select_stage_group_menu.screen_input = true
    self.select_stage_group_menu:enable_input()
end

local select_player = plus.Class(menulib.menu.base_menu)

function select_player:init(stack)
    self.menustack = stack
    stack:set_layer(self, 2)
    self.itemlist = {}
    self.pos = 1
    self.controller = menulib.menucontroller.scroll_list.create(self, 'pos', 'itemlist', 'down', 'up', true,
        menulib.utility.se.play_select, 2, 2, 8, nil,
        {x_initial = 200, y_initial = 360, x_increment = 0, y_increment = -25}
    )
    for _, info in ipairs(player_list) do
        local item = menulib.item.simple_scroll_list_text_item(info[1], "menu_ttf", Color(255, 255, 255, 255), Color(255, 255, 222, 89), function (self, menu) end, 2)
        item.align = {"left", "vcenter"}
        item.player_info = {classname = info[2], replayname = info[3]}
        table.insert(self.itemlist, item)
    end
    self.timer = 0
end

function select_player:frame()
    task.Do(self)
    self.controller:frame(get_keystate())
    self.timer = self.timer + 1
    local k = (sin(self.timer * 2) + 1) / 2
    self.hintcolor = Color(255, 255, 255, 10) * k + Color(255, 255, 255, 255) * (1 - k)
end

function select_player:render()
    if self.render_active then
        SetImageState("white", "", Color(160 * (self.alpha / 255), 0, 0, 0))
        Render4V("white",
            180, 420, 0.5,
            460, 420, 0.5,
            460, 100, 0.5,
            180, 100, 0.5
        )
    end
    self.controller:render()
    if self.render_active and (startup_info.mode == "stage" or startup_info.mode == "sc_practice") then
        RenderTTF2("menu_ttf", "按下 SPECIAL 键可设置练习时的各项参数", 320, 320, 120, 120, 0.7, Color(self.alpha , 255, 255, 255) * self.hintcolor, "centerpoint")
    end
end

function select_player:on_confirm()
    local item = self.itemlist[self.pos]
    if item then
        startup_info.player_info = item.player_info
        menulib.utility.se.play_confirm()
        default_fade_out(self)
        New(mask_fader, 'close')
        task.New(self, function ()
            for i = 19, 0, -1 do
                SetBGMVolume('menu', i / 20)
                task.Wait(1)
            end
            start_game()
        end)
    end
end

function select_player:on_special()
    local item = self.itemlist[self.pos]
    if item then
        startup_info.player_info = item.player_info
        menulib.utility.se.play_confirm()
        default_fade_out(self)
        self.menustack:push_stack(self, default_fade_in)
        local set_practice_properties_menu = self.menustack:get_menu("set_practice_properties")
        default_fade_in(set_practice_properties_menu)
    end
end

function select_player:on_cancel()
    menulib.utility.se.play_cancel()
    default_fade_out(self)
    self.menustack:lastmenu_flyback()
end

local set_practice_properties = plus.Class(menulib.menu.base_menu)

function set_practice_properties:init(stack)
    self.menustack = stack
    self.itemlist = {}
    self.pos = 1
    self.controller = menulib.menucontroller.simple_list.create(self, "pos", "itemlist", "down", "up", true, menulib.utility.se.play_select)
end

function set_practice_properties:frame()
    task.Do(self)
    self.controller:frame(get_keystate())
end

function set_practice_properties:render()
    if self.render_active then
        RenderTTF2("menu_ttf", "功能未实装", 320, 320, 240, 240, 2, Color(self.alpha , 255, 0, 0), "centerpoint")
    end
    self.controller:render()
end

function set_practice_properties:on_confirm()
    menulib.utility.se.play_invalid()
end

function set_practice_properties:on_cancel()
    menulib.utility.se.play_cancel()
    default_fade_out(self)
    self.menustack:lastmenu_flyback()
end

local select_sc_practice_legacy = plus.Class(menulib.menu.base_menu)

function select_sc_practice_legacy:init(stack)
    self.menustack = stack
    self.controller = menulib.menucontroller.no_item.create(self)
    stack:set_layer(self, 3)
    self.npage = max(int((#_sc_table - 1) / ui.menu.sc_pr_line_per_page) + 1, 1)
    self.page = 0
    self.pos = 1
    self.item_t = {}
    for  i = 1, ui.menu.sc_pr_line_per_page do
        self.item_t[i] = 0
    end
end

function select_sc_practice_legacy:frame()
    task.Do(self)
    if self.input_active then
        local keystate = get_keystate()
        if keystate["up"] then
            self.pos = self.pos - 1
            menulib.utility.se.play_select()
        end
        if keystate["down"] then
            self.pos = self.pos + 1
            menulib.utility.se.play_select()
        end
        self.pos = (self.pos + ui.menu.sc_pr_line_per_page - 1) % ui.menu.sc_pr_line_per_page + 1
        if keystate["left"] then
            self.page = self.page - 1
            menulib.utility.se.play_select()
        end
        if keystate["right"] then
            self.page = self.page + 1
            menulib.utility.se.play_select()
        end
        self.page = (self.page + self.npage) % self.npage
        self.controller:frame(get_keystate())
    end
    for  i = 1, ui.menu.sc_pr_line_per_page do
        if i == self.pos then
            self.item_t[i] = min(self.item_t[i] + 3, 15)
        else
            self.item_t[i] = max(self.item_t[i] - 1, 0)
        end
    end
end

function select_sc_practice_legacy:render()
    if self.render_active then
        SetImageState("white", "", Color(160 * (self.alpha / 255), 0, 0, 0))
        Render4V("white",
            80, 450, 0.5,
            560, 450, 0.5,
            560, 80, 0.5,
            80, 80, 0.5
        )
        local text1 = {}
        local text2 = {}
        local color = {}
        local offset = self.page * ui.menu.sc_pr_line_per_page
        for i = 1, ui.menu.sc_pr_line_per_page do
            if _sc_table[i + offset] then
                text1[i] = _editor_class[_sc_table[i + offset][1]].name
                text2[i] = _sc_table[i + offset][2]
            else
                text1[i] = '---'
                text2[i] = '---'
            end
            local k = self.item_t[i] / 15
            color[i] = (Color(255, 255, 255, 255) * (1 - k) + Color(255, 255, 222, 89) * k) * Color(self.alpha, 255, 255, 255)
        end
        for i = 1, ui.menu.sc_pr_line_per_page do
            local render_y = 430 - 25 * (i - 1)
            RenderTTF2("menu_ttf", text1[i], 100, 100, render_y, render_y, 0.75, color[i], "left", "vcenter")
            RenderTTF2("menu_ttf", text2[i], 540, 540, render_y, render_y, 0.75, color[i], "right", "vcenter")
        end
        RenderTTF2('menu_ttf', 'Spell Practice', 320, 320, 125, 125, 0.75, Color(self.alpha, 255, 255, 255), 'centerpoint')
        RenderTTF2('menu_ttf', string.format('<  page %d / %d  >', self.page + 1, self.npage), 320, 320, 100, 100, 0.75, Color(self.alpha, 255, 255, 255), 'centerpoint')
    end
end

function select_sc_practice_legacy:on_confirm()
    local index = self.pos + self.page * ui.menu.sc_pr_line_per_page
    if _sc_table[index] then
        -- if not startup_info.mode then
        --     startup_info.mode = "sc_practice"
        --     startup_info.sc_practice_mode = "legacy"
        -- end
        startup_info.sc_index = index
        menulib.utility.se.play_confirm()
        self.menustack:push_stack(self, default_fade_in)
        default_fade_out(self)
        local select_player_menu = self.menustack:get_menu("select_player")
        default_fade_in(select_player_menu)
    else
        menulib.utility.se.play_invalid()
    end
end

function select_sc_practice_legacy:on_cancel()
    menulib.utility.se.play_cancel()
    default_fade_out(self)
    self.menustack:lastmenu_flyback()
end

function select_sc_practice_legacy:set_index(index)
    self.pos = index
    self.page = int(index / ui.menu.sc_pr_line_per_page)
end

local select_replay = plus.Class(menulib.menu.base_menu)

function select_replay:init(stack)
    self.menustack = stack
    self.mode = "view"
    self:refresh_replay_slot()
    self.controller = menulib.menucontroller.simple_list.create(self, "pos", "itemlist", "down", "up", true, menulib.utility.se.play_select)
end

function select_replay:refresh_replay_slot(pos)
    self.replay_info = {}
    self.pos = pos or 1
    self.itemlist = {}
    
    ext.replay.RefreshReplay()
    local max_num = ext.replay.GetSlotCount()
    for i = 1, max_num do
        local info = {}
        local slot = ext.replay.GetSlot(i)
        if slot then
            -- 使用第一关的时间作为录像时间
            local date = os.date("!%Y/%m/%d", slot.stages[1].stageDate + setting.timezone * 3600)

            -- 统计总分数
            local totalScore = 0
            local diff, stage_num
            local tmp
            for j, k in ipairs(slot.stages) do
                totalScore = totalScore + slot.stages[j].score
                diff = string.match(k.stageName, '^.+@(.+)$')
                tmp = string.match(k.stageName, '^(.+)@.+$')
                if string.match(tmp, '%d+') == nil then
                    stage_num = tmp
                else
                    stage_num = 'St' .. string.match(tmp, '%d+')
                end
            end
            if diff == 'Spell Practice' then
                diff = 'SpellCard'
            end
            if tmp == 'Spell Practice' then
                stage_num = 'SC'
            end
            if slot.group_finish == 1 then
                stage_num = 'All'
            end
            info.exist = true
            info.user_name = slot.userName
            info.date = date
            info.player = slot.stages[1].stagePlayer
            info.diff = diff
            info.stage_num = stage_num
        else
            info.exist = false
            info.user_name = "--------"
            info.date = "----/--/--"
            info.player = "--------"
            info.diff = "--------"
            info.stage_num = "---"
        end
        table.insert(self.replay_info, info)
        local display_info = string.format("No.%02d  %8s  %8s  %8s  %8s  %3s",
            i, info.user_name, info.date, string.sub(info.player, 1, 8), string.sub(info.diff, 1, 8), info.stage_num)
        local item = menulib.item.simple_text_item(display_info, "menu_ttf_mono", Color(255, 255, 255, 255), Color(255, 255, 222, 89), function (self, menu) end)
        item.size = 0.8
        table.insert(self.itemlist, item)
    end
    menulib.utility.quick_layout(self.itemlist, 80, 430, 0, -25, {
        align = {"left", "vcenter"}
    })
end

function select_replay:set_replay_data(stages, finish)
    self.save_replay_data = {}
    self.save_replay_data.finish = finish or 0
    self.save_replay_data.stages = stages
end

function select_replay:set_mode(mode)
    assert(mode == "view" or mode == "save")
    self.mode = mode
end

function select_replay:frame()
    task.Do(self)
    self.controller:frame(get_keystate())
end

function select_replay:render()
    if self.render_active then
        SetImageState("white", "", Color(160 * (self.alpha / 255), 0, 0, 0))
        Render4V("white",
            60, 450, 0.5,
            580, 450, 0.5,
            580, 30, 0.5,
            60, 30, 0.5
        )
    end
    self.controller:render()
end

function select_replay:on_confirm()
    if self.mode == "view" then
        if self.replay_info[self.pos].exist then
            menulib.utility.se.play_confirm()
            local select_replay_stage_menu = self.menustack:get_menu("select_replay_stage")
            select_replay_stage_menu:refresh(self.pos)
            startup_info.replay_info = {}
            startup_info.replay_info.pos = self.pos
            default_fade_out(self)
            self.menustack:push_stack(self, default_fade_in)
            default_fade_in(select_replay_stage_menu)
        else
            menulib.utility.se.play_invalid()
        end
    else
        menulib.utility.se.play_confirm()
        local get_text_menu = self.menustack:get_menu("get_text")
        get_text_menu:set_callback(function (username)
            ext.replay.SaveReplay(self.save_replay_data.stages, self.pos, username, self.save_replay_data.finish)
            self:refresh_replay_slot(self.pos)
        end)
        get_text_menu:set_text("")
        get_text_menu:set_max_length(8)
        get_text_menu:set_special_input_mode(true)
        get_text_menu:set_default_result("User")
        default_fade_out(self)
        self.menustack:push_stack(self, default_fade_in)
        default_fade_in(get_text_menu)
    end
end

function select_replay:on_cancel()
    menulib.utility.se.play_cancel()
    default_fade_out(self)
    self.menustack:lastmenu_flyback()
end

local select_replay_stage = plus.Class(menulib.menu.base_menu)

function select_replay_stage:init(stack)
    self.menustack = stack
    self.itemlist = {}
    self.pos = 1
    self.controller = menulib.menucontroller.scroll_list.create(self, 'pos', 'itemlist', 'down', 'up', true,
        menulib.utility.se.play_select, 2, 2, 6, nil,
        {x_initial = 320, y_initial = 300, x_increment = 0, y_increment = -25}
    )
end

function select_replay_stage:refresh(slot_index)
    self.itemlist = {}
    self.pos = 1
    local slot = ext.replay.GetSlot(slot_index)
    self.replay_path = slot.path
    for i, v in ipairs(slot.stages) do
        local display_stagename = get_stage_display_name(v.stageName)
        local score = string.format("%012d", v.score)
        local display_info = string.format("%12s  %012d", display_stagename, score)
        local item = menulib.item.simple_scroll_list_text_item(display_info, "menu_ttf_mono", Color(255, 255, 255, 255), Color(255, 255, 222, 89), function (self, menu) end, 2)
        item.stage_name = v.stageName
        item.align = {"centerpoint"}
        table.insert(self.itemlist, item)
    end
end

function select_replay_stage:frame()
    task.Do(self)
    self.controller:frame(get_keystate())
end

function select_replay_stage:render()
    if self.render_active then
        SetImageState("white", "", Color(160 * (self.alpha / 255), 0, 0, 0))
        Render4V("white",
            160, 360, 0.5,
            480, 360, 0.5,
            480, 120, 0.5,
            160, 120, 0.5
        )
    end
    self.controller:render()
end

function select_replay_stage:on_confirm()
    menulib.utility.se.play_confirm()
    startup_info.replay_info.stage_name = self.itemlist[self.pos].stage_name
    startup_info.replay_info.replay_path = self.replay_path
    default_fade_out(self)
    New(mask_fader, 'close')
    task.New(self, function ()
        for i = 19, 0, -1 do
            SetBGMVolume('menu', i / 20)
            task.Wait(1)
        end
        start_game()
    end)
end

function select_replay_stage:on_cancel()
    menulib.utility.se.play_cancel()
    default_fade_out(self)
    self.menustack:lastmenu_flyback()
end

local get_text = plus.Class(menulib.menu.base_menu)

function get_text:init(stack)
    self.menustack = stack
    self.text = ""
    self.text_max_length = 8
    self.posX = 1
    self.posX_max = 13
    self.posY = 1
    self.posY_max = 8
    self.default_result = "User"
    self.itemlist = {}
    self.enable_special_input = false
    self.timer = 0
    local __0 = "\0"
    local __3 = "\3" --结束（确认）
    local _24 = "\24" --取消
    local __8 = "\8" --退格
    local _bs = "\\" --\
    local _sp = " "
    local keyboard = {
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ",", ".", "_",
        "+", "-", "*", "/", "=", "<", ">", "(", ")", "[", "]", "{", "}",
        "#", "$", "%", "&", "@", ":", ";", "!", "?", "^", "~", "`", "|",
        _bs, '"', "'", __0, __0, __0, __0, __0, __0, _sp, __8, _24, __3,
    }
    for _, char in ipairs(keyboard) do
        local item = {}
        item.char = char
        item.display_text = char
        item.t = 0
        item.on_confirm = function (_self, menu)
            menulib.utility.se.play_confirm()
            if #menu.text < self.text_max_length then
                menu.text = menu.text .. _self.char
            end
        end
        if char == __0 then
            item.display_text = ""
            item.on_confirm = function () end
        elseif char == _sp then
            item.display_text = "␣"
        elseif char == __8 then
            item.display_text = "←"
            item.on_confirm = function (_self, menu)
                menulib.utility.se.play_cancel()
                menu:backspace()
            end
        elseif char == _24 then
            item.display_text = "×"
            item.on_confirm = function (_self, menu)
                menulib.utility.se.play_cancel()
                menu:cancel_input()
            end
        elseif char == __3 then
            item.display_text = "✓"
            item.on_confirm = function (_self, menu)
                menulib.utility.se.play_confirm()
                menu:confirm_input()
            end
        end
        table.insert(self.itemlist, item)
    end
end

function get_text:backspace()
    if #self.text > 0 then
        self.text = string.sub(self.text, 1, -2)
    end
end

function get_text:cancel_input()
    default_fade_out(self)
    self.menustack:lastmenu_flyback()
end

function get_text:set_text(text)
    self.text = text or ""
end

function get_text:set_max_length(length)
    self.text_max_length = length or 8
end

function get_text:set_special_input_mode(allow)
    self.enable_special_input = allow
end

function get_text:set_default_result(res)
    self.default_result = res
end

function get_text:set_callback(callback)
    assert(type(callback) == "function")
    self.callback = callback
end

function get_text:confirm_input()
    if self.text == "" then
        self.text = self.default_result
    end
    if self.callback then
        self.callback(self.text)
    end
    self.text = ""
    self.callback = nil
    default_fade_out(self)
    self.menustack:lastmenu_flyback()
end

function get_text:frame()
    self.timer = self.timer + 1
    local k = (sin(self.timer * 2) + 1) / 2
    self.hintcolor = Color(255, 255, 255, 10) * k + Color(255, 255, 255, 255) * (1 - k)
    task.Do(self)
    -- self.controller:frame(get_keystate())
    local function get_index(posX, posY)
        return (posY - 1) * self.posX_max + posX
    end
    if self.input_active then
        local keystate = get_keystate()
        if keystate["up"] then
            menulib.utility.se.play_select()
            repeat
                self.posY = (self.posY - 1 - 1 + self.posY_max) % self.posY_max + 1
            until self.itemlist[get_index(self.posX, self.posY)].char ~= "\0"
        end
        if keystate["down"] then
            menulib.utility.se.play_select()
            repeat
                self.posY = (self.posY - 1 + 1 + self.posY_max) % self.posY_max + 1
            until self.itemlist[get_index(self.posX, self.posY)].char ~= "\0"
        end
        if keystate["left"] then
            menulib.utility.se.play_select()
            repeat
                self.posX = (self.posX - 1 - 1 + self.posX_max) % self.posX_max + 1
            until self.itemlist[get_index(self.posX, self.posY)].char ~= "\0"
        end
        if keystate["right"] then
            menulib.utility.se.play_select()
            repeat
                self.posX = (self.posX - 1 + 1 + self.posX_max) % self.posX_max + 1
            until self.itemlist[get_index(self.posX, self.posY)].char ~= "\0"
        end
        if keystate["shoot"] then
            self.itemlist[get_index(self.posX, self.posY)]:on_confirm(self)
            if #self.text == self.text_max_length then
                self.posX = self.posX_max
                self.posY = self.posY_max
            end
        end
        if keystate["spell"] then
            menulib.utility.se.play_cancel()
            if #self.text > 0 then
                self:backspace()
            else
                self:cancel_input()
            end
        end
        if keystate["special"] and self.enable_special_input then
            menulib.utility.se.play_confirm()
            self.text = string.sub(setting.username, 1, self.text_max_length)
            self.posX = self.posX_max
            self.posY = self.posY_max
        end
    end
    for index, item in ipairs(self.itemlist) do
        if index == get_index(self.posX, self.posY) then
            item.t = min(item.t + 3, 15)
        else
            item.t = max(item.t - 1, 0)
        end
    end
end

function get_text:render()
    local function get_index(posX, posY)
        return (posY - 1) * self.posX_max + posX
    end
    if self.render_active then
        SetImageState("white", "", Color(160 * (self.alpha / 255), 0, 0, 0))
        Render4V("white",
            110, 390, 0.5,
            530, 390, 0.5,
            530, 50, 0.5,
            110, 50, 0.5
        )
        for i = 1, self.posY_max do
            for j = 1, self.posX_max do
                local render_x, render_y = 320 + (j - 7) * 30, 320 - (i - 1) * 30
                local item = self.itemlist[get_index(j, i)]
                local k = item.t / 15
                local color = (Color(255, 255, 255, 255) * (1 - k) + Color(255, 255, 222, 89) * k) * Color(self.alpha, 255, 255, 255)
                RenderTTF2("menu_ttf", item.display_text, render_x, render_x, render_y, render_y, 1, color, "centerpoint")
            end
        end
        RenderTTF2("menu_ttf_mono", self.text, 320, 320, 360, 360, 1, Color(self.alpha, 255, 255, 255), "centerpoint")
        if self.enable_special_input then
            RenderTTF2("menu_ttf", "按下 SPECIAL 键填入LuaSTG设置中的用户名", 320, 320, 70, 70, 0.75, Color(self.alpha, 255, 255, 255) * self.hintcolor, "centerpoint")
        end
    end
end

local title_stack = plus.Class(menulib.menucontainer.base_menustack)
title.title_stack = title_stack

function title_stack:init(stage)
    self.super.init(self)
    local menus = {
        {"title_bg", title_bg},
        {"info_display", info_display},
        {"top_menu", top_menu},
        {"select_stage_group", select_stage_group},
        {"select_stage", select_stage},
        {"select_player", select_player},
        {"set_practice_properties", set_practice_properties},
        {"select_sc_practice_legacy", select_sc_practice_legacy},
        {"select_replay", select_replay},
        {"select_replay_stage", select_replay_stage},
        {"get_text", get_text}
    }
    local external_menus = menulib.external_menu_system.sort_menus_by_category("title")
    for _, info in ipairs(external_menus) do
        table.insert(menus, {info.name, info.menu_class})
    end
    self:create_menus(menus)
    if last_time_startup_info.mode == "replay" then
        --播放完replay后的跳转
        self:push_stack(self:get_menu("top_menu"), default_fade_in)
        self:get_menu("select_replay"):refresh_replay_slot(last_time_startup_info.replay_info.pos)
        self:get_menu("select_replay"):set_mode("view")
        self:push_stack(self:get_menu("select_replay"), default_fade_in)
        startup_info.mode = "replay"
    elseif last_time_startup_info.mode then
        --符卡练习后的跳转
        self:push_stack(self:get_menu("top_menu"), default_fade_in)
        if last_time_startup_info.mode == "sc_practice" then
            if last_time_startup_info.sc_practice_mode == "legacy" then
                self:get_menu("select_sc_practice_legacy"):set_index(last_time_startup_info.sc_index)
                startup_info.mode = "sc_practice"
                startup_info.sc_practice_mode = "legacy"
                self:push_stack(self:get_menu("select_sc_practice_legacy"), default_fade_in)
            elseif last_time_startup_info.sc_practice_mode == "weekend" then
                local select_sc_practice_weekend_menu_info = menulib.external_menu_system.get_menuinfo_by_index(select_sc_practice_weekend_menu_index)
                if select_sc_practice_weekend_menu_info then
                    local select_sc_practice_weekend_menu = self:get_menu(select_sc_practice_weekend_menu_info.name)
                    local entrance_function = select_sc_practice_weekend_menu_info.entrance_function
                    if select_sc_practice_weekend_menu.set_pos then
                        select_sc_practice_weekend_menu:set_pos(last_time_startup_info)
                    end
                    startup_info = {}
                    startup_info.mode = "sc_practice"
                    startup_info.sc_practice_mode = "weekend"
                    local select_player_menu = self:get_menu("select_player")
                    self:push_stack(select_sc_practice_weekend_menu, function (menu)
                        entrance_function(menu, startup_info, function ()
                            default_fade_in(select_player_menu)
                        end)
                    end)
                end
            end
        end
        --完成关卡后保存replay跳转
        if stage.save_replay then
            self:push_stack(self:get_menu("top_menu"), default_fade_in)
            self:get_menu("select_replay"):set_mode("save")
            self:get_menu("select_replay"):set_replay_data(stage.save_replay, stage.finish) --史
            self:push_stack(self:get_menu("select_replay"), default_fade_in)
        end
    else
        --啥也没有，直接进主菜单
        self:push_stack(self:get_menu("top_menu"), default_fade_in)
    end
    self:lastmenu_flyback()
    PlayMusic('menu')
    last_time_startup_info = {}
end

return title