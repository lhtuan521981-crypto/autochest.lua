-- AUTO FARM CHEST FULL SCRIPT
-- Có: Auto chọn team Marine, Auto reset, Auto hop server sau 100 chest
-- Ưu tiên chest gần nhất trước

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")

-- Biến toàn cục
local Character
local HumanoidRootPart
local AUTO_HOP_ENABLED = true
local HOP_DELAY = 5
local RESET_AFTER_CHESTS = 10
local RESET_WAIT_TIME = 6
local MAX_CHESTS_BEFORE_HOP = 100
local isAutoFarming = false
local selectedTeam = "Marine"

-- Khởi tạo character
local function initializeCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end

-- Auto chọn team Marine
local function autoSelectMarineTeam()
    local teamService = game:GetService("Teams")
    local marineTeam = nil
    for _, team in pairs(teamService:GetTeams()) do
        local teamName = team.Name:lower()
        if teamName:find("marine") or teamName:find("hải quân") then
            marineTeam = team
            break
        end
    end
    if marineTeam then
        pcall(function()
            LocalPlayer.Team = marineTeam
            selectedTeam = marineTeam.Name
        end)
    end
end

local function checkAndSelectTeam()
    if LocalPlayer.Team == nil then
        autoSelectMarineTeam()
    else
        selectedTeam = LocalPlayer.Team.Name
    end
end

-- Tìm chest và sắp xếp gần trước
local function findChests()
    local chests = {}
    for _, part in ipairs(workspace:GetDescendants()) do
        local lowerName = part.Name:lower()
        if part:IsA("BasePart") and (
            lowerName:find("chest") or 
            lowerName:find("treasure") or 
            lowerName:find("box") or
            lowerName:find("reward") or
            lowerName:find("ruong") or
            lowerName:find("kho bau") or
            part:FindFirstChild("IsChest") ~= nil or
            part:FindFirstChild("Chest") ~= nil
        ) then
            table.insert(chests, part)
        end
    end

    if HumanoidRootPart then
        table.sort(chests, function(a, b)
            return (HumanoidRootPart.Position - a.Position).Magnitude 
                 < (HumanoidRootPart.Position - b.Position).Magnitude
        end)
    end

    return chests
end

local function respawnCharacter()
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.Health = 0 end
    wait(RESET_WAIT_TIME)
    initializeCharacter()
    checkAndSelectTeam()
end

local collectedAll = 0

local function teleportToChests()
    local chests = findChests()
    if #chests == 0 then return 0 end
    local collected = 0

    for _, chest in ipairs(chests) do
        if not isAutoFarming then break end
        HumanoidRootPart.CFrame = CFrame.new(chest.Position + Vector3.new(0,3,0))
        collected += 1
        collectedAll += 1
        wait(0.5)

        if collected % RESET_AFTER_CHESTS == 0 then
            respawnCharacter()
            wait(2)
        end

        if collectedAll >= MAX_CHESTS_BEFORE_HOP then
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
            return collected
        end
    end
    return collected
end

-- Auto farm main loop
local function startAutoFarm()
    if isAutoFarming then return end
    isAutoFarming = true
    initializeCharacter()
    checkAndSelectTeam()

    while isAutoFarming do
        local collected = teleportToChests()
        if AUTO_HOP_ENABLED and isAutoFarming then
            for i = HOP_DELAY,1,-1 do
                if not isAutoFarming then break end
                wait(1)
            end
            if isAutoFarming then
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
                break
            end
        else
            wait(30)
        end
    end
end

-- GUI
local function createAutoFarmGUI()
    local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Size = UDim2.new(0, 400, 0, 280)
    Frame.Position = UDim2.new(0, 10, 0, 10)
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)

    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Text = "🤖 AUTO CHEST FARM"
    Title.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)

    local StartButton = Instance.new("TextButton", Frame)
    StartButton.Size = UDim2.new(0, 180, 0, 50)
    StartButton.Position = UDim2.new(0, 10, 0, 50)
    StartButton.Text = "🚀 START"
    StartButton.MouseButton1Click:Connect(startAutoFarm)

    local StopButton = Instance.new("TextButton", Frame)
    StopButton.Size = UDim2.new(0, 180, 0, 50)
    StopButton.Position = UDim2.new(0, 210, 0, 50)
    StopButton.Text = "⏹️ STOP"
    StopButton.MouseButton1Click:Connect(function() isAutoFarming = false end)

    local ResetBox = Instance.new("TextBox", Frame)
    ResetBox.Size = UDim2.new(0, 180, 0, 30)
    ResetBox.Position = UDim2.new(0, 10, 0, 120)
    ResetBox.Text = "Reset sau "..RESET_AFTER_CHESTS.." chest"
    ResetBox.FocusLost:Connect(function()
        local val = tonumber(ResetBox.Text)
        if val then RESET_AFTER_CHESTS = val end
    end)

    local HopBox = Instance.new("TextBox", Frame)
    HopBox.Size = UDim2.new(0, 180, 0, 30)
    HopBox.Position = UDim2.new(0, 210, 0, 120)
    HopBox.Text = "Hop sau "..MAX_CHESTS_BEFORE_HOP.." chest"
    HopBox.FocusLost:Connect(function()
        local val = tonumber(HopBox.Text)
        if val then MAX_CHESTS_BEFORE_HOP = val end
    end)

    local DelayBox = Instance.new("TextBox", Frame)
    DelayBox.Size = UDim2.new(0, 380, 0, 30)
    DelayBox.Position = UDim2.new(0, 10, 0, 170)
    DelayBox.Text = "Delay hop "..HOP_DELAY.."s"
    DelayBox.FocusLost:Connect(function()
        local val = tonumber(DelayBox.Text)
        if val then HOP_DELAY = val end
    end)
end

createAutoFarmGUI()
