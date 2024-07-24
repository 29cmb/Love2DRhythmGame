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
    ["LargeButtonLeft"] = "Images/LeftLargeButton.png",
    ["GoldenBeat"] = "Images/GoldenBeat.png",
    ["Slowness"] = "Images/Slowness.png",
    ["Background"] = "Images/Background.png",
    ["Outline"] = "Images/ButtonOutline.png",
    ["DeleteBeat"] = "Images/DeleteBeat.png",
    ["PageUp"] = "Images/PageUp.png",
    ["PageDown"] = "Images/PageDown.png",
    ["Reset"] = "Images/ResetLevel.png",
    ["Save"] = "Images/Save.png",
    ["Music"] = "Images/MusicSelector.png",
    ["Record"] = "Images/Record.png"
}

Sprites.IsLoaded = false

function Sprites:Load()
    for index,spr in pairs(self) do 
        if type(spr) == "string" then 
            self[index] = love.graphics.newImage(spr)
        end
    end

    self.IsLoaded = true
end

return Sprites