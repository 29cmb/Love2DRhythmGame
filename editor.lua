local editor = {}
local circleRadius = 20
local spacing = (300 - (4 * circleRadius * 2)) / 5
local circleY = 500 - circleRadius - 40

local collision = require("collision")

local Sprites = {
    ["Bomb"] = "Images/bomb.png",
    ["PowerupBorder"] = "Images/PowerupBorder.png",
    ["Pause"] = "Images/Pause.png",
    ["Resume"] = "Images/Resume.png",
    ["ExitGame"] = "Images/ExitGame.png",
    ["FinishedOverlay"] = "Images/FinishedOverlay.png",
    ["ExitEndGameOverlay"] = "Images/ExitGameEndGameOverlay.png",
    ["Background"] = "Images/Background.png",
    ["Outline"] = "Images/ButtonOutline.png",
    ["DeleteBeat"] = "Images/DeleteBeat.png",
    ["PageUp"] = "Images/PageUp.png",
    ["PageDown"] = "Images/PageDown.png"
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
local page = 1

local editorMode = "none"

local buttons = {
    ['Playtest'] = {
        ["x"] = 285,
        ["y"] = 10,
        ["scaleX"] = 65,
        ["scaleY"] = 65,
        ["condition"] = function()
            return true
        end,
        ["callback"] = function()
            playtestMode = not playtestMode
        end
    },
    ["PlaceBeat"] = {
        ["x"] = 285,
        ["y"] = 80,
        ["scaleX"] = 65,
        ["scaleY"] = 65,
        ["condition"] = function()
            return playtestMode == false
        end,
        ["callback"] = function()
            editorMode = "placing"
        end
    },
    ["DeleteBeat"] = {
        ["x"] = 285,
        ["y"] = 150,
        ["scaleX"] = 65,
        ["scaleY"] = 65,
        ["condition"] = function()
            return playtestMode == false
        end,
        ["callback"] = function()
            editorMode = "delete"
        end
    },
    ["PageUp"] = {
        ["x"] = 675,
        ["y"] = 10,
        ["scaleX"] = 65,
        ["scaleY"] = 65,
        ["condition"] = function()
            return playtestMode == false
        end,
        ["callback"] = function()
            page = page + 1
        end
    },
    ["PageDown"] = {
        ["x"] = 675,
        ["y"] = 80,
        ["scaleX"] = 65,
        ["scaleY"] = 65,
        ["condition"] = function()
            return playtestMode == false
        end,
        ["callback"] = function()
            if page <= 1 then return end
            page = page - 1
        end
    }
}

local BeatMap = {}

function getBeatDataFromTime(time)
    for _,data in pairs(BeatMap) do 
        if data.Time == time then
            return data
        end
    end

    return false
end

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

        if i ~= 4 then 
            love.graphics.line(spacing * (i + 0.5) + circleRadius * (2 * (i + 0.5) - 1) + 362.5, 0, spacing * (i + 0.5) + circleRadius * (2 * (i + 0.5) - 1) + 362.5, 500)
        end
    end

    love.graphics.line((spacing + circleRadius + 314), 0, (spacing + circleRadius + 314), 768)
    love.graphics.line((spacing * 5 + circleRadius * (2 * 5 - 1)) + 343.5, 0, spacing * 5 + circleRadius * (2 * 5 - 1) + 343.5, 768)

    -- playtest button
    if playtestMode == true then 
        love.graphics.draw(Sprites.Pause, 285, 10)
    else
        love.graphics.draw(Sprites.Resume, 285, 10)
    end

    -- Beat placer
    love.graphics.draw(Sprites.Outline, 285, 80)
    love.graphics.setColor(Colors[2])
    love.graphics.circle("fill", 318, 113, 15)
    love.graphics.setColor(1,1,1)

    -- Beat remover
    love.graphics.draw(Sprites.DeleteBeat, 285, 150)

    -- page up
    love.graphics.draw(Sprites.PageUp, 675, 10)
    -- page down
    love.graphics.draw(Sprites.PageDown, 675, 80)
end

function editor.update(dt)
    if love.keyboard.isDown("k") then 
        playtestMode = true
    end
end

local placementSpacing = {
    [1] = {(spacing + circleRadius + 314), spacing * (1 + 0.5) + circleRadius * (2 * (1 + 0.5) - 1) + 362.5},
    [2] = {spacing * (1 + 0.5) + circleRadius * (2 * (1 + 0.5) - 1) + 362.5, spacing * (2 + 0.5) + circleRadius * (2 * (2 + 0.5) - 1) + 362.5},
    [3] = {spacing * (2 + 0.5) + circleRadius * (2 * (2 + 0.5) - 1) + 362.5, spacing * (3 + 0.5) + circleRadius * (2 * (3 + 0.5) - 1) + 362.5},
    [4] = {spacing * (3 + 0.5) + circleRadius * (2 * (3 + 0.5) - 1) + 362.5, (spacing * 5 + circleRadius * (2 * 5 - 1)) + 343.5}
}

function editor.mousepressed(x,y,button)
    local collided = false
    for _,button in pairs(buttons) do 
        if collision:CheckCollision(x, y, 1, 1, button.x, button.y, button.scaleX, button.scaleY) and button.condition() == true then 
            button.callback()
            collided = true
        end
    end

    if collided == false then -- only do editor modes if the user did not press a button
        if editorMode == "placing" then 
            local time = ((((460 - (circleRadius * 2)) - y)/(460 - (circleRadius * 2))) * 2.5) + ((page-1) * 2.5)
            if time <= 0 then return end

            local boundary = 0

            if x > (spacing + circleRadius + 314) and x < (spacing * 5 + circleRadius * (2 * 5 - 1)) + 343.5 then 
                for index, v in pairs(placementSpacing) do 
                    if x > v[1] and x < v[2] then 
                        boundary = index
                    end
                end
            end

            if boundary == 0 then return end

            local beatData = getBeatDataFromTime(math.round(time, 2))
            if beatData then 
                if not table.find(beatData.Beats, boundary) then
                    table.insert(beatData.Beats, boundary)
                end
            else
                table.insert(BeatMap, {
                    ["Time"] = math.round(time, 2),
                    ["Beats"] = {
                        boundary
                    }
                })
            end
        end
    end
end

function table.find(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function math.round(num, decimalPlaces)
    local mult = 10^decimalPlaces
    return math.floor(num * mult + 0.5) / mult
end

return editor