local editor = {}
local circleRadius = 20
local spacing = (300 - (4 * circleRadius * 2)) / 5
local circleY = 500 - circleRadius - 40

local Sprites = {
    ["Bomb"] = "Images/bomb.png",
    ["PowerupBorder"] = "Images/PowerupBorder.png",
    ["Pause"] = "Images/Pause.png",
    ["Resume"] = "Images/Resume.png",
    ["MainMenu"] = "Images/MenuBg.png",
    ["PlayMenu"] = "Images/PlayMenu.png",
    ["ExitGame"] = "Images/ExitGame.png",
    ["FinishedOverlay"] = "Images/FinishedOverlay.png",
    ["ExitEndGameOverlay"] = "Images/ExitGameEndGameOverlay.png",
    ["Background"] = "Images/Background.png"
}

local KeyCodes = {
    [1] = "a",
    [2] = "s",
    [3] = "d",
    [4] = "f"
}

local Colors = {
    [1] = {255/255, 0, 0},
    [2] = {255/255, 150/255, 0},
    [3] = {255/255, 217/255, 0},
    [4] = {5/255, 255/255, 0}
}


local playtestMode = false

function editor.load()
    love.window.setMode(1024, 500)
    for name, spr in pairs(Sprites) do 
        Sprites[name] = love.graphics.newImage(spr)
    end
end

function editor.draw()

    love.graphics.draw(Sprites.Background, 363, 0)

    for i = 1, 4 do 
        local circleX = spacing * i + circleRadius * (2 * i - 1) + 362.5
        
        if love.keyboard.isDown(KeyCodes[i]) and playtestMode == true then 
            love.graphics.setColor(Colors[i])
            love.graphics.circle("fill", circleX, circleY, circleRadius)
            love.graphics.setColor(0,0,0)
            love.graphics.circle("line", circleX, circleY, circleRadius)
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.circle("line", circleX, circleY, circleRadius)
        end
    end

    love.graphics.line((spacing + circleRadius + 314), 0, (spacing + circleRadius + 320.5), 768)
    love.graphics.line((spacing * 5 + circleRadius * (2 * 5 - 1)) + 346, 0, spacing * 5 + circleRadius * (2 * 5 - 1) + 338.5, 768)
end

function editor.update(dt)
    if love.keyboard.isDown("k") then 
        playtestMode = true
    end
end

function editor.mousepressed(x,y,button)

end

return editor