-- AUTO FARM CHEST FULL V2
-- Có: Auto chọn team Marine, Auto reset, Auto hop server, Ưu tiên chest gần nhất
-- Thêm GUI đẹp + đếm số chest đã lụm

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")

-- Biến chính
local Character
local HumanoidRootPart
local AUTO_HOP_ENABLED = true
local HOP_DELAY = 5
local RESET_AFTER_CHESTS = 10
local RESET_WAIT_TIME = 6
local MAX_CHESTS_BEFORE_HOP = 100
local isAutoFarming = false
local selectedTeam = "Marine"

local collectedAll = 0 -- tổng số chest đã lụm

-- Init character
local function initializeCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end

-- Auto chọn team Marine
local function autoSelectMarineTeam()
    local teamService = game:GetService("Teams")
    for _, team in pairs(teamService:GetTeams()) do
        if team.Name:lower():find("marine") or team.Name:lower():find("hải quân") then
            LocalPlayer.Team = team
            selectedTeam = team.Name
            break
        end
    end
end

local function checkAndSelectTeam()
    if LocalPlayer.Team == nil then
        autoSelectMarineTeam()
    else
        selectedTeam = LocalPlayer.Team.Name
    end
end

-- Tìm chest gần nhất
local function findChests()
    local chests = {}
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and (
            part.Name:lower():find("chest") or
            part.Name:lower():find("treasure") or
            part.Name:lower():find("box") or
            part:FindFirstChild("IsChest") ~= nil
        ) then
            table.insert(chests, part)
        end
    end
    if HumanoidRootPart then
        table.sort(chests, function(a, b)
            return (HumanoidRootPart.Position - a.Position).Magnitude <
                   (HumanoidRootPart.Position - b.Position).Magnitude
        end)
    end
    return chests
end

-- Reset nhân vật
local function respawnCharacter()
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.Health = 0 end
    wait(RESET_WAIT_TIME)
    initializeCharacter()
    checkAndSelectTeam()
end

-- Tele đến chest
local function teleportToChests()
    local chests = findChests()
    if #chests == 0 then return 0 end
    local collected = 0

    for _, chest in ipairs(chests) do
        if not isAutoFarming then break end
        HumanoidRootPart.CFrame = CFrame.new(chest.Position + Vector3.new(0,3,0))
        collected += 1
        collectedAll += 1
        if _G.CollectedLabel then
            _G.CollectedLabel.Text = "Đã lụm: " .. collectedAll .. " chest"
        end
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

-- Auto farm loop
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

-- GUI đẹp
local function createAutoFarmGUI()
    local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Size = UDim2.new(0, 420, 0, 300)
    Frame.Position = UDim2.new(0, 20, 0, 20)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true

    local UICorner = Instance.new("UICorner", Frame)
    UICorner.CornerRadius = UDim.new(0, 12)

    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Text = "🔥 AUTO CHEST FARM 🔥"
    Title.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 20
    local TitleCorner = Instance.new("UICorner", Title)
    TitleCorner.CornerRadius = UDim.new(0, 12)

    local StartButton = Instance.new("TextButton", Frame)
    StartButton.Size = UDim2.new(0, 180, 0, 40)
    StartButton.Position = UDim2.new(0, 20, 0, 60)
    StartButton.Text = "🚀 START"
    StartButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    StartButton.Font = Enum.Font.GothamBold
    StartButton.TextSize = 18
    Instance.new("UICorner", StartButton).CornerRadius = UDim.new(0, 8)
    StartButton.MouseButton1Click:Connect(startAutoFarm)

    local StopButton = Instance.new("TextButton", Frame)
    StopButton.Size = UDim2.new(0, 180, 0, 40)
    StopButton.Position = UDim2.new(0, 220, 0, 60)
    StopButton.Text = "⏹ STOP"
    StopButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    StopButton.Font = Enum.Font.GothamBold
    StopButton.TextSize = 18
    Instance.new("UICorner", StopButton).CornerRadius = UDim.new(0, 8)
    StopButton.MouseButton1Click:Connect(function() isAutoFarming = false end)

    local ResetBox = Instance.new("TextBox", Frame)
    ResetBox.Size = UDim2.new(0, 180, 0, 30)
    ResetBox.Position = UDim2.new(0, 20, 0, 120)
    ResetBox.Text = "Reset sau "..RESET_AFTER_CHESTS.." chest"
    ResetBox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    ResetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", ResetBox).CornerRadius = UDim.new(0, 8)
    ResetBox.FocusLost:Connect(function()
        local val = tonumber(ResetBox.Text)
        if val then RESET_AFTER_CHESTS = val end
    end)

    local HopBox = Instance.new("TextBox", Frame)
    HopBox.Size = UDim2.new(0, 180, 0, 30)
    HopBox.Position = UDim2.new(0, 220, 0, 120)
    HopBox.Text = "Hop sau "..MAX_CHESTS_BEFORE_HOP.." chest"
    HopBox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    HopBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", HopBox).CornerRadius = UDim.new(0, 8)
    HopBox.FocusLost:Connect(function()
        local val = tonumber(HopBox.Text)
        if val then MAX_CHESTS_BEFORE_HOP = val end
    end)

    local DelayBox = Instance.new("TextBox", Frame)
    DelayBox.Size = UDim2.new(0, 380, 0, 30)
    DelayBox.Position = UDim2.new(0, 20, 0, 170)
    DelayBox.Text = "Delay hop "..HOP_DELAY.."s"
    DelayBox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    DelayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", DelayBox).CornerRadius = UDim.new(0, 8)
    DelayBox.FocusLost:Connect(function()
        local val = tonumber(DelayBox.Text)
        if val then HOP_DELAY = val end
    end)

    local CollectedLabel = Instance.new("TextLabel", Frame)
    CollectedLabel.Size = UDim2.new(0, 380, 0, 40)
    CollectedLabel.Position = UDim2.new(0, 20, 0, 220)
    CollectedLabel.Text = "Đã lụm: 0 chest"
    CollectedLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    CollectedLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    CollectedLabel.Font = Enum.Font.GothamBold
    CollectedLabel.TextSize = 18
    Instance.new("UICorner", CollectedLabel).CornerRadius = UDim.new(0, 8)

    -- gắn global để update
    _G.CollectedLabel = CollectedLabel
end

createAutoFarmGUI()
