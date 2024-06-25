local self = {}
local circleRadius = 20
local spacing = (300 - (4 * circleRadius * 2)) / 5
local circleY = 500 - circleRadius - 40
local speed = 3

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

self.Beats = {[1] = {}, [2] = {}, [3] = {}, [4] = {}}
self.TimeSinceGameBegan = 0
self.ActiveBeats = {}

function love.load()
    love.window.setMode(300, 500)
end

function love.draw(dt)
    local BeatMap = require("beats")
    for i = 1, 4 do
        local circleX = spacing * i + circleRadius * (2 * i - 1)

        for _,beat in pairs(self.Beats[i]) do 
            if beat.Hit == false then
                love.graphics.setColor(self.Colors[i])
                love.graphics.circle("fill", circleX, beat.PosY, circleRadius)
                love.graphics.setColor(1,1,1)

                beat.PosY = beat.PosY + (speed * (beat.SpeedMod or 1))
            else
                self.Beats[i][beat] = nil
            end
        end

        if not love.keyboard.isDown(self.KeyCodes[i]) then
            love.graphics.circle("line", circleX, circleY, circleRadius)
        else
            love.graphics.setColor(self.Colors[i])
            love.graphics.circle("fill", circleX, circleY, circleRadius)
            love.graphics.setColor(1, 1, 1)

            -- calculate score based on how centered it was
            -- Furthest point they can be apart is 39.999...
            -- Minimum is obviously 0
            for _,beat in pairs(self.Beats[i]) do
                local distance = math.abs(beat.PosY - circleY)
                if distance <= circleRadius and beat.Hit == false then
                    beat.Hit = true

                    if distance <= 2 then
                        self.Score = self.Score + 500
                        print("500")
                    elseif distance <= 5 then
                        self.Score = self.Score + 350
                        print("350")
                    elseif distance <= 10 then
                        self.Score = self.Score + 200
                        print("200")
                    elseif distance <= 20 then
                        self.Score = self.Score + 100
                        print("100")
                    else
                        self.Score = self.Score + 50
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
            print("Beat time")
            for _,v in pairs(beat.Beats) do 
                table.insert(self.Beats[v], {
                    ["PosY"] = -5,
                    ["Hit"] = false,
                    ["SpeedMod"] = beat.SpeedMod
                })
            end
        end
    end
end

function love.update(dt)
    self.TimeSinceGameBegan = self.TimeSinceGameBegan + dt
end

function table.find(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end