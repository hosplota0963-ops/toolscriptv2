if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ProximityPromptService = game:GetService("ProximityPromptService") -- Added for Fast E

local lp = Players.LocalPlayer
repeat task.wait() until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

-- ======= CONFIG SYSTEM (REAL-TIME) =======
local ConfigName = "DarkSlayer_Config_V2.json"

-- Global States for Saving
_G.FlySpeed = 120
_G.ESPEnabled = false
_G.NoclipEnabled = false
_G.FlyEnabled = false
_G.InfJumpEnabled = false
_G.AutoClickEnabled = false 
_G.InstantEEnabled = false -- Added Global State for Fast E
_G.WaypointA = nil
_G.WaypointB = nil
_G.WaypointC = nil

local function SaveConfig()
    local data = {
        FlySpeed = _G.FlySpeed,
        ESP = _G.ESPEnabled,
        Noclip = _G.NoclipEnabled,
        Fly = _G.FlyEnabled,
        InfJump = _G.InfJumpEnabled,
        InstantE = _G.InstantEEnabled, -- Save Fast E State
        Waypoints = {
            A = _G.WaypointA and {X = _G.WaypointA.X, Y = _G.WaypointA.Y, Z = _G.WaypointA.Z} or nil,
            B = _G.WaypointB and {X = _G.WaypointB.X, Y = _G.WaypointB.Y, Z = _G.WaypointB.Z} or nil,
            C = _G.WaypointC and {X = _G.WaypointC.X, Y = _G.WaypointC.Y, Z = _G.WaypointC.Z} or nil
        }
    }
    pcall(function() writefile(ConfigName, HttpService:JSONEncode(data)) end)
end

local function LoadConfig()
    if isfile(ConfigName) then
        pcall(function()
            local data = HttpService:JSONDecode(readfile(ConfigName))
            _G.FlySpeed = data.FlySpeed or 120
            _G.ESPEnabled = data.ESP or false
            _G.NoclipEnabled = data.Noclip or false
            _G.FlyEnabled = data.Fly or false
            _G.InfJumpEnabled = data.InfJump or false
            _G.InstantEEnabled = data.InstantE or false -- Load Fast E State
            _G.AutoClickEnabled = false 
            if data.Waypoints then
                if data.Waypoints.A then _G.WaypointA = CFrame.new(data.Waypoints.A.X, data.Waypoints.A.Y, data.Waypoints.A.Z) end
                if data.Waypoints.B then _G.WaypointB = CFrame.new(data.Waypoints.B.X, data.Waypoints.B.Y, data.Waypoints.B.Z) end
                if data.Waypoints.C then _G.WaypointC = CFrame.new(data.Waypoints.C.X, data.Waypoints.C.Y, data.Waypoints.C.Z) end
            end
        end)
    end
end

LoadConfig()

-- State
local isFrozen = false
local ghostFlying = false
local frozenPos = nil
local timeLeft, timerOn = 0, false
local ghostClone = nil
local realBodyAnchorPos = nil
local isMouseOnUI = false 
local jToggleState = true -- State for J Waypoint Switch

-- Cleanup existing GUI
if CoreGui:FindFirstChild("DS_Phone_V1") then CoreGui["DS_Phone_V1"]:Destroy() end
if CoreGui:FindFirstChild("HaihubIntro") then CoreGui["HaihubIntro"]:Destroy() end

-- ======= INTRO SYSTEM =======
local introGui = Instance.new("ScreenGui", CoreGui)
introGui.Name = "HaihubIntro"
introGui.DisplayOrder = 999

local introLabel = Instance.new("TextLabel", introGui)
introLabel.Size = UDim2.new(0, 400, 0, 100)
introLabel.Position = UDim2.new(0.5, -200, 0.5, -50)
introLabel.BackgroundTransparency = 1
introLabel.Text = "Haihub script"
introLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
introLabel.TextSize = 60
introLabel.Font = Enum.Font.GothamBold
introLabel.TextTransparency = 1
introLabel.TextStrokeTransparency = 1

-- ======= PHONE UI DESIGN =======
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "DS_Phone_V1"
gui.Enabled = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 280, 0, 560)
main.Position = UDim2.new(0.5, -140, 0.5, -280)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
main.BorderSizePixel = 0
main.Active, main.Draggable = true, true

-- UI Interaction Tracking
main.MouseEnter:Connect(function() isMouseOnUI = true end)
main.MouseLeave:Connect(function() isMouseOnUI = false end)

local corner = Instance.new("UICorner", main)
corner.CornerRadius = UDim.new(0, 40)

local stroke = Instance.new("UIStroke", main)
stroke.Thickness = 4
stroke.Color = Color3.fromRGB(40, 40, 40)

local notch = Instance.new("Frame", main)
notch.Size = UDim2.new(0, 120, 0, 25)
notch.Position = UDim2.new(0.5, -60, 0, 0)
notch.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Instance.new("UICorner", notch).CornerRadius = UDim.new(0, 10)

local homeBar = Instance.new("Frame", main)
homeBar.Size = UDim2.new(0, 100, 0, 5)
homeBar.Position = UDim2.new(0.5, -50, 1, -15)
homeBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
homeBar.BackgroundTransparency = 0.5
Instance.new("UICorner", homeBar)

local container = Instance.new("ScrollingFrame", main)
container.Size = UDim2.new(0.9, 0, 0.82, 0)
container.Position = UDim2.new(0.05, 0, 0.08, 0)
container.BackgroundTransparency = 1
container.CanvasSize = UDim2.new(0, 0, 0, 800) -- ลดขนาดเนื่องจากเอาส่วน Follow ออก
container.ScrollBarThickness = 2
container.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)

local function createBtn(text, pos, size, color)
    local b = Instance.new("TextButton", container)
    b.Size = size or UDim2.new(1, 0, 0, 40)
    b.Position = pos
    b.Text = text
    b.BackgroundColor3 = color or Color3.fromRGB(25, 25, 25)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextScaled = true
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

-- ======= FEATURES =======
local espBtn = createBtn("ESP: " .. (_G.ESPEnabled and "ON" or "OFF"), UDim2.new(0, 0, 0, 0), nil, _G.ESPEnabled and Color3.fromRGB(0, 70, 0) or Color3.fromRGB(70, 0, 0))
local noclipBtn = createBtn("NOCLIP: " .. (_G.NoclipEnabled and "ON" or "OFF"), UDim2.new(0, 0, 0, 45), UDim2.new(0.48, 0, 0, 40), _G.NoclipEnabled and Color3.fromRGB(0, 70, 0) or Color3.fromRGB(70, 0, 0))
local flyBtn = createBtn("FLY: " .. (_G.FlyEnabled and "ON" or "OFF"), UDim2.new(0.52, 0, 0, 45), UDim2.new(0.48, 0, 0, 40), _G.FlyEnabled and Color3.fromRGB(0, 70, 0) or Color3.fromRGB(25, 25, 25))

-- Ghost Fly Section
local ghostFlyBtn = createBtn("GHOST FLY: OFF", UDim2.new(0, 0, 0, 90), nil, Color3.fromRGB(40, 0, 80))

local speedLabel = Instance.new("TextLabel", container)
speedLabel.Size = UDim2.new(0.48, 0, 0, 30)
speedLabel.Position = UDim2.new(0, 0, 0, 135)
speedLabel.Text = "FLY SPEED:"
speedLabel.TextColor3 = Color3.new(1,1,1)
speedLabel.BackgroundTransparency = 1
speedLabel.TextScaled = true

local speedInput = Instance.new("TextBox", container)
speedInput.Size = UDim2.new(0.48, 0, 0, 30)
speedInput.Position = UDim2.new(0.52, 0, 0, 135)
speedInput.Text = tostring(_G.FlySpeed)
speedInput.BackgroundColor3 = Color3.fromRGB(25,25,25)
speedInput.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", speedInput)

speedInput.FocusLost:Connect(function()
    _G.FlySpeed = tonumber(speedInput.Text) or 120
    SaveConfig()
end)

local speedBtn = createBtn("SPEED: OFF", UDim2.new(0, 0, 0, 170), UDim2.new(0.48, 0, 0, 40))
local jumpBtn = createBtn("INF JUMP: " .. (_G.InfJumpEnabled and "ON" or "OFF"), UDim2.new(0.52, 0, 0, 170), UDim2.new(0.48, 0, 0, 40), _G.InfJumpEnabled and Color3.fromRGB(0, 70, 0) or Color3.fromRGB(25, 25, 25))

-- Adjusted Freeze Button and added Fast E Button
local freezeBtn = createBtn("FREEZE: OFF", UDim2.new(0, 0, 0, 215), UDim2.new(0.48, 0, 0, 40), Color3.fromRGB(0, 45, 90))
local fastEBtn = createBtn("FAST E: " .. (_G.InstantEEnabled and "ON" or "OFF"), UDim2.new(0.52, 0, 0, 215), UDim2.new(0.48, 0, 0, 40), _G.InstantEEnabled and Color3.fromRGB(0, 70, 0) or Color3.fromRGB(70, 0, 0))

-- Auto Clicker Section
local autoClickBtn = createBtn("AUTO CLICK: OFF", UDim2.new(0, 0, 0, 260), nil, Color3.fromRGB(70, 0, 0))

-- Timer Section
local timerLabel = Instance.new("TextLabel", container)
timerLabel.Size = UDim2.new(1, 0, 0, 40)
timerLabel.Position = UDim2.new(0, 0, 0, 305)
timerLabel.Text = "00:00"
timerLabel.TextColor3 = Color3.new(1,1,1)
timerLabel.BackgroundTransparency = 1
timerLabel.TextScaled = true

local timeInput = Instance.new("TextBox", container)
timeInput.Size = UDim2.new(1, 0, 0, 30)
timeInput.Position = UDim2.new(0, 0, 0, 345)
timeInput.Text = "60"
timeInput.BackgroundColor3 = Color3.fromRGB(25,25,25)
timeInput.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", timeInput)

local startBtn = createBtn("START", UDim2.new(0, 0, 0, 380), UDim2.new(0.48, 0, 0, 35), Color3.fromRGB(0, 70, 0))
local resetBtn = createBtn("RESET", UDim2.new(0.52, 0, 0, 380), UDim2.new(0.48, 0, 0, 35), Color3.fromRGB(70, 0, 0))

task.spawn(function()
    while task.wait(1) do
        if timerOn and timeLeft > 0 then
            timeLeft = timeLeft - 1
            timerLabel.Text = string.format("%02d:%02d", math.floor(timeLeft/60), timeLeft%60)
        end
    end
end)

-- ======= CUSTOM WAYPOINTS (3 SETS) =======
local function createWaypointSet(name, yOffset)
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, 0, 0, 25)
    label.Position = UDim2.new(0, 0, 0, yOffset)
    label.Text = "WAYPOINT SET " .. name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundTransparency = 1
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold

    local setBtn = createBtn("SET POS " .. name, UDim2.new(0, 0, 0, yOffset + 30), UDim2.new(0.48, 0, 0, 35), Color3.fromRGB(40, 40, 80))
    local tpBtn = createBtn("TP TO " .. name, UDim2.new(0.52, 0, 0, yOffset + 30), UDim2.new(0.48, 0, 0, 35), Color3.fromRGB(80, 40, 40))

    setBtn.MouseButton1Click:Connect(function()
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            _G["Waypoint" .. name] = lp.Character.HumanoidRootPart.CFrame
            setBtn.Text = "SAVED!"
            SaveConfig()
            task.wait(1)
            setBtn.Text = "SET POS " .. name
        end
    end)

    tpBtn.MouseButton1Click:Connect(function()
        if _G["Waypoint" .. name] and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = _G["Waypoint" .. name]
        else
            tpBtn.Text = "NO POS!"
            task.wait(1)
            tpBtn.Text = "TP TO " .. name
        end
    end)
end

createWaypointSet("A", 430)
createWaypointSet("B", 510)
createWaypointSet("C", 590)

-- ======= BOTTOM SECTION (SERVER HOP) =======
local hopBtn = createBtn("JOIN ACTIVE SERVER", UDim2.new(0, 0, 0, 680), nil, Color3.fromRGB(160, 0, 0))
hopBtn.MouseButton1Click:Connect(function()
    hopBtn.Text = "FINDING..."
    local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
    local s, res = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)).data end)
    if s then
        for _, v in pairs(res) do
            local openSlots = v.maxPlayers - v.playing
            if openSlots >= 2 and openSlots <= 5 and v.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
                return
            end
        end
    end
end)

-- นำ Player Selector UI ออก และขยับ Exit Button ขึ้นมาแทนที่
local exitBtn = createBtn("SHUTDOWN", UDim2.new(0, 0, 0, 730), nil, Color3.fromRGB(40,40,40))
exitBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- ======= INTRO ANIMATION & UI DELAY =======
task.spawn(function()
    TweenService:Create(introLabel, TweenInfo.new(0.5), {TextTransparency = 0, TextStrokeTransparency = 0.5}):Play()
    task.wait(1.5)
    TweenService:Create(introLabel, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
    task.wait(0.5)
    introGui:Destroy()
    gui.Enabled = true
end)

-- ======= AUTO CLICKER LOGIC (STRICT UI CHECK) =======
task.spawn(function()
    while true do
        task.wait(0.01)
        if _G.AutoClickEnabled then
            if not isMouseOnUI and not UIS:GetFocusedTextBox() then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
        end
    end
end)

-- ======= FAST E LOGIC (UNIVERSAL) =======
local function instantPrompt(prompt)
    if prompt:IsA("ProximityPrompt") and _G.InstantEEnabled then
        prompt.HoldDuration = 0
    end
end

-- Hook for new objects
workspace.DescendantAdded:Connect(instantPrompt)

-- Hook for objects shown on screen
ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
    instantPrompt(prompt)
end)

local function updateAllPrompts()
    for _, descendant in pairs(workspace:GetDescendants()) do
        instantPrompt(descendant)
    end
end

-- Fast E Toggle Button
fastEBtn.MouseButton1Click:Connect(function()
    _G.InstantEEnabled = not _G.InstantEEnabled
    fastEBtn.Text = "FAST E: " .. (_G.InstantEEnabled and "ON" or "OFF")
    fastEBtn.BackgroundColor3 = _G.InstantEEnabled and Color3.fromRGB(0, 70, 0) or Color3.fromRGB(70, 0, 0)
    if _G.InstantEEnabled then
        updateAllPrompts()
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Universal Script",
                Text = "✅ กด E ไม่มีดีเลย์ ทำงานแล้ว!",
                Duration = 3,
            })
        end)
    end
    SaveConfig()
end)

-- ======= KEYBIND 'J' (WAYPOINT SWAP) =======
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.J then
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            -- Swap Logic between Waypoint A and B
            if jToggleState and _G.WaypointA then
                lp.Character.HumanoidRootPart.CFrame = _G.WaypointA
                jToggleState = false
            elseif not jToggleState and _G.WaypointB then
                lp.Character.HumanoidRootPart.CFrame = _G.WaypointB
                jToggleState = true
            elseif _G.WaypointA and not _G.WaypointB then
                -- Fallback if only A is set
                lp.Character.HumanoidRootPart.CFrame = _G.WaypointA
            elseif _G.WaypointB and not _G.WaypointA then
                -- Fallback if only B is set
                lp.Character.HumanoidRootPart.CFrame = _G.WaypointB
            end
        end
    end
end)

-- ======= GHOST FLY LOGIC (WITH CLONE) =======
ghostFlyBtn.MouseButton1Click:Connect(function()
    ghostFlying = not ghostFlying
    ghostFlyBtn.Text = "GHOST FLY: " .. (ghostFlying and "ON" or "OFF")
    ghostFlyBtn.BackgroundColor3 = ghostFlying and Color3.fromRGB(0, 70, 0) or Color3.fromRGB(40, 0, 80)
    
    if ghostFlying then
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            realBodyAnchorPos = lp.Character.HumanoidRootPart.CFrame
            lp.Character.Archivable = true
            ghostClone = lp.Character:Clone()
            ghostClone.Name = "GhostClone"
            ghostClone.Parent = workspace
            for _, v in pairs(ghostClone:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Transparency = 0.5
                    v.CanCollide = false
                    v.Anchored = true
                elseif v:IsA("Decal") then
                    v.Transparency = 0.5
                end
            end
            cam.CameraSubject = ghostClone:FindFirstChild("Humanoid")
            if lp.Character:FindFirstChild("Humanoid") then lp.Character.Humanoid.PlatformStand = true end
        end
    else
        if ghostClone and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = ghostClone.HumanoidRootPart.CFrame
            cam.CameraSubject = lp.Character:FindFirstChild("Humanoid")
            ghostClone:Destroy()
            ghostClone = nil
            realBodyAnchorPos = nil
            if lp.Character:FindFirstChild("Humanoid") then lp.Character.Humanoid.PlatformStand = false end
        end
    end
end)

-- ESP LOGIC
local function applyESP(p)
    if p == lp then return end
    local function setup(char)
        local h = Instance.new("Highlight", char)
        h.Name = "DS_Highlight"
        h.FillColor = Color3.new(1, 0, 0)
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        local head = char:WaitForChild("Head", 10)
        local bill = Instance.new("BillboardGui", head)
        bill.Name = "DS_Name"
        bill.Size = UDim2.new(0, 200, 0, 50)
        bill.AlwaysOnTop = true
        bill.ExtentsOffset = Vector3.new(0, 3, 0)
        
        local lbl = Instance.new("TextLabel", bill)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.TextStrokeTransparency = 0
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 14
        lbl.Text = p.DisplayName

        RunService.RenderStepped:Connect(function()
            h.Enabled = _G.ESPEnabled
            bill.Enabled = _G.ESPEnabled
        end)
    end
    p.CharacterAdded:Connect(setup)
    if p.Character then setup(p.Character) end
end

for _, p in pairs(Players:GetPlayers()) do applyESP(p) end
Players.PlayerAdded:Connect(applyESP)

-- LOOPS
RunService.Stepped:Connect(function()
    if (_G.NoclipEnabled or ghostFlying) and lp.Character then
        for _, v in pairs(lp.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then
                v.CanCollide = false
            end
        end
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = lp.Character.HumanoidRootPart
    
    if isFrozen and frozenPos then 
        hrp.CFrame = frozenPos
        hrp.Velocity = Vector3.new(0,0,0) 
    end
    
    if _G.FlyEnabled and not ghostFlying then
        local moveDir = Vector3.new(0,0,0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
        
        -- FIX: เปลี่ยนความเร็วแกน Y เป็น 0 เพื่อให้ตัวละครลอยนิ่งสนิทกลางอากาศ
        hrp.Velocity = Vector3.zero 
        hrp.CFrame = hrp.CFrame + (moveDir * _G.FlySpeed * dt)
    end
    
    if ghostFlying and ghostClone then
        if realBodyAnchorPos then
            hrp.CFrame = realBodyAnchorPos
            hrp.Velocity = Vector3.new(0,0,0)
        end
        local moveDir = Vector3.new(0,0,0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
        ghostClone.HumanoidRootPart.CFrame = ghostClone.HumanoidRootPart.CFrame + (moveDir * _G.FlySpeed * dt)
    end
end)

-- Toggles
autoClickBtn.MouseButton1Click:Connect(function()
    _G.AutoClickEnabled = not _G.AutoClickEnabled
    autoClickBtn.Text = "AUTO CLICK: " .. (_G.AutoClickEnabled and "ON" or "OFF")
    autoClickBtn.BackgroundColor3 = _G.AutoClickEnabled and Color3.fromRGB(0, 70, 0) or Color3.fromRGB(70, 0, 0)
end)

espBtn.MouseButton1Click:Connect(function() 
    _G.ESPEnabled = not _G.ESPEnabled
    espBtn.Text = "ESP: " .. (_G.ESPEnabled and "ON" or "OFF")
    espBtn.BackgroundColor3 = _G.ESPEnabled and Color3.fromRGB(0, 70, 0) or Color3.fromRGB(70, 0, 0)
    SaveConfig()
end)

noclipBtn.MouseButton1Click:Connect(function() 
    _G.NoclipEnabled = not _G.NoclipEnabled
    noclipBtn.Text = "NOCLIP: " .. (_G.NoclipEnabled and "ON" or "OFF")
    noclipBtn.BackgroundColor3 = _G.NoclipEnabled and Color3.fromRGB(0, 70, 0) or Color3.fromRGB(70, 0, 0)
    SaveConfig()
end)

flyBtn.MouseButton1Click:Connect(function() 
    _G.FlyEnabled = not _G.FlyEnabled
    flyBtn.Text = "FLY: " .. (_G.FlyEnabled and "ON" or "OFF")
    flyBtn.BackgroundColor3 = _G.FlyEnabled and Color3.fromRGB(0, 70, 0) or Color3.fromRGB(25, 25, 25)
    if lp.Character:FindFirstChild("Humanoid") then 
        lp.Character.Humanoid.PlatformStand = _G.FlyEnabled 
    end 
    SaveConfig()
end)

speedBtn.MouseButton1Click:Connect(function() 
    local h = lp.Character:FindFirstChild("Humanoid") 
    if h then 
        h.WalkSpeed = (h.WalkSpeed == 16 and 100 or 16) 
        speedBtn.Text = "SPEED: "..(h.WalkSpeed > 20 and "ON" or "OFF")
        speedBtn.BackgroundColor3 = h.WalkSpeed > 20 and Color3.fromRGB(0, 70, 0) or Color3.fromRGB(25, 25, 25)
    end 
end)

freezeBtn.MouseButton1Click:Connect(function() 
    isFrozen = not isFrozen
    frozenPos = isFrozen and lp.Character.HumanoidRootPart.CFrame or nil
    freezeBtn.Text = isFrozen and "FREEZE: ON" or "FREEZE: OFF" 
    freezeBtn.BackgroundColor3 = isFrozen and Color3.fromRGB(0, 70, 0) or Color3.fromRGB(0, 45, 90)
end)

jumpBtn.MouseButton1Click:Connect(function() 
    _G.InfJumpEnabled = not _G.InfJumpEnabled
    jumpBtn.Text = "INF JUMP: " .. (_G.InfJumpEnabled and "ON" or "OFF")
    jumpBtn.BackgroundColor3 = _G.InfJumpEnabled and Color3.fromRGB(0, 70, 0) or Color3.fromRGB(25, 25, 25)
    SaveConfig()
end)

UIS.JumpRequest:Connect(function() 
    if _G.InfJumpEnabled and lp.Character:FindFirstChild("Humanoid") then 
        lp.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) 
    end 
end)

startBtn.MouseButton1Click:Connect(function() 
    if not timerOn then 
        timeLeft = tonumber(timeInput.Text) or 0
        timerOn = true
        startBtn.Text = "STOP" 
    else 
        timerOn = false
        startBtn.Text = "START" 
    end 
end)

resetBtn.MouseButton1Click:Connect(function() 
    timeLeft = 0
    timerOn = false
    timerLabel.Text = "00:00" 
end)

-- Apply initial states
if _G.FlyEnabled and lp.Character:FindFirstChild("Humanoid") then
    lp.Character.Humanoid.PlatformStand = true
end
if _G.InstantEEnabled then
    updateAllPrompts()
end
