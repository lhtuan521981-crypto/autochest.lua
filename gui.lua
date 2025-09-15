-- AUTO FARM CHEST + GUI (Full Package)

-- OrionLib GUI
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")

-- Config
local TELEPORT_DELAY = 0.5
local HOP_AFTER_CHESTS = 100
local collectedTotal = 0
local isAutoFarm = false

-- Character
local Character, HumanoidRootPart
local function initChar()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end
initChar()
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    initChar()
end)

-- Chest finder (near first)
local function getNearestChest()
    local nearest, dist = nil, math.huge
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("TouchInterest") then
            local mag = (HumanoidRootPart.Position - v.Position).Magnitude
            if mag < dist then
                dist = mag
                nearest = v
            end
        end
    end
    return nearest
end

-- Auto farm loop
local function autoFarm()
    while isAutoFarm and task.wait(TELEPORT_DELAY) do
        local chest = getNearestChest()
        if chest then
            HumanoidRootPart.CFrame = chest.CFrame + Vector3.new(0,3,0)
            firetouchinterest(HumanoidRootPart, chest, 0)
            firetouchinterest(HumanoidRootPart, chest, 1)
            collectedTotal += 1
            if collectedTotal % HOP_AFTER_CHESTS == 0 then
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end
        end
    end
end

-- GUI
local Window = OrionLib:MakeWindow({Name = "Auto Chest Farm", HidePremium = false, SaveConfig = true, ConfigFolder = "AutoChest"})

local Tab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

Tab:AddToggle({
    Name = "Auto Farm Chest",
    Default = false,
    Callback = function(Value)
        isAutoFarm = Value
        if Value then
            task.spawn(autoFarm)
        end
    end    
})

Tab:AddLabel("Collected: 0"):UpdateLabel("Collected: "..collectedTotal)

OrionLib:Init()
