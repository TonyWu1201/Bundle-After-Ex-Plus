local title = require("foundation.menu.titlemenu")

local stage_init = stage.New('init', true, true)
function stage_init:init()
    --加载资源
    stage.preserve_res = true
end
function stage_init:frame()
    if true then --以后做（伪）异步加载可以写具体的判断
        stage.Set('menu', 'none')
    end
end
function stage_init:render()
    --还写一点动画啥的
end

local stage_quit = stage.New("stage.quit", false, true)
function stage_quit:init()
    -- 添加一个单独的关卡，退出游戏时会切换到这个关卡
    -- 这是为了触发切换关卡时自动存档
    stage.QuitGame()
end
function stage_quit:render()
end

local title_menu = stage.New("menu", false, true)

function title_menu:init()
    title.load_resources()
    self.stack = title.title_stack(self)
end

function title_menu:frame()
    self.stack:frame()
end

function title_menu:render()
    self.stack:render()
end