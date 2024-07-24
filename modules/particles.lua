local particles = {
    ["HitBeat"] = {
        ["Image"] = "Images/Sparkle.png",
        ["Size"] = 32,
        ["LifeTime"] = {0.25, 0.5},
        ["Speed"] = 0,
    }
}
particles.IsLoaded = false

function particles:Load()
    for index, pSystem in pairs(self) do
        if type(pSystem) == "table" and pSystem.Image then 
            for i = 1, 4 do
                local img = love.graphics.newImage(pSystem.Image)
                local particleSystem = love.graphics.newParticleSystem(img, 128)
                particleSystem:setParticleLifetime(pSystem.LifeTime[1], pSystem.LifeTime[2])
                particleSystem:setSpeed(pSystem.Speed)
                particleSystem:setLinearAcceleration(-2500, -2500, 2500, 2500)
                particleSystem:setSpread(10 * math.pi)
                

                if not self[i] then self[i] = {} end
                self[i][index] = particleSystem
            end
        end
        
    end
end

return particles