-- AUTO FARM CHEST + GUI (có hop server sau X rương)
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Config mặc định
local TELEPORT_DELAY = 0.5
local RESET_AFTER_CHESTS = 10
local RESET_WAIT_TIME = 6
local HOP_AFTER_CHESTS = 100
local AUTO_HOP_ENABLED = true
local HOP_DELAY = 5

-- Trạng thái
local isAutoFarming = false
local Character, HumanoidRootPart
local collectedTotal = 0

-- Init character
local function initializeCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end
initializeCharacter()
LocalPlayer.CharacterAdded:Connect(function()
    wait(RESET_WAIT_TIME)
    initializeCharacter()
end)

-- Reset
local function respawnCharacter()
    local humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Health = 0
        for i = RESET_WAIT_TIME, 1, -1 do
            wait(1)
        end
        initializeCharacter()
    end
end

-- Tìm part đại diện cho chest
local function getChestPart(chest)
    if not chest then return nil end
    if chest:IsA("BasePart") then return chest end
    if chest:IsA("Model") then
        if chest.PrimaryPart then return chest.PrimaryPart end
        for _,d in ipairs(chest:GetDescendants()) do
            if d:IsA("BasePart") then return d end
        end
    end
    return nil
end

-- Thử fire remote (ReplicatedStorage)
local function tryFireRemoteCollect(chest)
    local fired = false
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            if n:find("chest") or n:find("collect") or n:find("open") or n:find("pickup") or n:find("treasure") then
                pcall(function()
                    if obj:IsA("RemoteEvent") then obj:FireServer(chest) end
                    if obj:IsA("RemoteFunction") then obj:InvokeServer(chest) end
                end)
                fired = true
            end
        end
    end
    return fired
end

-- Thử touch hoặc MoveTo
local function tryTouchCollect(part)
    if not part then return false end
    if not HumanoidRootPart or not HumanoidRootPart.Parent then initializeCharacter() end
    pcall(function()
        HumanoidRootPart.CFrame = CFrame.new(part.Position + Vector3.new(0,1,0))
    end)
    wait(0.2)
    if type(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(HumanoidRootPart, part, 0)
            wait(0.12)
            firetouchinterest(HumanoidRootPart, part, 1)
        end)
        return true
    end
    return (HumanoidRootPart.Position - part.Position).Magnitude < 5
end

-- Tổng hợp collect
local function attemptCollect(chest)
    if not chest then return false end
    local part = getChestPart(chest)
    if tryFireRemoteCollect(chest) then return true end
    if tryTouchCollect(part) then return true end
    local humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if humanoid and part then
        humanoid:MoveTo(part.Position + Vector3.new(0,2,0))
        wait(1)
        if (HumanoidRootPart.Position - part.Position).Magnitude < 5 then return true end
    end
    return false
end

-- Hop server (gửi teleport request và lưu state để auto restart)
local function hopServer()
    if not AUTO_HOP_ENABLED then return end
    pcall(function()
        _G.AutoRestartFarm = true
        _G.AutoFarmSettings = {
            enabled = isAutoFarming,
            hopEnabled = AUTO_HOP_ENABLED,
            resetCount = RESET_AFTER_CHESTS,
            hopDelay = HOP_DELAY,
            resetWait = RESET_WAIT_TIME,
            teleportDelay = TELEPORT_DELAY,
            hopAfter = HOP_AFTER_CHESTS
        }
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- Farm loop
local function teleportToChestsLoop()
    while isAutoFarming do
        for _, obj in ipairs(workspace:GetDescendants()) do
            if not isAutoFarming then break end
            if obj.Name:lower():find("chest") then
                local part = getChestPart(obj)
                if part then
                    -- Tele
                    if not HumanoidRootPart or not HumanoidRootPart.Parent then initializeCharacter() end
                    HumanoidRootPart.CFrame = CFrame.new(part.Position + Vector3.new(0,3,0))
                    wait(0.2)
                    attemptCollect(obj)

                    collectedTotal = collectedTotal + 1

                    -- Highlight (tùy ý)
                    local hl = Instance.new("Highlight")
                    hl.Parent = obj
                    hl.FillColor = Color3.fromRGB(255,215,0)
                    hl.OutlineColor = Color3.fromRGB(200,170,0)
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    wait(0.1)
                    hl:Destroy()

                    -- Reset sau N rương
                    if collectedTotal % RESET_AFTER_CHESTS == 0 then
                        respawnCharacter()
                        wait(2)
                    end

                    -- Nếu đạt ngưỡng để hop server
                    if HOP_AFTER_CHESTS > 0 and collectedTotal >= HOP_AFTER_CHESTS then
                        print("➡️ Đạt "..collectedTotal.." rương. Bắt đầu hop server...")
                        hopServer()
                        return
                    end

                    wait(TELEPORT_DELAY)
                end
            end
        end
        task.wait(TELEPORT_DELAY)
    end
end

-- Start / Stop
local function startAutoFarm()
    if isAutoFarming then return end
    isAutoFarming = true
    if not Character or not HumanoidRootPart or not HumanoidRootPart.Parent then initializeCharacter() end
    task.spawn(teleportToChestsLoop)
end

local function stopAutoFarm()
    isAutoFarming = false
    print("⏹️ Dừng AutoFarm")
end

-- Auto-restart handling after teleport (nếu dùng hopServer)
if _G.AutoRestartFarm then
    task.spawn(function()
        wait(8)
        if _G.AutoFarmSettings then
            TELEPORT_DELAY = _G.AutoFarmSettings.teleportDelay or TELEPORT_DELAY
            RESET_AFTER_CHESTS = _G.AutoFarmSettings.resetCount or RESET_AFTER_CHESTS
            RESET_WAIT_TIME = _G.AutoFarmSettings.resetWait or RESET_WAIT_TIME
            HOP_AFTER_CHESTS = _G.AutoFarmSettings.hopAfter or HOP_AFTER_CHESTS
            isAutoFarming = _G.AutoFarmSettings.enabled
        end
        initializeCharacter()
        _G.AutoRestartFarm = false
        if isAutoFarming then startAutoFarm() end
    end)
end

-- GUI (Start/Stop + settings)
local screen = Instance.new("ScreenGui")
screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
screen.Name = "AutoFarmChestGUI"
screen.ResetOnSpawn = false

local frame = Instance.new("Frame", screen)
frame.Size = UDim2.new(0,420,0,260)
frame.Position = UDim2.new(0,10,0,10)
frame.BackgroundColor3 = Color3.fromRGB(35,35,45)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,36)
title.Position = UDim2.new(0,0,0,0)
title.Text = "🤖 AUTO FARM CHEST"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.BackgroundColor3 = Color3.fromRGB(0,110,220)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18

local function makeLabel(x,y,text)
    local l = Instance.new("TextLabel", frame)
    l.Size = UDim2.new(0,200,0,24)
    l.Position = UDim2.new(0,x,0,y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(220,220,220)
    l.Font = Enum.Font.SourceSans
    l.TextSize = 14
    return l
end

local delayBox = Instance.new("TextBox", frame)
delayBox.Size = UDim2.new(0,160,0,30)
delayBox.Position = UDim2.new(0,10,0,50)
delayBox.Text = tostring(TELEPORT_DELAY)

local resetBox = Instance.new("TextBox", frame)
resetBox.Size = UDim2.new(0,160,0,30)
resetBox.Position = UDim2.new(0,10,0,90)
resetBox.Text = tostring(RESET_AFTER_CHESTS)

local waitBox = Instance.new("TextBox", frame)
waitBox.Size = UDim2.new(0,160,0,30)
waitBox.Position = UDim2.new(0,10,0,130)
waitBox.Text = tostring(RESET_WAIT_TIME)

local hopBox = Instance.new("TextBox", frame)
hopBox.Size = UDim2.new(0,160,0,30)
hopBox.Position = UDim2.new(0,10,0,170)
hopBox.Text = tostring(HOP_AFTER_CHESTS)

makeLabel(0,30,"⏱ Delay tele (giây)")
makeLabel(0,70,"📦 Reset sau bao nhiêu rương")
makeLabel(0,110,"⏳ Thời gian chờ reset (giây)")
makeLabel(0,150,"🔀 Hop server sau tổng rương (0 = tắt)")

local saveBtn = Instance.new("TextButton", frame)
saveBtn.Size = UDim2.new(0,160,0,30)
saveBtn.Position = UDim2.new(0,200,0,50)
saveBtn.Text = "💾 Lưu"
saveBtn.BackgroundColor3 = Color3.fromRGB(0,160,90)
saveBtn.TextColor3 = Color3.fromRGB(255,255,255)

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(0,160,0,30)
startBtn.Position = UDim2.new(0,200,0,90)
startBtn.Text = "🚀 Start"
startBtn.BackgroundColor3 = Color3.fromRGB(0,140,220)
startBtn.TextColor3 = Color3.fromRGB(255,255,255)

local stopBtn = Instance.new("TextButton", frame)
stopBtn.Size = UDim2.new(0,160,0,30)
stopBtn.Position = UDim2.new(0,200,0,130)
stopBtn.Text = "⏹ Stop"
stopBtn.BackgroundColor3 = Color3.fromRGB(200,40,40)
stopBtn.TextColor3 = Color3.fromRGB(255,255,255)

local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(1,-20,0,28)
statusLabel.Position = UDim2.new(0,10,0,210)
statusLabel.Text = "Trạng thái: Tắt | Thu tổng: 0"
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(200,200,200)

saveBtn.MouseButton1Click:Connect(function()
    local d = tonumber(delayBox.Text)
    local r = tonumber(resetBox.Text)
    local w = tonumber(waitBox.Text)
    local h = tonumber(hopBox.Text)
    if d and d > 0 then TELEPORT_DELAY = d end
    if r and r > 0 then RESET_AFTER_CHESTS = r end
    if w and w > 0 then RESET_WAIT_TIME = w end
    if h and h >= 0 then HOP_AFTER_CHESTS = h end
    statusLabel.Text = "Trạng thái: Cấu hình đã lưu | Thu tổng: "..tostring(collectedTotal)
end)

startBtn.MouseButton1Click:Connect(function()
    if not isAutoFarming then
        collectedTotal = 0
        statusLabel.Text = "Trạng thái: Đang chạy | Thu tổng: "..tostring(collectedTotal)
        startAutoFarm()
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    if isAutoFarming then
        stopAutoFarm()
        statusLabel.Text = "Trạng thái: Đã dừng | Thu tổng: "..tostring(collectedTotal)
    end
end)

-- Update status hàng giây
task.spawn(function()
    while true do
        wait(1)
        statusLabel.Text = "Trạng thái: "..(isAutoFarming and "Đang chạy" or "Tắt").." | Thu tổng: "..tostring(collectedTotal)
    end
end)
