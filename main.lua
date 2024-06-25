local self = {} -- Why do I use self? oooo purple
local circleRadius = 20
local spacing = (300 - (4 * circleRadius * 2)) / 5
local circleY = 500 - circleRadius - 40

local UI = require("Packages.UI")
local collision = require("collision")

self.Score = 0
self.Colors = {
    [1] = {255/255, 0, 0},
    [2] = {255/255, 150/255, 0},
    [3] = {255/255, 217/255, 0},
    [4] = {5/255, 255/255, 0}
}


self.KeyCodes = {
    [1] = "a",
    [2] = "s",
    [3] = "d",
    [4] = "f"
}

self.SongKeyCodes = {
    ["On and On"] = "1"
}

local Sprites = {
    ["Bomb"] = "Images/bomb.png",
    ["PowerupBorder"] = "Images/PowerupBorder.png",
    ["Pause"] = "Images/Pause.png",
    ["Resume"] = "Images/Resume.png",
    ["MenuBg"] = "Images/MenuBg.png"
}
self.Speed = 3
self.Powerup = "None"
-- Clock: Slow down the game
-- Golden beat: 2x points
self.PowerupTimer = 0

self.ActiveSong = nil
self.ActiveAudio = nil
self.GameStarted = false
self.GamePaused = false

self.Beats = {[1] = {}, [2] = {}, [3] = {}, [4] = {}}
self.TimeSinceGameBegan = 0
self.ActiveBeats = {}

self.Background = nil
self.ScoreMultiplier = 1

self.Powerups = {
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


function love.load()
    love.window.setMode(300, 500)
    love.window.setTitle("Rhythm Game")
    background = love.graphics.newImage("Images/Background.png")

    for name,spr in pairs(Sprites) do
        Sprites[name] = love.graphics.newImage(spr)
    end

    for _, data in pairs(self.Powerups) do 
        data.Sprite = love.graphics.newImage(data.Sprite)
    end
end

function love.draw()
    if self.Background ~= nil then 
        for i = 0, love.graphics.getWidth() / self.Background:getWidth() do
            for j = 0, love.graphics.getHeight() / self.Background:getHeight() do
                love.graphics.draw(self.Background, i * self.Background:getWidth(), j * self.Background:getHeight())
            end
        end
    end
    

    if self.GameStarted == false then

        love.graphics.draw(Sprites.MenuBg)

        UI.draw({
            x = 115, 
            y = 30,
            UI.button({"On and On", on_click = function() startGame("On and On") end}),
        })

        return
    end
    if self.GamePaused then
        love.graphics.print(self.TimeSinceGameBegan .. " time has passed")
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.draw(Sprites.Resume, 230, 10)
        love.graphics.setColor(1,1,1,1)
    else
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.draw(Sprites.Pause, 230, 10)
        love.graphics.setColor(1,1,1,1)
    end

    if self.Powerup ~= "None" then 
        love.graphics.draw(Sprites.PowerupBorder)
        love.graphics.push()
        love.graphics.scale(2,2)
        love.graphics.print(self.Powerup .. "!", 50, 30)
        love.graphics.pop()
    end

    local BeatMap = require(self.ActiveSong)
    for i = 1, 4 do
        local circleX = spacing * i + circleRadius * (2 * i - 1)

        for _,beat in pairs(self.Beats[i]) do 
            if beat.Hit == false then
                if beat.Powerup ~= "None" then
                    local powerup = self.Powerups[beat.Powerup]
                    love.graphics.draw(powerup.Sprite, circleX, beat.PosY, 0, 1, 1, powerup.SpriteOffset.x, powerup.SpriteOffset.y)
                elseif beat.Bomb == false then
                    love.graphics.setColor(self.Colors[i])
                    love.graphics.circle("fill", circleX, beat.PosY, circleRadius)
                    love.graphics.setColor(0,0,0)
                    love.graphics.circle("line", circleX, beat.PosY, circleRadius)
                    love.graphics.setColor(1,1,1)
                elseif beat.Bomb == true then
                    love.graphics.draw(Sprites.Bomb, circleX, beat.PosY, 0, 1, 1, 22, 30) -- why is the sprite off-center? No idea.
                end
                
                if self.GamePaused == false then
                    beat.PosY = beat.PosY + (self.Speed * (beat.SpeedMod or 1))
                end
            else
                self.Beats[i][beat] = nil
            end
        end

        if not love.keyboard.isDown(self.KeyCodes[i]) or self.GamePaused then
            love.graphics.circle("line", circleX, circleY, circleRadius)
        else
            love.graphics.setColor(self.Colors[i])
            love.graphics.circle("fill", circleX, circleY, circleRadius)
            love.graphics.setColor(0,0,0)
            love.graphics.circle("line", circleX, circleY, circleRadius)
            love.graphics.setColor(1, 1, 1)

            -- calculate score based on how centered it was
            for _,beat in pairs(self.Beats[i]) do
                local distance = math.abs(beat.PosY - circleY)
                if distance <= (circleRadius * 2) and beat.Hit == false then
                    beat.Hit = true

                    if beat.Powerup ~= "None" then 
                        self.Powerups[beat.Powerup].Callback()
                        print("Powerup " .. beat.Powerup .. " activated")
                        self.Powerup = beat.Powerup
                        self.PowerupTimer = self.Powerups[beat.Powerup].Duration
                    elseif beat.Bomb == true then 
                        self.Score = math.clamp(self.Score - 2000)
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
            end
        end
    end

    love.graphics.push()
    love.graphics.scale(1.5, 1.5)
    love.graphics.print("Score: " .. self.Score, 10, 10)
    love.graphics.pop()

    for _, beat in pairs(BeatMap) do
        if self.TimeSinceGameBegan >= beat.Time and not table.find(self.ActiveBeats, beat) then
            table.insert(self.ActiveBeats, beat)
            for _,v in pairs(beat.Beats) do 
                table.insert(self.Beats[v], {
                    ["PosY"] = -5,
                    ["Hit"] = false,
                    ["SpeedMod"] = beat.SpeedMod,
                    ["Bomb"] = beat.Bomb or false,
                    ["Powerup"] = beat.Powerup or "None"
                })
            end
        end
    end
end

function love.update(dt)
    if love.keyboard.isDown("j") then
        pause()
    end

    if love.keyboard.isDown("k") then
        unpause()
    end

    if self.GameStarted then
        if self.GamePaused == false then 
            self.TimeSinceGameBegan = self.TimeSinceGameBegan + dt
            self.PowerupTimer = self.PowerupTimer - dt
            if self.PowerupTimer <= 0 and self.Powerup ~= "None" then 
                self.Powerups[self.Powerup].Undo()
                self.PowerupTimer = 0
                self.Powerup = "None"
            end
        end
    else
        for song, key in pairs(self.SongKeyCodes) do 
            if love.keyboard.isDown(key) then
                startGame(song)
            end
        end
    end
end

function startGame(song)
    self.ActiveSong = "Songs." .. song .. ".beats"
    self.GameStarted = true

    local audio = love.audio.newSource("Songs/" .. song .. "/Music.mp3", "stream")
    audio:setVolume(0.6)
    audio:play()

    self.Background = love.graphics.newImage(require("Songs." .. song .. ".data").BackgroundImage)
    self.ActiveAudio = audio
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

function table.find(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function math.clamp(val, lower, upper)
    if not lower then lower = 0 end
    if not upper then upper = math.huge end

    assert(val, "Value not provided")

    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end


-- UI shennanigans
function love.mousepressed(x, y, button)
    local input = { x = x, y = y }
    if button == 1 then
       input = UI.mousepressed(input)
    end

    if self.GameStarted == true then
        if collision:CheckCollision(x, y, 1, 1, 230, 10, 65, 65) then
            if self.GamePaused == true then
                unpause()
            else
                pause()
            end
        end
    end
 end
 
 function love.mousereleased(x, y, button)
    local input = { x = x, y = y }
    if button == 1 then
       input = UI.mousereleased(input)
    end
 end
 
 function love.mousemoved(x, y)
    local input = { x = x, y = y }
    UI.mousemoved(input)
 end
 
 function love.textinput(t)
    UI.textinput(t)
 end
 
function love.keypressed(key)
    UI.keypressed(key)
end