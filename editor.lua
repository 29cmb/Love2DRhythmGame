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
    ["PageDown"] = "Images/PageDown.png",
    ["Reset"] = "Images/ResetLevel.png",
    ["Save"] = "Images/Save.png"
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

local Powerups = {
    ["2xScore"] = {
        Duration = 5,
        Sprite = "Images/GoldenBeat.png",
        SpriteOffset = {x = 22, y = 30},
        Callback = function()
           
        end,
        Undo = function()
            
        end
    },
    ["Slow"] = {
        Duration = 5,
        Sprite = "Images/Slowness.png",
        SpriteOffset = {x = 22, y = 30},
        Callback = function()
            
        end,
        Undo = function()
            
        end
    }
}


local BeatMap = {}
local beats = {[1] = {}, [2] = {}, [3] = {}, [4] = {}}
local activeBeats = {}
local timePassed = 2.5
local getStartedHint = true

local Colors = {
    [1] = {255/255, 0, 0},
    [2] = {255/255, 150/255, 0},
    [3] = {255/255, 217/255, 0},
    [4] = {5/255, 255/255, 0}
}
local playtestMode = false
local page = 1
local editorMode = "none"

local function tableToString(tbl, indent)
    local result = "{\n"
    local nextIndent = indent .. "    "
    for k, v in pairs(tbl) do
        if type(k) == "string" then
            k = string.format("%q", k)
        end
        if type(v) == "string" then
            v = string.format("%q", v)
        elseif type(v) == "table" then
            v = tableToString(v, nextIndent)
        end
        result = result .. string.format("%s[%s] = %s,\n", nextIndent, k, v)
    end
    result = result .. indent .. "}"
    return result
end

function countFilesInDirectory(directory)
    local files = love.filesystem.getDirectoryItems(directory)
    local fileCount = 0

    for _, file in ipairs(files) do
        local filePath = directory .. "/" .. file
        if love.filesystem.getInfo(filePath, "file") then
            fileCount = fileCount + 1
        end
    end

    return fileCount
end

local fileName = nil
local holdingColumn = 0
local holdingBeatPosX = 0
local holdingBeatPosY = 0

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
            beats = {[1] = {}, [2] = {}, [3] = {}, [4] = {}}
            activeBeats = {}
            timePassed = 2.5
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
            if editorMode == "placing" then editorMode = "None" return end
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
            if editorMode == "placeBomb" then editorMode = "None" return end
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
            if editorMode == "placeGoldenBeat" then editorMode = "None" return end
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
            if editorMode == "delete" then editorMode = "None" return end
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
    },
    ["Exit"] = {
        ["x"] = 10,
        ["y"] = 10,
        ["scaleX"] = 168,
        ["scaleY"] = 67,
        ["condition"] = function()
            return true
        end,
        ["callback"] = function()
            require("main").InEditor = false
            love.window.setMode(300, 500)
        end
    },
    ["ResetLevel"] = {
        ["x"] = 285,
        ["y"] = 365,
        ["scaleX"] = 65,
        ["scaleY"] = 65,
        ["condition"] = function()
            return playtestMode == false
        end,
        ["callback"] = function()
            local confirmed = love.window.showMessageBox("Confirm?", "Are you sure you would like to erase this level?", {"Cancel", "Confirm"}, "info", true)
            if confirmed == 2 then 
                BeatMap = {}
            end
        end
    },
    ["Save"] = {
        ["x"] = 675,
        ["y"] = 150,
        ["scaleX"] = 65,
        ["scaleY"] = 65,
        ["condition"] = function()
            return playtestMode == false
        end,
        ["callback"] = function()
            love.filesystem.setIdentity("rhythm-game-levels")
            if fileName == nil then 
                fileName = "Level" .. (countFilesInDirectory("") - 3) .. ".lua" 
                love.filesystem.newFile(fileName)
            end
            
            love.filesystem.write(fileName, "return " .. tableToString(BeatMap, ""))
        end
    }
}


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

        if playtestMode == false then 
            for _,beat in pairs(BeatMap) do 
                if beat.Time >= ((page - 1) * 2.5) and beat.Time <= ((page) * 2.5) and table.find(beat.Beats, i) then
                    local posY = (460 - (circleRadius * 2)) - (168 * (beat.Time - ((page-1) * 2.5)))

                    if beat.Trail then
                        if beat.Hit == true then beat.PosY = circleY end
                        if beat.Trail > 0 then
                            love.graphics.setColor(Colors[i], 0.7)
                            love.graphics.rectangle("fill", circleX - 10, posY - circleRadius, circleRadius, -(beat.Trail * 60 * 3)) -- negative I guess?
                            love.graphics.circle("fill", circleX, posY - circleRadius - (beat.Trail * 60 * 3), circleRadius/2) -- curved corners
                            love.graphics.setColor(1, 1, 1)
                        end
                    end
    
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
        else
            for _,beat in pairs(beats[i]) do 
                if beat.Hit == false or ((beat.Trail and (beat.Trail.Held == false and beat.Trail.Holding == true or playtestMode == false))) then
                    if beat.Trail and beat.Trail.Time then
                        if beat.Hit == true then beat.PosY = circleY end
                        if beat.Trail.Time > 0 then
                            love.graphics.setColor(Colors[i], 0.7)
                            love.graphics.rectangle("fill", circleX - 10, beat.PosY - circleRadius, circleRadius, -(beat.Trail.Time * 60 * 3)) -- negative I guess?
                            love.graphics.circle("fill", circleX, beat.PosY - circleRadius - (beat.Trail.Time * 60 * 3), circleRadius/2) -- curved corners
                            love.graphics.setColor(1, 1, 1)
                        end
                    end
    
                    if beat.Hit == false then 
                        if beat.Powerup ~= "None" then
                            local powerup = Powerups[beat.Powerup]
                            love.graphics.draw(powerup.Sprite, circleX, beat.PosY, 0, 1, 1, powerup.SpriteOffset.x, powerup.SpriteOffset.y)
                        elseif beat.Bomb == false then
                            love.graphics.setColor(Colors[i])
                            love.graphics.circle("fill", circleX, beat.PosY, circleRadius)
                            love.graphics.setColor(0,0,0)
                            love.graphics.circle("line", circleX, beat.PosY, circleRadius)
                            love.graphics.setColor(1,1,1)
                        elseif beat.Bomb == true then
                            love.graphics.draw(Sprites.Bomb, circleX, beat.PosY, 0, 1, 1, 22, 30) -- why is the sprite off-center? No idea.
                        end
                    end
                    
                    
                    if beat.Hit == false then
                        beat.PosY = beat.PosY + 3
                    end

                    if love.keyboard.isDown(KeyCodes[i]) then 
                        local distance = math.abs(beat.PosY - circleY)
                        if distance <= (circleRadius * 2) and (beat.Hit == false or (beat.Trail and beat.Trail.Time)) then
                            beat.Hit = true
        
                            if beat.Trail and beat.Trail.Time and beat.Trail.Held == false then 
                                beat.Trail.Holding = true
                            end
                        end
                    end
                else
                    beats[i][beat] = nil
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
    if editorMode == "placing" then 
        love.graphics.setColor(0.8,0.8,0.8,0.5)
    end
    love.graphics.draw(Sprites.Outline, 285, 80)
    love.graphics.setColor(Colors[2])
    love.graphics.circle("fill", 318, 113, 15)
    love.graphics.setColor(1,1,1)

    -- Bomb placer
    if editorMode == "placeBomb" then 
        love.graphics.setColor(0.8,0.8,0.8,0.5)
    end
    love.graphics.draw(Sprites.Outline, 285, 150)
    love.graphics.push()
    love.graphics.scale(0.75, 0.75)
    love.graphics.draw(Sprites.Bomb, 400, 215)
    love.graphics.pop()

    love.graphics.setColor(1,1,1)

    -- 2x Points Placer
    if editorMode == "placeGoldenBeat" then 
        love.graphics.setColor(0.8,0.8,0.8,0.5)
    end
    love.graphics.draw(Sprites.Outline, 285, 220)
    love.graphics.push()
    love.graphics.scale(0.75, 0.75)
    love.graphics.draw(Sprites.GoldenBeat, 398, 310)
    love.graphics.pop()

    love.graphics.setColor(1,1,1)

    -- Beat remover
    if editorMode == "delete" then 
        love.graphics.setColor(0.8,0.8,0.8,0.5)
    end

    love.graphics.draw(Sprites.DeleteBeat, 285, 290)
    love.graphics.setColor(1,1,1)
    -- page up
    love.graphics.draw(Sprites.PageUp, 675, 10)
    -- page down
    love.graphics.draw(Sprites.PageDown, 675, 80)
    love.graphics.push()
    love.graphics.setFont(Fonts.Headers)
    love.graphics.print("Page " .. page, 750, 50)
    love.graphics.pop()

    -- reset level
    love.graphics.draw(Sprites.Reset, 285, 360)

    -- exit
    love.graphics.draw(Sprites.ExitGame, 10, 10)

    -- save
    love.graphics.draw(Sprites.Save, 675, 150)

    if getStartedHint then
        love.graphics.setFont(Fonts.Score)
        love.graphics.printf("Drag a file or place a beat to get started!", 700, 300, 200)
    end

    if playtestMode == true then 
        for _,beatData in pairs(BeatMap) do
            if not table.find(activeBeats, beatData) then 
                if beatData.Time <= 2.5 then
                    table.insert(activeBeats, beatData)
                    for _,beat in pairs(beatData.Beats) do
                        table.insert(beats[beat], {
                            ["PosY"] = (460 - (circleRadius * 2)) - (168 * beatData.Time),
                            ["Hit"] = false,
                            ["SpeedMod"] = 1,
                            ["Bomb"] = beatData.Bomb or false,
                            ["Powerup"] = beatData.Powerup or "None",
                            ["Trail"] = {
                                ["Time"] = beatData.Trail or nil, 
                                ["Held"] = false,
                                ["Holding"] = false
                            },
                        })
                    end
                else
                    if beatData.Time <= timePassed then 
                        table.insert(activeBeats, beatData)
                        for _,beat in pairs(beatData.Beats) do
                            table.insert(beats[beat], {
                                ["PosY"] = -5,
                                ["Hit"] = false,
                                ["SpeedMod"] = 1,
                                ["Bomb"] = beatData.Bomb or false,
                                ["Powerup"] = beatData.Powerup or "None",
                                ["Trail"] = {
                                    ["Time"] = beatData.Trail or nil, 
                                    ["Held"] = false,
                                    ["Holding"] = false
                                },
                            })
                        end
                    end
                end 
            end 
        end
    end
end

function editor.update(dt)
    if playtestMode == true then 
        timePassed = timePassed + dt

        for i = 1, 4 do 
            for _,beat in pairs(beats[i]) do 
                if beat.Trail and beat.Trail.Time then
                    if beat.Trail.Holding == true then
                        beat.Trail.Time = beat.Trail.Time - dt
                    end
                end
            end
        end
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

    if collided == false and editorMode ~= "none" and playtestMode == false then -- only do editor modes if the user did not press a button
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

        getStartedHint = false

        holdingColumn = boundary
        holdingBeatPosX = x
        holdingBeatPosY = y

        if editorMode == "placing" then
            holding = true
            local beatData = getBeatDataFromTime(math.round(time, 1))
            if beatData then
                if not table.find(beatData.Beats, boundary) and beatData.Bomb ~= true then
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
                if beats.Time >= time - 0.2 and beats.Time <= time + 0.2 then 
                    for i2, beat in pairs(beats.Beats) do 
                        if beat == boundary then
                            table.remove(BeatMap[i].Beats, i2)
                            break
                        end
                    end
                end
            end
        end
    end
end

function editor.mousemoved(x, y)
    if playtestMode == false and holdingColumn ~= 0 and holdingBeatPosY ~= 0 and holdingBeatPosX ~= 0 and holding == true then
        local time = math.round(((((460 - (circleRadius * 2)) - holdingBeatPosY)/(460 - (circleRadius * 2))) * 2.5) + ((page-1) * 2.5), 1)
        if y + 80 < holdingBeatPosY then 
            for index, data in pairs(BeatMap) do
                if data.Time == time and table.find(data.Beats, holdingColumn) then
                    local trailTime = math.round(((((460 - (circleRadius * 2)) - y)/(460 - (circleRadius * 2))) * 2.5) + ((page-1) * 2.5), 1)
                    BeatMap[index].Trail = (trailTime - 0.15) - time

                    return
                end
            end
        else
            for index, data in pairs(BeatMap) do
                if data.Time == time and table.find(data.Beats, holdingColumn) then 
                    BeatMap[index].Trail = nil
                    return
                end
            end
        end
    end
end

function editor.mousereleased(x, y, button)
    holding = false
    if holdingColumn ~= 0 and holdingBeatPosY ~= 0 and holdingBeatPosX ~= 0 and playtestMode == false then 
        if y + 80 < holdingBeatPosY then 
            print("Higher")
        end

        holdingColumn = 0
        holdingBeatPosY = 0
        holdingBeatPosX = 0
    else
        print(holdingColumn, holdingBeatPosX, holdingBeatPosY, playtestMode)
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

function editor.fileLoaded(file)
    file:open("r")
    local data = load(file:read())()
    BeatMap = data

    love.window.showMessageBox("Success", "Level '" .. file:getFilename() .. "' loaded successfully")
end

return editor