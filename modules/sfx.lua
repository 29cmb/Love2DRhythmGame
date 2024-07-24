local sfx = {
    ["Powerup"] = "SFX/Powerup.wav",
    ["Point"] = "SFX/Point.wav"
}
sfx.IsLoaded = false

function sfx:Load()
    for index, sound in pairs(self) do 
        if type(sound) == "string" then 
            self[index] = love.audio.newSource(sound, "stream")
        end
    end
end

return sfx