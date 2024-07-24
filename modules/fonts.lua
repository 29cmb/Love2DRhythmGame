local Fonts = {
    ["Headers"] = {"Fonts/SF Archery Black.ttf", 40},
    ["Score"] = {"Fonts/good times rg.otf", 25},
    ["LevelText"] = {"Fonts/Roboto-Regular.ttf", 20}
}
Fonts.IsLoaded = false

function Fonts:Load()
    for index, fnt in pairs(self) do 
        if type(fnt) == "table" and #fnt == 2 then 
            self[index] = love.graphics.newFont(fnt[1], fnt[2])
        end
    end

    self.IsLoaded = true
end

return Fonts