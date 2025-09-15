--// Load OrionLib
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

--// Variables
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character, HumanoidRootPart
local isAutoFarm = false
local teleportDelay = 0.5
local resetAfter = 20
local collectedChests = 0

--// Init Character
local function initChar()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end
initChar()

--// Find all chests
local function findChests()
    local chests = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("chest") or n:find("treasure") or obj:FindFirstChild("Chest") then
                table.insert(chests, obj)
            end
        end
    end
    table.sort(chests, function(a,b)
        return (HumanoidRootPart.Position - a.Position).Magnitude < (HumanoidRootPart.Position - b.Position).Magnitude
    end)
    return chests
end

--// Reset Char
local function resetChar()
    local h = Character:FindFirstChildOfClass("Humanoid")
    if h then h.Health = 0 end
    task.wait(6)
    initChar()
end

--// Teleport farming
local function farmChests()
    while isAutoFarm do
        local chests = findChests()
        if #chests == 0 then
            OrionLib:MakeNotification({Name="Chest Farm", Content="Không còn chest!", Time=3})
            break
        end
        for _, chest in ipairs(chests) do
            if not isAutoFarm then break end
            HumanoidRootPart.CFrame = chest.CFrame + Vector3.new(0,3,0)
            collectedChests += 1
            ChestLabel:Set("Đã nhặt: "..collectedChests)
            task.wait(teleportDelay)
            if collectedChests % resetAfter == 0 then
                resetChar()
            end
        end
    end
end

--// GUI
local Window = OrionLib:MakeWindow({Name="⚡ Auto Chest Farm", HidePremium=false, SaveConfig=false})

local Tab = Window:MakeTab({Name="Main", Icon="rbxassetid://4483345998"})

Tab:AddToggle({
    Name="Auto Farm Chest",
    Default=false,
    Callback=function(v)
        isAutoFarm = v
        if v then
            task.spawn(farmChests)
        end
    end
})

Tab:AddSlider({
    Name="Delay Teleport (s)",
    Min=0.1, Max=3, Default=0.5, Increment=0.1,
    Callback=function(v) teleportDelay=v end
})

Tab:AddSlider({
    Name="Reset sau số chest",
    Min=5, Max=100, Default=20, Increment=1,
    Callback=function(v) resetAfter=v end
})

ChestLabel = Tab:AddLabel("Đã nhặt: 0")

OrionLib:Init()
