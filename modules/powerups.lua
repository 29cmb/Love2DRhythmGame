local powerups = {
    ["2xScore"] = {
        Duration = 7,
        Sprite = "Images/GoldenBeat.png",
        SpriteOffset = {x = 22, y = 30},
        Callback = function()
            require("main").ScoreMultiplier = 2
        end,
        Undo = function()
            require("main").ScoreMultiplier = 1
        end
    },
    ["Slow"] = {
        Duration = 5,
        Sprite = "Images/Slowness.png",
        SpriteOffset = {x = 22, y = 30},
        Callback = function()
            require("main").Speed = require("main").Speed * 0.75
            require("main").ActiveAudio:setPitch(.75)
        end,
        Undo = function()
            require("main").Speed = require("main").Speed * 1.25
            require("main").ActiveAudio:setPitch(1)
        end
    }
}
powerups.IsLoaded = false

function powerups:Load()
    for index, power in pairs(self) do 
        if type(power) == "table" then 
            self[index].Sprite = love.graphics.newImage(power.Sprite)
        end
    end

    self.IsLoaded = true
end

return powerups