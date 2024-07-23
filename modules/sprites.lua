local Sprites = {
    ["Bomb"] = "Images/bomb.png",
    ["PowerupBorder"] = "Images/PowerupBorder.png",
    ["Pause"] = "Images/Pause.png",
    ["Resume"] = "Images/Resume.png",
    ["MainMenu"] = "Images/MenuBg.png",
    ["PlayMenu"] = "Images/PlayMenu.png",
    ["LevelsMenu"] = "Images/LevelsMenu.png",
    ["ExitGame"] = "Images/ExitGame.png",
    ["FinishedOverlay"] = "Images/FinishedOverlay.png",
    ["ExitEndGameOverlay"] = "Images/ExitGameEndGameOverlay.png",
    ["BackButton"] = "Images/BackButton.png",
    ["LargeButtonRight"] = "Images/RightLargeButton.png",
    ["LargeButtonLeft"] = "Images/LeftLargeButton.png"
}

function Sprites:Load()
    for index,spr in pairs(self) do 
        if typeof(spr) == "string" then 
            self[index] = love.graphics.newImage(spr)
        end
    end
end

return Sprites