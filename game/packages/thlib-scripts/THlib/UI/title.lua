local stage_init = stage.New('init', true, true)
function stage_init:init()
end
function stage_init:frame()
    stage.Set('menu', 'none')
end
function stage_init:render()
end

local stage_quit = stage.New("stage.quit", false, true)
function stage_quit:init()
    -- 添加一个单独的关卡，退出游戏时会切换到这个关卡
    -- 这是为了触发切换关卡时自动存档
    stage.QuitGame()
end
function stage_quit:render()
end

MusicRecord("menu", 'THlib/music/luastg 0.08.540 - 1.27.800.ogg', 87.8, 79.26)
MusicRecord("spellcard", 'THlib/music/spellcard.ogg', 75, 0xc36e80 / 44100 / 4)

local menu_dev_tool = require("vulpine_ui_v0.dev_utils.menu_dev_tool")

stage_menu = stage.New('menu', false, true)

function stage_menu:init()
    self.menucontainer = menu_dev_tool.container()
end

function stage_menu:frame()
    self.menucontainer:frame()
end

function stage_menu:render()
    self.menucontainer:render()
end
