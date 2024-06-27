local editor = {}
local circleRadius = 20
local spacing = (300 - (4 * circleRadius * 2)) / 5
local circleY = 768 - circleRadius - 40

local Sprites = {
    ["Bomb"] = "Images/bomb.png",
    ["PowerupBorder"] = "Images/PowerupBorder.png",
    ["Pause"] = "Images/Pause.png",
    ["Resume"] = "Images/Resume.png",
    ["MainMenu"] = "Images/MenuBg.png",
    ["PlayMenu"] = "Images/PlayMenu.png",
    ["ExitGame"] = "Images/ExitGame.png",
    ["FinishedOverlay"] = "Images/FinishedOverlay.png",
    ["ExitEndGameOverlay"] = "Images/ExitGameEndGameOverlay.png"
}

function editor.load()
    love.window.setMode(1024, 768)
    for name, spr in pairs(Sprites) do 
        Sprites[name] = love.graphics.newImage(spr)
    end
end

function editor.draw()
    for i = 1, 4 do 
        local circleX = spacing * i + circleRadius * (2 * i - 1) + 362
        love.graphics.circle("line", circleX, circleY, circleRadius)
    end
end

function editor.update()

end

function editor.mousepressed()

end

return editor