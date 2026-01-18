local KeyFileName = "CatHub_SavedKey.txt"
local CorrectKey = "ScriptTodday"

function loadMainScript()
    local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local player = Players.LocalPlayer

    local config = {
        speed = 450,
        isTweening = false,
        heightOffset = 4.5,
        instantTake = true,
        unlimitedZoom = false
    }

    -- ==========================================
    -- HỆ THỐNG QUẢN LÝ NOCLIP CƯỠNG BỨC
    -- ==========================================
    RunService.Stepped:Connect(function()
        if config.isTweening and player.Character then
            for _, p in ipairs(player.Character:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end
    end)

    -- ==========================================
    -- HIỂN THỊ THỜI GIAN SPAWN CELESTIAL
    -- ==========================================
    local function setupCelestialTimer(labelObj)
        task.spawn(function()
            while task.wait(0.5) do
                pcall(function()
                    local modelFolder = Workspace:FindFirstChild("Model")
                    if modelFolder then
                        local children = modelFolder:GetChildren()
                        local targetPart = children[15]
                        if targetPart then
                            local textLabel = targetPart:FindFirstChild("SurfaceGui") and 
                                              targetPart.SurfaceGui:FindFirstChild("Frame") and 
                                              targetPart.SurfaceGui.Frame:FindFirstChild("TextLabel")
                            
                            if textLabel then
                                labelObj:Set("." .. textLabel.ContentText)
                            end
                        end
                    end
                end)
            end
        end)
    end

    -- ==========================================
    -- LOGIC TELEPORT: CHỐNG TÉ & TỰ TẮT NOCLIP
    -- ==========================================
    local function GetGapCenter(i)
        local gaps = Workspace:FindFirstChild("Misc") and Workspace.Misc:FindFirstChild("Gaps")
        if not gaps then return nil end
        local gap = gaps:FindFirstChild("Gap"..i)
        if not gap then return nil end

        local biggestPart = nil
        local maxVolume = 0
        for _, p in ipairs(gap:GetDescendants()) do
            if p:IsA("BasePart") then
                local volume = p.Size.X * p.Size.Y * p.Size.Z
                if volume > maxVolume then maxVolume = volume; biggestPart = p end
            end
        end
        return biggestPart
    end

    local function ForcedCenterTP(targetPart)
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or not targetPart or config.isTweening then return end

        config.isTweening = true
        
        local bp = Instance.new("BodyPosition")
        bp.MaxForce = Vector3.new(1, 1, 1) * 1e7
        bp.P = 20000
        bp.D = 200
        
        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(1, 1, 1) * 1e7
        bg.P = 20000
        bg.CFrame = root.CFrame
        bg.Parent = root

        local targetPos = targetPart.Position + Vector3.new(0, config.heightOffset, 0)
        bp.Position = root.Position
        bp.Parent = root

        local distance = (targetPos - root.Position).Magnitude
        local tweenTime = distance / config.speed
        
        local tween = TweenService:Create(bp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {Position = targetPos})
        tween:Play()
        
        tween.Completed:Connect(function()
            task.wait(0.1)
            bp:Destroy()
            bg:Destroy()
            config.isTweening = false 
            
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end

    -- ==========================================
    -- SIÊU FIX INSTANT TAKE
    -- ==========================================
    local function initInstantTake()
        local root = Workspace:FindFirstChild("ActiveBrainrots")
        if not root then return end
        local function deepScan(folder)
            for _, item in ipairs(folder:GetDescendants()) do
                if item:IsA("ProximityPrompt") then item.HoldDuration = 0 end
            end
            folder.DescendantAdded:Connect(function(desc)
                if desc:IsA("ProximityPrompt") and config.instantTake then
                    task.wait()
                    desc.HoldDuration = 0
                end
            end)
        end
        deepScan(root)
    end

    -- ==========================================
    -- GIAO DIỆN CHÍNH
    -- ==========================================
    local Win = Rayfield:CreateWindow({Name = "CAT HUB | FREMIUM", LoadingTitle = "Đang tải cấu hình..."})
    local MainTab = Win:CreateTab("Mics", 4483362458)
    local MudTab = Win:CreateTab("MAIN", 4483362458)

    -- Label Celestial
    local CelestialLabel = MainTab:CreateLabel("Celestial Spawn: Đang kiểm tra...")
    setupCelestialTimer(CelestialLabel)

    -- Zoom Toggle
    MainTab:CreateToggle({
        Name = "Unlimited Zoom",
        CurrentValue = false,
        Callback = function(v) 
            config.unlimitedZoom = v
            if v then
                player.CameraMaxZoomDistance = 10000
            else
                player.CameraMaxZoomDistance = 35
            end
        end
    })

    MainTab:CreateToggle({
        Name = "Instant Take",
        CurrentValue = true,
        Callback = function(v) config.instantTake = v end
    })

    -- Mud Nav Controls
    MudTab:CreateSlider({
        Name = "Tốc độ di chuyển",
        Range = {100, 1500}, Increment = 50, CurrentValue = 450,
        Callback = function(v) config.speed = v end
    })

    MudTab:CreateButton({Name = "⬆️ UP", Callback = function()
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local closest, minDist = 1, math.huge
        for i = 1, 9 do
            local m = GetGapCenter(i)
            if m then
                local d = (root.Position - m.Position).Magnitude
                if d < minDist then minDist = d; closest = i end
            end
        end
        if closest < 9 then ForcedCenterTP(GetGapCenter(closest + 1)) end
    end})

    MudTab:CreateButton({Name = "⬇️ DOWN", Callback = function()
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local closest, minDist = 1, math.huge
        for i = 1, 9 do
            local m = GetGapCenter(i)
            if m then
                local d = (root.Position - m.Position).Magnitude
                if d < minDist then minDist = d; closest = i end
            end
        end
        if closest > 1 then ForcedCenterTP(GetGapCenter(closest - 1)) end
    end})

    initInstantTake()
end

-- KEY SYSTEM
if isfile(KeyFileName) and readfile(KeyFileName) == CorrectKey then
    loadMainScript()
else
    local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    local Win = Rayfield:CreateWindow({Name = "CAT HUB | VERIFY"})
    local Tab = Win:CreateTab("Verify", 4483362458)
    Tab:CreateInput({
        Name = "Nhập Key",
        Callback = function(t)
            if t == CorrectKey then
                writefile(KeyFileName, t)
                Rayfield:Destroy()
                loadMainScript()
            end
        end
    })
end
