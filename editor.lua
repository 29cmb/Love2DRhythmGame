local editor = {}
local circleRadius = 20
local spacing = (300 - (4 * circleRadius * 2)) / 5
local circleY = 500 - circleRadius - 40

local utils = require("modules.utils")
local Sprites = require("modules.sprites")
local Fonts = require("modules.fonts")
local misc = require("modules.misc")

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


local BeatMap = {
    ["Data"] = {
        ["Song"] = "DELTA",
        ["BackgroundImage"] = "Images/Background.png" -- no variability yet
    },
    ["Beats"] = {}
}

local beats = {[1] = {}, [2] = {}, [3] = {}, [4] = {}}
local activeBeats = {}
local timePassed = 2.5
local getStartedHint = true
local playtestMode = false
local recording = false
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
local musicSelectorItems = {}
local musicSelectorPage = 1
local musicSelectorOpen = false

local ActiveSong = nil

function playtest(o)
    playtestMode = o or not playtestMode
    beats = {[1] = {}, [2] = {}, [3] = {}, [4] = {}}
    activeBeats = {}
    timePassed = 2.5

    if playtestMode == true then 
        local audio = love.audio.newSource("Songs/" .. musicSelectorItems[musicSelectorPage].SongName .. "/Music.mp3", "stream")
        audio:setVolume(1) 
        audio:play()

        ActiveAudio = audio
    else
        if ActiveAudio then 
            ActiveAudio:stop()
            ActiveAudio = nil
        end
        recording = false
    end
end

local buttons = {
    ['Playtest'] = {
        ["x"] = 285,
        ["y"] = 10,
        ["scaleX"] = 65,
        ["scaleY"] = 65,
        ["condition"] = function()
            return true
        end,
        ["callback"] = playtest
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
    ["PlaceIce"] = {
        ["x"] = 285,
        ["y"] = 290,
        ["scaleX"] = 65,
        ["scaleY"] = 65,
        ["condition"] = function() 
            return playtestMode == false 
        end,
        ["callback"] = function()
            if editorMode == "placeIce" then editorMode = "None" return end
            editorMode = "placeIce"
        end
    },
    ["DeleteBeat"] = {
        ["x"] = 285,
        ["y"] = 350,
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
            return playtestMode == false
        end,
        ["callback"] = function()
            BeatMap = {
                ["Data"] = {
                    ["Song"] = "On and On",
                    ["BackgroundImage"] = "Images/Background.png" -- no variability yet
                },
                ["Beats"] = {}
            }

            fileName = nil
            holdingColumn = 0
            holdingBeatPosX = 0
            holdingBeatPosY = 0
            musicSelectorItems = {}
            musicSelectorPage = 1
            musicSelectorOpen = false
            page = 1

            ActiveSong = nil

            local main = require('main')

            main.InEditor = false
            main.endGame()

            love.window.setMode(300, 500)
        end
    },
    ["ResetLevel"] = {
        ["x"] = 285,
        ["y"] = 430,
        ["scaleX"] = 65,
        ["scaleY"] = 65,
        ["condition"] = function()
            return playtestMode == false
        end,
        ["callback"] = function()
            local confirmed = love.window.showMessageBox("Confirm?", "Are you sure you would like to erase this level?", {"Cancel", "Confirm"}, "info", true)
            if confirmed == 2 then 
                BeatMap.Beats = {}
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
                fileName = "Level" .. (countFilesInDirectory("") - 3) .. ".rhythm" 
                love.filesystem.newFile(fileName)
            end

            local highestTime = 0
            local foundEndCard = false

            for i,beat in pairs(BeatMap.Beats) do
                if beat.Time > highestTime then
                    highestTime = beat.Time
                end

                if beat.End == true then 
                    foundEndCard = true
                    break
                end
            end

            if foundEndCard == false then 
                table.insert(BeatMap.Beats, {
                    ["Time"] = highestTime + 4.5, -- 2.5 for the beat to reach the bottom of the screen and 2 for clarity
                    ["Beats"] = {},
                    ["End"] = true
                })
            end
            
            love.filesystem.write(fileName, "return " .. tableToString(BeatMap, ""))
            love.window.showMessageBox("Saved", "Save was successful!")
        end
    },
    ["MusicSelector"] = {
        ["x"] = 675,
        ["y"] = 220,
        ["scaleX"] = 65,
        ["scaleY"] = 65,
        ["condition"] = function()
            return playtestMode == false
        end,
        ["callback"] = function()
            musicSelectorOpen = not musicSelectorOpen
        end
    },
    ["LargeButtonLeft"] = {
        ["x"] = 675,
        ["y"] = 300,
        ["scaleX"] = 48,
        ["scaleY"] = 128,
        ["condition"] = function()
            return musicSelectorOpen == true and playtestMode == false
        end,
        ["callback"] = function()
            if musicSelectorPage > 1 then
                musicSelectorPage = musicSelectorPage - 1
                BeatMap.Data.Song = musicSelectorItems[musicSelectorPage].SongName
            else
                musicSelectorPage = #musicSelectorItems
            end
        end
    },
    ["LargeButtonRight"] = {
        ["x"] = 972.5,
        ["y"] = 300,
        ["scaleX"] = 48,
        ["scaleY"] = 128,
        ["condition"] = function()
            return musicSelectorOpen == true and playtestMode == false
        end,
        ["callback"] = function()
            if musicSelectorItems[musicSelectorPage + 1] ~= nil then 
                musicSelectorPage = musicSelectorPage + 1
            else
                musicSelectorPage = 1
            end
            
            BeatMap.Data.Song = musicSelectorItems[musicSelectorPage].SongName
        end
    },
    ["Record"] = {
        ["x"] = 675,
        ["y"] = 290,
        ["scaleX"] = 65,
        ["scaleY"] = 65,
        ["condition"] = function()
            return musicSelectorOpen == false and playtestMode == false
        end,
        ["callback"] = function()
            -- later
            playtest(true)
            recording = true
        end
    }
}

local holdingKeys = {}

function getBeatDataFromTime(time)
    for _,data in pairs(BeatMap.Beats) do 
        if data.Time == time then
            return data
        end
    end

    return false
end

function editor.load()
    love.window.setMode(1024, 500)

    for _, data in pairs(Powerups) do 
        data.Sprite = love.graphics.newImage(data.Sprite)
    end
end



function editor.draw()
    love.graphics.draw(Sprites.Background, 363, 0)
    if getStartedHint then
        love.graphics.setFont(Fonts.Score)
        love.graphics.printf("Drag a file or place a beat to get started!", 800, 360, 200)
    end
    musicSelectorItems = {}
    if recording == true then 
        love.graphics.print("Recording...", 430, 40)
    end
    for _,song in pairs(love.filesystem.getDirectoryItems("/Songs")) do 
        local songData = require("Songs." .. tostring(song) .. ".data")
        table.insert(musicSelectorItems, songData)
    end

    if musicSelectorOpen == true then 
        love.graphics.rectangle("fill", 725, 300, 245, 130)
        

        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(Fonts.SmallScore)
        love.graphics.printf(musicSelectorItems[musicSelectorPage].SongName, 740, 310, 200)
        love.graphics.push()
        love.graphics.scale(0.8)
        love.graphics.printf(musicSelectorItems[musicSelectorPage].Artist, 925, 410, 300)
        love.graphics.pop()
        love.graphics.printf("Page " .. musicSelectorPage .. "/" .. #musicSelectorItems, 760, 400, 200, "right")
        love.graphics.setColor(1, 1, 1, 1)

        love.graphics.draw(Sprites.LeftLargeButton, 675, 300)
        love.graphics.draw(Sprites.RightLargeButton, 972.5, 300)
    end

    for i = 1, 4 do 
        local circleX = spacing * i + circleRadius * (2 * i - 1) + 362.5
        
        if love.keyboard.isDown(misc.KeyCodes[i]) and playtestMode == true then 
            love.graphics.setColor(misc.Colors[i])
            love.graphics.circle("fill", circleX, circleY, circleRadius)
            love.graphics.setColor(0,0,0)
            love.graphics.circle("line", circleX, circleY, circleRadius)
            love.graphics.setColor(1, 1, 1)
            if recording == true then
                local found = false
                for key, time in pairs(holdingKeys) do 
                    if key == misc.KeyCodes[i] and time ~= nil then 
                        found = true
                    end
                end

                if found == false then
                    holdingKeys[misc.KeyCodes[i]] = {0,timePassed}
                    local fromTime = getBeatDataFromTime(timePassed)
                    if not fromTime then
                        table.insert(BeatMap.Beats, {
                            ["Time"] = timePassed - 2.5,
                            ["Beats"] = {
                                i
                            }
                        })
                    else
                        if not utils.find(fromTime.Beats, i) then 
                            table.insert(fromTime.Beats, i)
                        end
                    end
                elseif holdingKeys[misc.KeyCodes[i]][1] > 0.6 then
                    for _,v in pairs(BeatMap.Beats) do 
                        if v.Time == (holdingKeys[misc.KeyCodes[i]][2] - 2.5) then 
                            v.Trail = timePassed - holdingKeys[misc.KeyCodes[i]][2]
                        end
                    end
                end
            end
        else
            love.graphics.circle("line", circleX, circleY, circleRadius)
            for _,beat in pairs(beats[i]) do
                if beat.Hit and beat.Trail and beat.Trail.Time then 
                    if beat.Trail.Holding == true then 
                        beat.Trail.Held = true
                        beat.Trail.Holding = false
                    end
                end
            end
        end

        if i ~= 4 then 
            love.graphics.line(spacing * (i + 0.5) + circleRadius * (2 * (i + 0.5) - 1) + 362.5, 0, spacing * (i + 0.5) + circleRadius * (2 * (i + 0.5) - 1) + 362.5, 500)
        end

        if playtestMode == false then 
            for _,beat in pairs(BeatMap.Beats) do 
                if beat.Time >= ((page - 1) * 2.5) and beat.Time <= ((page) * 2.5) and utils.find(beat.Beats, i) then
                    local posY = (460 - (circleRadius * 2)) - (168 * (beat.Time - ((page-1) * 2.5)))

                    if beat.Trail then
                        if beat.Hit == true then beat.PosY = circleY end
                        if beat.Trail > 0 then
                            love.graphics.setColor(misc.Colors[i], 0.7)
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
                        love.graphics.setColor(misc.Colors[i])
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
                            love.graphics.setColor(misc.Colors[i], 0.7)
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
                            love.graphics.setColor(misc.Colors[i])
                            love.graphics.circle("fill", circleX, beat.PosY, circleRadius)
                            love.graphics.setColor(0,0,0)
                            love.graphics.circle("line", circleX, beat.PosY, circleRadius)
                            love.graphics.setColor(1,1,1)
                        elseif beat.Bomb == true then
                            love.graphics.draw(Sprites.Bomb, circleX, beat.PosY, 0, 1, 1, 22, 30) -- why is the sprite off-center? No idea.
                        end
                    end
                    
                    
                    -- if beat.Hit == false then
                    --     beat.PosY = beat.PosY + 3
                    -- end

                    if love.keyboard.isDown(misc.KeyCodes[i]) then 
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
    love.graphics.setColor(misc.Colors[2])
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

    -- ice-cube placer
    if editorMode == "placeIce" then 
        love.graphics.setColor(0.8,0.8,0.8,0.5)
    end
    love.graphics.draw(Sprites.Outline, 285, 290)
    love.graphics.push()
    love.graphics.scale(0.75, 0.75)
    love.graphics.draw(Sprites.Slowness, 398, 402.5)
    love.graphics.pop()

    love.graphics.setColor(1,1,1)

    -- Beat remover
    if editorMode == "delete" then 
        love.graphics.setColor(0.8,0.8,0.8,0.5)
    end

    love.graphics.draw(Sprites.DeleteBeat, 285, 360)
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
    love.graphics.draw(Sprites.Reset, 285, 430)

    -- exit
    love.graphics.draw(Sprites.ExitGame, 10, 10)

    -- save
    love.graphics.draw(Sprites.Save, 675, 150)
    love.graphics.print(fileName or "Unsaved", 750, 160)

    -- music selector
    love.graphics.draw(Sprites.Music, 675, 220)

    -- record
    if not musicSelectorOpen then 
        love.graphics.draw(Sprites.Record, 675, 290)
    end    

    if playtestMode == true and recording == false then 
        for i,beatData in pairs(BeatMap.Beats) do
            if not utils.find(activeBeats, beatData) then 
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
                if beat.Hit == false then 
                    beat.PosY = beat.PosY + (60 * dt * 3)
                end
                if beat.Trail and beat.Trail.Time then
                    if beat.Trail.Holding == true then
                        beat.Trail.Time = beat.Trail.Time - dt
                    end
                end
            end
        end

        if recording == true then 
            for _,keycode in pairs(misc.KeyCodes) do 
                local found = false

                for key, time in pairs(holdingKeys) do 
                    if key == keycode then found = true break end
                end

                if not love.keyboard.isDown(keycode) then 
                    holdingKeys[keycode] = nil
                elseif love.keyboard.isDown(keycode) and found and holdingKeys[keycode] ~= nil then 
                    holdingKeys[keycode][1] = holdingKeys[keycode][1] + dt
                end
            end
        else
            holdingKeys = {}
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
        if utils:CheckCollision(x, y, 1, 1, button.x, button.y, button.scaleX, button.scaleY) and button.condition() == true then 
            getStartedHint = false
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
            local beatData = getBeatDataFromTime(utils.round(time, 1))
            if beatData then
                if beatData.Bomb ~= true and beatData.Powerup == nil then
                    if not utils.find(beatData.Beats, boundary) then 
                        table.insert(beatData.Beats, boundary)
                    end
                else
                    if not utils.find(beatData.Beats, boundary) then 
                        table.insert(BeatMap.Beats, {
                            ["Time"] = utils.round(time, 1),
                            ["Beats"] = {
                                boundary
                            }
                        })
                    end
                end
            else
                table.insert(BeatMap.Beats, {
                    ["Time"] = utils.round(time, 1),
                    ["Beats"] = {
                        boundary
                    }
                })
            end
        elseif editorMode == "placeBomb" then -- JAAAAAANK
            local beatData = getBeatDataFromTime(utils.round(time, 1))
            if beatData then 
                if beatData.Bomb == true and not utils.find(beatData.Beats, boundary) then 
                    table.insert(beatData.Beats, boundary)
                else
                    if not utils.find(beatData.Beats, boundary) then 
                        table.insert(BeatMap.Beats, {
                            ["Time"] = utils.round(time, 1),
                            ["Beats"] = {
                                boundary
                            },
                            ["Bomb"] = true
                        })
                    end
                end
            else
                table.insert(BeatMap.Beats, {
                    ["Time"] = utils.round(time, 1),
                    ["Beats"] = {
                        boundary
                    },
                    ["Bomb"] = true
                })
            end
            
        elseif editorMode == "placeGoldenBeat" then
            local beatData = getBeatDataFromTime(utils.round(time, 1))
            if beatData then 
                if beatData.Powerup == "2xScore" then 
                    if not utils.find(beatData.Beats, boundary)  then
                        table.insert(beatData.Beats, boundary)
                    end
                else
                    if not utils.find(beatData.Beats, boundary)  then 
                        table.insert(BeatMap.Beats, {
                            ["Time"] = utils.round(time, 1),
                            ["Beats"] = {
                                boundary
                            },
                            ["Powerup"] = "2xScore"
                        })
                    end
                end
            else
                table.insert(BeatMap.Beats, {
                    ["Time"] = utils.round(time, 1),
                    ["Beats"] = {
                        boundary
                    },
                    ["Powerup"] = "2xScore"
                })
            end
        elseif editorMode == "placeIce" then
            local beatData = getBeatDataFromTime(utils.round(time, 1))
            if beatData then 
                if beatData.Powerup == "Slow" then 
                    if not utils.find(beatData.Beats, boundary)  then
                        table.insert(beatData.Beats, boundary)
                    end
                else
                    if not utils.find(beatData.Beats, boundary)  then 
                        table.insert(BeatMap.Beats, {
                            ["Time"] = utils.round(time, 1),
                            ["Beats"] = {
                                boundary
                            },
                            ["Powerup"] = "Slow"
                        })
                    end
                end
            else
                table.insert(BeatMap.Beats, {
                    ["Time"] = utils.round(time, 1),
                    ["Beats"] = {
                        boundary
                    },
                    ["Powerup"] = "Slow"
                })
            end
        elseif editorMode == "delete" then 
            for i,beats in pairs(BeatMap.Beats) do 
                if beats.Time >= time - 0.2 and beats.Time <= time + 0.2 then 
                    for i2, beat in pairs(beats.Beats) do 
                        if beat == boundary then
                            table.remove(BeatMap.Beats[i].Beats, i2)

                            if #BeatMap.Beats[i].Beats == 0 then 
                                table.remove(BeatMap, i)
                            end

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
        local time = utils.round(((((460 - (circleRadius * 2)) - holdingBeatPosY)/(460 - (circleRadius * 2))) * 2.5) + ((page-1) * 2.5), 1)
        if y + 80 < holdingBeatPosY then 
            for index, data in pairs(BeatMap.Beats) do
                if data.Time == time and utils.find(data.Beats, holdingColumn) then
                    local trailTime = utils.round(((((460 - (circleRadius * 2)) - y)/(460 - (circleRadius * 2))) * 2.5) + ((page-1) * 2.5), 1)
                    BeatMap.Beats[index].Trail = (trailTime - 0.15) - time

                    return
                end
            end
        else
            for index, data in pairs(BeatMap.Beats) do
                if data.Time == time and utils.find(data.Beats, holdingColumn) then 
                    BeatMap.Beats[index].Trail = nil
                    return
                end
            end
        end
    end
end

function editor.mousereleased(x, y, button)
    holding = false
    if holdingColumn ~= 0 and holdingBeatPosY ~= 0 and holdingBeatPosX ~= 0 and playtestMode == false then 
        holdingColumn = 0
        holdingBeatPosY = 0
        holdingBeatPosX = 0
    end
end

function editor.fileLoaded(file)
    if playtestMode == true then return end

    file:open("r")
    local data = load(file:read())()
    BeatMap = data

    love.window.showMessageBox("Success", "Level '" .. file:getFilename() .. "' loaded successfully")
end

return editor