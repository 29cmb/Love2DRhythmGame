local self = {}
local circleRadius = 20
local spacing = (300 - (4 * circleRadius * 2)) / 5
local circleY = 500 - circleRadius - 10

self.colors = {
    [1] = {255/255, 0, 0},
    [2] = {255/255, 150/255, 0},
    [3] = {255/255, 217/255, 0},
    [4] = {128/255, 255/255, 0}
}

function love.load()
    love.window.setMode(300, 500)
end


function love.draw()
    for i = 1, 4 do
        local circleX = spacing * i + circleRadius * (2 * i - 1)
        love.graphics.circle("fill", circleX, circleY, circleRadius)
    end
end

