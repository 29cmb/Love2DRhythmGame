local self = {} -- Why am I using self here? Well you see, oooo purple
local circleRadius = 20
local spacing = (300 - (4 * circleRadius * 2)) / 5
local circleY = 500 - circleRadius - 40

local Sprites = require("modules.sprites")
local Fonts = require("modules.fonts")
local SFX = require("modules.sfx")
local utils = require("modules.utils")
local editor = require("editor")
local misc = require("modules.misc")
local ParticleSystems = require("modules.particles")
local Powerups = require("modules.powerups")

self.Score = 0
self.InEditor = false

self.Speed = 3
self.Powerup = "None"
self.PowerupTimer = 0

self.ActiveSong = nil
self.ActiveAudio = nil
self.GameStarted = false
self.GamePaused = false
self.GameFinished = false

self.Beats = {[1] = {}, [2] = {}, [3] = {}, [4] = {}}

self.TimeSinceGameBegan = 0
self.ActiveBeats = {}


self.Background = nil
self.ScoreMultiplier = 1

self.MenuPage = "MainMenu"



function self.load()
    if Sprites.IsLoaded == false then Sprites:Load() end
    if Fonts.IsLoaded == false then Fonts:Load() end
    if SFX.IsLoaded == false then SFX:Load() end
    if ParticleSystems.IsLoaded == false then ParticleSystems:Load() end
    if Powerups.IsLoaded == false then Powerups:Load() end

    if self.InEditor == false then
        love.window.setMode(300, 500)
        love.window.setTitle("Rhythm Game")
        background = love.graphics.newImage("Images/Background.png")
    else
        editor.load()
    end
end

love.load = self.load

self.VisualScore = 0

local levelPositions = {}
local levelPage = 1
local firstTick = true
function love.draw()
    if firstTick then 
        firstTick = false
        self.endGame()
    end
    
    if self.InEditor == true then
        editor.draw()
        return
    end

    if self.Background ~= nil then 
        for i = 0, love.graphics.getWidth() / self.Background:getWidth() do
            for j = 0, love.graphics.getHeight() / self.Background:getHeight() do
                love.graphics.draw(self.Background, i * self.Background:getWidth(), j * self.Background:getHeight())
            end
        end
    end

    if self.GameStarted == false then
        love.graphics.draw(Sprites[self.MenuPage])
        if self.MenuPage ~= "MainMenu" then 
            love.graphics.draw(Sprites.BackButton, 5, 5)
        end

        if self.MenuPage == "LevelsMenu" then 
            levelPositions = {}
            love.filesystem.setIdentity("rhythm-game-levels")
            local rhythmIndex = 1
            for _, v in ipairs(love.filesystem.getDirectoryItems("")) do
                if v:match("^.+(%..+)$") == ".rhythm" then -- a rhythm file is just a lua file in disguise, it will parse any formatted file as long as it is a lua table.
                    rhythmIndex = rhythmIndex + 1
                    if (rhythmIndex > ((levelPage - 1) * 6) and rhythmIndex <= (levelPage * 6)) then 
                        love.graphics.rectangle("fill", 75, (#levelPositions * 45) + 200, 150, 40)
                        love.graphics.setColor(0,0,0)
                        love.graphics.setFont(Fonts.LevelText)
                        love.graphics.printf(v, -24.5, (#levelPositions * 45) + 207.5, 350, "center")
                        love.graphics.setColor(1,1,1)

                        local data = load(love.filesystem.read(v))()

                        table.insert(levelPositions, {
                            ["Song"] = data.Data.Song,
                            ["PosY"] = ((#levelPositions) * 45) + 200,
                            ["Data"] = data
                        })
                    else
                        print(rhythmIndex, levelPage, (levelPage - 1) * 6, ((levelPage) * 6))
                    end
                end
            end

            love.graphics.draw(Sprites.LargeButtonLeft, 0, 275)
            love.graphics.draw(Sprites.LargeButtonRight, 260, 275)
        end

        return
    end

    if self.GameFinished == true then 
        love.graphics.setFont(Fonts.Score)
        
        if self.VisualScore < self.Score then 
            love.graphics.draw(Sprites.ExitEndGameOverlay)
            if self.Score >= 300 then 
                self.VisualScore = utils.clamp(self.VisualScore + math.floor((self.Score/300)), 0, self.Score)
            else
                self.VisualScore = self.Score
            end
            
            SFX.Point:play()
        else
            love.graphics.draw(Sprites.FinishedOverlay)
        end

        love.graphics.printf(self.VisualScore,90,225,125,"center")
        return
    end
    

    if self.Powerup ~= "None" then 
        love.graphics.draw(Sprites.PowerupBorder)
    end

    local BeatMap = self.ActiveSong
    for i = 1, 4 do
        local circleX = spacing * i + circleRadius * (2 * i - 1)
        for _,pSystem in pairs(ParticleSystems[i]) do 
            love.graphics.draw(pSystem, circleX, circleY)
        end
        for _,beat in pairs(self.Beats[i]) do 
            if beat.Hit == false or (beat.Trail and (beat.Trail.Held == false and beat.Trail.Holding == true)) then
                
                if beat.Trail and beat.Trail.Time then
                    if beat.Hit == true then beat.PosY = circleY end
                    if beat.Trail.Time > 0 then
                        love.graphics.setColor(misc.Colors[i], 0.7)
                        love.graphics.rectangle("fill", circleX - 10, beat.PosY - circleRadius, circleRadius, -(beat.Trail.Time * 60 * self.Speed)) -- negative I guess?
                        love.graphics.circle("fill", circleX, beat.PosY - circleRadius - (beat.Trail.Time * 60 * self.Speed), circleRadius/2) -- curved corners
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
                
                
                if self.GamePaused == false and beat.Hit == false then
                    --beat.PosY = beat.PosY + (self.Speed * (beat.SpeedMod or 1))
                end
            else
                self.Beats[i][beat] = nil
            end
        end

        if not love.keyboard.isDown(misc.KeyCodes[i]) or self.GamePaused then
            love.graphics.circle("line", circleX, circleY, circleRadius)
            for _,beat in pairs(self.Beats[i]) do
                if beat.Hit and beat.Trail and beat.Trail.Time then 
                    if beat.Trail.Holding == true then 
                        beat.Trail.Held = true
                        beat.Trail.Holding = false

                        local time = math.abs(beat.Trail.Time)

                        if time < 0.1 then
                            self.Score = self.Score + 500
                        elseif time < 0.25 then
                            self.Score = self.Score + 250
                        elseif time < 0.5 then
                            self.Score = self.Score + 100
                        else
                            self.Score = self.Score + 50
                        end 
                    end
                end
            end
        else
            love.graphics.setColor(misc.Colors[i])
            love.graphics.circle("fill", circleX, circleY, circleRadius)
            love.graphics.setColor(0,0,0)
            love.graphics.circle("line", circleX, circleY, circleRadius)
            love.graphics.setColor(1, 1, 1)

            -- calculate score based on how centered it was
            for _,beat in pairs(self.Beats[i]) do
                local distance = math.abs(beat.PosY - circleY)
                if distance <= (circleRadius * 2) and (beat.Hit == false or (beat.Trail and beat.Trail.Time)) then
                    if beat.Hit == false then
                        ParticleSystems[i].HitBeat:setColors(misc.Colors[i])
                        ParticleSystems[i].HitBeat:emit(10)
                        if beat.Powerup ~= "None" then 
                            Powerups[beat.Powerup].Callback()
                            SFX.Powerup:play()

                            print("Powerup " .. beat.Powerup .. " activated")
                            self.Powerup = beat.Powerup
                            self.PowerupTimer = Powerups[beat.Powerup].Duration
                        elseif beat.Bomb == true then 
                            self.Score = utils.clamp(self.Score - 2000)
                        elseif distance <= 2 then
                            self.Score = self.Score + (500 * self.ScoreMultiplier)
                        elseif distance <= 5 then
                            self.Score = self.Score + (350 * self.ScoreMultiplier)
                        elseif distance <= 10 then
                            self.Score = self.Score + (200 * self.ScoreMultiplier)
                        elseif distance <= 15 then
                            self.Score = self.Score + (100 * self.ScoreMultiplier)
                        else
                            self.Score = self.Score + (50 * self.ScoreMultiplier)
                        end
                    end

                    beat.Hit = true

                    if beat.Trail and beat.Trail.Time and beat.Trail.Held == false then 
                        beat.Trail.Holding = true
                    end
                end
            end
        end
    end

    love.graphics.push()
    love.graphics.setFont(Fonts.Score)
    love.graphics.print("Score: " .. self.Score, 10, 10)
    love.graphics.pop()
    
    if self.GamePaused then
        love.graphics.draw(Sprites.Resume, 230, 10)
        love.graphics.draw(Sprites.ExitGame, 130, 85)
    else
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.draw(Sprites.Pause, 230, 10)
        love.graphics.setColor(1,1,1,1)
    end
end

function love.update(dt)

    if self.InEditor == true then
        editor.update(dt)
        return
    end

    for i = 1, 4 do 
        for _,pSystem in pairs(ParticleSystems[i]) do
            pSystem:update(dt)
        end
    end

    if self.GameStarted then
        if self.GamePaused == false then 
            self.TimeSinceGameBegan = self.TimeSinceGameBegan + ((dt/3)*self.Speed)
            if self.ActiveSong == nil then return end
            for _, beatData in pairs(self.ActiveSong) do
                if not utils.find(self.ActiveBeats, beatData) then 
                    if beatData.Time <= 2.5 then
                        table.insert(self.ActiveBeats, beatData)
                        for _,beatCircle in pairs(beatData.Beats) do
                            table.insert(self.Beats[beatCircle], {
                                ["PosY"] = (460 - (circleRadius * 2)) - (168 * beatData.Time),
                                ["Hit"] = false,
                                ["SpeedMod"] = beatData.SpeedMod or 1,
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
                        if beatData.Time <= (self.TimeSinceGameBegan + 2.5) then 
                            if beatData.End == true then 
                                self.GameFinished = true
                                break
                            end
                            table.insert(self.ActiveBeats, beatData)
                            for _,beat in pairs(beatData.Beats) do
                                table.insert(self.Beats[beat], {
                                    ["PosY"] = -5,
                                    ["Hit"] = false,
                                    ["SpeedMod"] = beatData.SpeedMod or 1,
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

            for i = 1, 4 do 
                for _,beat in pairs(self.Beats[i]) do 
                    if self.GamePaused == false and beat.Hit == false then
                        beat.PosY = beat.PosY + math.abs(60 * dt * (self.Speed * (beat.SpeedMod or 1)))
                        -- make it go crazy
                        -- beat.PosY = 60 * dt * (beat.PosY + self.Speed * (beat.SpeedMod or 1))
                    end
                end
            end
            
            self.PowerupTimer = self.PowerupTimer - dt
            if self.PowerupTimer <= 0 and self.Powerup ~= "None" then 
                Powerups[self.Powerup].Undo()
                self.PowerupTimer = 0
                self.Powerup = "None"
            end
        end
    end
    

    for i = 1, 4 do 
        for _,beat in pairs(self.Beats[i]) do 
            if beat.Trail and beat.Trail.Time then
                if beat.Trail.Holding == true then
                    beat.Trail.Time = beat.Trail.Time - dt
                end
            end
        end
    end
end

function startGame(song, custom, customBeatMap)
    if custom == true then 
        self.ActiveSong = customBeatMap.Beats
        self.GameStarted = true

        if self.ActiveAudio ~= nil then 
            self.ActiveAudio:stop()
        end

        local audio = love.audio.newSource("Songs/" .. song .. "/Music.mp3", "stream")
        audio:setVolume(0.6)
        audio:play()

        self.Background = love.graphics.newImage(customBeatMap.Data.BackgroundImage)
        self.ActiveAudio = audio
    else
        self.ActiveSong = require("Songs." .. song .. ".beats")
        self.GameStarted = true

        if self.ActiveAudio ~= nil then 
            self.ActiveAudio:stop()
        end

        local audio = love.audio.newSource("Songs/" .. song .. "/Music.mp3", "stream")
        audio:setVolume(0.6)
        audio:play()

        self.Background = love.graphics.newImage(require("Songs." .. song .. ".data").BackgroundImage)
        self.ActiveAudio = audio
    end
end

function pause()
    if self.GamePaused == false then
        self.GamePaused = true
        self.ActiveAudio:pause()
    end
end

function unpause()
    if self.GamePaused == true then
        self.GamePaused = false
        self.ActiveAudio:play()
    end
end

function self.endGame()
    self.GameStarted = false
    self.GamePaused = false
    self.GameFinished = false

    self.Score = 0
    self.Speed = 3
    self.PowerupTimer = 0
    
    self.ActiveSong = nil

    self.Speed = 3
    self.Powerup = "None"
    self.PowerupTimer = 0
    self.VisualScore = 0

    self.ActiveSong = nil
    if self.ActiveAudio ~= nil then 
        self.ActiveAudio:stop()
    end
   
    self.ActiveAudio = nil

    self.Beats = {[1] = {}, [2] = {}, [3] = {}, [4] = {}}
    self.TimeSinceGameBegan = 0
    self.ActiveBeats = {}

    self.Background = nil
    self.ScoreMultiplier = 1

    self.MenuPage = "MainMenu"

    self.ActiveAudio = love.audio.newSource("NonLevelMusic/MenuLoop.mp3", "stream")
    self.ActiveAudio:setLooping(true)
    self.ActiveAudio:play()
end

-- UI shennanigans
local editorLoaded = false
function love.mousepressed(x, y, button)
    if self.InEditor then
        editor.mousepressed(x, y, button)
        return
    end

    if self.GameStarted == true then
        if self.GameFinished == true then
            if utils:CheckCollision(x, y, 1, 1, 24, 376, 254, 100) then 
                self.endGame()
            end
        else
            if utils:CheckCollision(x, y, 1, 1, 230, 10, 65, 65) then
                if self.GamePaused == true then
                    unpause()
                else
                    pause()
                end
            end
        end

        if self.GamePaused == true then 
            if utils:CheckCollision(x, y, 1, 1, 130, 85, 168, 67) then 
                self.endGame()
            end
        end
    else
        if self.MenuPage == "MainMenu" then 
            if utils:CheckCollision(x, y, 1, 1, 62, 80, 177, 93) then
                self.MenuPage = "PlayMenu"
            elseif utils:CheckCollision(x, y, 1, 1, 62, 202, 177, 93) then
                if editorLoaded == false then 
                    editor.load()
                else
                    love.window.setMode(1024, 500)
                end

                editorLoaded = true
                self.InEditor = true
                if self.ActiveAudio then 
                    self.ActiveAudio:stop()
                end
            elseif utils:CheckCollision(x, y, 1, 1, 62, 325, 177, 93) then
                self.MenuPage = "LevelsMenu"
            end
        elseif self.MenuPage == "PlayMenu" then
            if utils:CheckCollision(x, y, 1, 1, 62, 90, 117, 93) then 
                startGame("On and On", false)
            elseif utils:CheckCollision(x, y, 1, 1, 62, 204, 117, 93) then
                startGame("Fearless II", false)
            elseif utils:CheckCollision(x, y, 1, 1, 62, 319, 117, 93) then
                startGame("My Heart", false)
            elseif utils:CheckCollision(x, y, 1, 1, 5, 5, 65, 65) then
                self.MenuPage = "MainMenu"
            end
        elseif self.MenuPage == "LevelsMenu" then 
            for _,btn in pairs(levelPositions) do
                if utils:CheckCollision(x, y, 1, 1, 75, btn.PosY, 150, 40) then 
                    startGame(btn.Song, true, btn.Data)
                    return
                end
            end

            if utils:CheckCollision(x, y, 1, 1, 5, 5, 65, 65) then
                self.MenuPage = "MainMenu"
                levelPage = 1
            elseif utils:CheckCollision(x, y, 1, 1, 0, 275, 48, 128) then 
                if levelPage ~= 1 then 
                    levelPage = levelPage - 1
                end
            elseif utils:CheckCollision(x, y, 1, 1, 260, 275, 48, 128) then 
                local levels = 0
                for _,v in pairs(love.filesystem.getDirectoryItems("")) do 
                    if v:match("^.+(%..+)$") == ".rhythm" then
                        levels = levels + 1
                    end
                end

                if levels >= ((levelPage) * 6) then 
                    levelPage = levelPage + 1
                end
            end
        end
    end
end

function love.filedropped(file) 
    if self.GameStarted == false then
        filename = file:getFilename()
	    ext = filename:match("%.%w+$")
        if ext == ".rhythm" then 
            if self.MenuPage == "LevelsMenu" then 
                file:open("r")
                local data = load(file:read())()
                startGame(data.Data.Song, true, data)
            else 
                if self.InEditor == false then 
                    if editorLoaded == false then 
                        editor.load()
                        love.window.setMode(1024, 500)
                    end

                    editorLoaded = true
                    self.InEditor = true
                end

                local confirm = love.window.showMessageBox("Confirm", "Would you like to load level '" .. file:getFilename() .. "'?", {"No", "Yes"}, "info", true)
                if confirm == 2 then 
                    editor.fileLoaded(file)
                end
            end
        end
    end
end

function love.mousereleased(x, y, button)
    if self.InEditor == true then 
        editor.mousereleased(x, y, button)
    end 
end

function love.mousemoved(x, y, dx, dy)
    if self.InEditor == true then 
        editor.mousemoved(x,y)
    end
end

return self