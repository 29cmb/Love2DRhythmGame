local editor = {}
local circleRadius = 20
local spacing = (300 - (4 * circleRadius * 2)) / 5
local circleY = 500 - circleRadius - 40

local collision = require("collision")

local Sprites = {
    ["Bomb"] = "Images/bomb.png",
    ["PowerupBorder"] = "Images/PowerupBorder.png",
    ["GoldenBeat"] = "Images/GoldenBeat.png",
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

local Fonts = {
    ["Headers"] = {"Fonts/SF Archery Black.ttf", 40},
    ["Score"] = {"Fonts/good times rg.otf", 25}
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
    ["PlaceBomb"] = {
        ["x"] = 285,
        ["y"] = 150,
        ["scaleX"] = 65,
        ["scaleY"] = 65,
        ["condition"] = function()
            return playtestMode == false
        end,
        ["callback"] = function()
            editorMode = "placeBomb"
        end
    },
    ["PlaceGoldenBeat"] = {
        ["x"] = 285,
        ["y"] = 220,
        ["scaleX"] = 65,
        ["scaleY"] = 65,
        ["condition"] = function()
            return playtestMode == false
        end,
        ["callback"] = function()
            editorMode = "placeGoldenBeat"
        end
    },
    ["DeleteBeat"] = {
        ["x"] = 285,
        ["y"] = 290,
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

local Powerups = {
    ["2xScore"] = {
        Duration = 5,
        Sprite = "Images/GoldenBeat.png",
        SpriteOffset = {x = 22, y = 30},
        Callback = function()
            self.ScoreMultiplier = 2
        end,
        Undo = function()
            self.ScoreMultiplier = 1
        end
    },
    ["Slow"] = {
        Duration = 5,
        Sprite = "Images/Slowness.png",
        SpriteOffset = {x = 22, y = 30},
        Callback = function()
            self.Speed = self.Speed * 0.75
            self.ActiveAudio:setPitch(.75)
        end,
        Undo = function()
            self.Speed = self.Speed * 1.25
            self.ActiveAudio:setPitch(1)
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

    for name,font in pairs(Fonts) do 
        Fonts[name] = love.graphics.newFont(font[1], font[2])
    end

    for _, data in pairs(Powerups) do 
        data.Sprite = love.graphics.newImage(data.Sprite)
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

        for _,beat in pairs(BeatMap) do 
            if beat.Time >= ((page - 1) * 2.5) and beat.Time <= ((page) * 2.5) and table.find(beat.Beats, i) then
                local posY = (460 - (circleRadius * 2)) - (168 * (beat.Time - ((page-1) * 2.5)))

                if beat.Bomb and beat.Bomb == true then 
                    love.graphics.draw(Sprites.Bomb, circleX, posY, 0, 1, 1, 22, 30) -- why is the sprite off-center? No idea.
                elseif beat.Powerup then
                    local powerup = Powerups[beat.Powerup]
                    love.graphics.draw(powerup.Sprite, circleX, posY, 0, 1, 1, powerup.SpriteOffset.x, powerup.SpriteOffset.y)
                else
                    love.graphics.setColor(Colors[i])
                    love.graphics.circle("fill", circleX, posY, circleRadius)
                    love.graphics.setColor(0,0,0)
                    love.graphics.circle("line", circleX, posY, circleRadius)
                    love.graphics.setColor(1,1,1)
                end
            end
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

    -- Bomb placer
    love.graphics.draw(Sprites.Outline, 285, 150)
    love.graphics.push()
    love.graphics.scale(0.75, 0.75)
    love.graphics.draw(Sprites.Bomb, 400, 215)
    love.graphics.pop()

    -- 2x Points Placer
    love.graphics.draw(Sprites.Outline, 285, 220)
    love.graphics.push()
    love.graphics.scale(0.75, 0.75)
    love.graphics.draw(Sprites.GoldenBeat, 398, 310)
    love.graphics.pop()
    -- Beat remover
    love.graphics.draw(Sprites.DeleteBeat, 285, 290)

    -- page up
    love.graphics.draw(Sprites.PageUp, 675, 10)
    -- page down
    love.graphics.draw(Sprites.PageDown, 675, 80)
    love.graphics.push()
    love.graphics.setFont(Fonts.Headers)
    love.graphics.print("Page " .. page, 750, 50)
    love.graphics.pop()
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

    if collided == false and editorMode ~= "none" then -- only do editor modes if the user did not press a button
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

        if editorMode == "placing" then 
            local beatData = getBeatDataFromTime(math.round(time, 1))
            if beatData then 
                if not table.find(beatData.Beats, boundary) and beatData.Bomb == false then
                    table.insert(beatData.Beats, boundary)
                end
            else
                table.insert(BeatMap, {
                    ["Time"] = math.round(time, 1),
                    ["Beats"] = {
                        boundary
                    }
                })
            end
        elseif editorMode == "placeBomb" then
            local beatData = getBeatDataFromTime(math.round(time, 1))
            if beatData then 
                if not table.find(beatData.Beats, boundary) and beatData.Bomb == true then
                    table.insert(beatData.Beats, boundary)
                end
            else
                table.insert(BeatMap, {
                    ["Time"] = math.round(time, 1),
                    ["Beats"] = {
                        boundary
                    },
                    ["Bomb"] = true
                })
            end
        elseif editorMode == "placeGoldenBeat" then
            local beatData = getBeatDataFromTime(math.round(time, 1))
            if beatData then 
                if not table.find(beatData.Beats, boundary) and beatData.Powerup == "2xScore" then
                    table.insert(beatData.Beats, boundary)
                end
            else
                table.insert(BeatMap, {
                    ["Time"] = math.round(time, 1),
                    ["Beats"] = {
                        boundary
                    },
                    ["Powerup"] = "2xScore"
                })
            end
        elseif editorMode == "delete" then 
            for i,beats in pairs(BeatMap) do 
                if beats.Time <= time + 0.2 or beats.Time >= time - 0.2 then 
                    for i2, beat in pairs(beats.Beats) do 
                        if beat == boundary then 
                            table.remove(BeatMap[i].Beats, i2)
                            break
                        end
                    end
                end
            end
        else
            print("Editor mode is " .. editorMode)
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