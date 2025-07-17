-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntiCheatUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local function createRoundedFrame(size, position, parent)
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    return frame
end

-- UI centrée
local mainFrame = createRoundedFrame(UDim2.new(0, 220, 0, 160), UDim2.new(0.5, -110, 0.5, -80), ScreenGui)

-- State variables
local espEnabled = false
local chamsEnabled = false
local aimbotEnabled = false
local uiVisible = true

-- Toggle buttons
local function createToggleButton(name, position, parent, toggleCallback)
    local btn = Instance.new("TextButton")
    btn.Text = name .. " OFF"
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.Position = position
    btn.BackgroundColor3 = Color3.new(0, 0, 0)
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 20
    btn.AutoButtonColor = false
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn

    local enabled = false

    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.Text = name .. (enabled and " ON" or " OFF")
        btn.BackgroundColor3 = enabled and Color3.fromRGB(50, 50, 50) or Color3.new(0, 0, 0)
        btn.BackgroundTransparency = enabled and 0 or 0.3
        btn.TextColor3 = enabled and Color3.fromRGB(0, 255, 100) or Color3.new(1, 1, 1)
        toggleCallback(enabled)
    end)
end

createToggleButton("ESP", UDim2.new(0, 20, 0, 10), mainFrame, function(state)
    espEnabled = state
    if not state then
        -- Clear all ESP when disabled
        for _, gui in pairs(espFolder:GetChildren()) do
            gui:Destroy()
        end
    end
end)

createToggleButton("Chams", UDim2.new(0, 20, 0, 60), mainFrame, function(state)
    chamsEnabled = state
    if not state then
        -- Remove all cham highlights on disable
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                local h = player.Character:FindFirstChild("ChamHighlight")
                if h then h:Destroy() end
            end
        end
    end
end)

createToggleButton("Aimbot", UDim2.new(0, 20, 0, 110), mainFrame, function(state)
    aimbotEnabled = state
end)

-- ESP Container
local espFolder = Instance.new("Folder", ScreenGui)
espFolder.Name = "ESPFolder"

-- Cache for ESP GUIs per character
local espCache = {}

local function isEnemy(player)
    return player.Team ~= localPlayer.Team
end

local function createESP(char)
    if espCache[char] then return espCache[char] end -- already created

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local esp = Instance.new("BillboardGui")
    esp.Adornee = root
    esp.Size = UDim2.new(0, 60, 0, 15)
    esp.AlwaysOnTop = true
    esp.Name = "ESPBox"
    esp.Parent = espFolder

    local label = Instance.new("TextLabel", esp)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = char.Name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14

    espCache[char] = esp
    return esp
end

local function removeESP(char)
    if espCache[char] then
        espCache[char]:Destroy()
        espCache[char] = nil
    end
end

local function applyChams(character, color)
    local highlight = character:FindFirstChild("ChamHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "ChamHighlight"
        highlight.Adornee = character
        highlight.Parent = character
    end
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local function removeChams(character)
    local h = character:FindFirstChild("ChamHighlight")
    if h then h:Destroy() end
end

-- Visual update throttle (10 FPS)
local lastUpdate = 0
local updateInterval = 0.1

RunService.RenderStepped:Connect(function(dt)
    lastUpdate = lastUpdate + dt
    if lastUpdate < updateInterval then return end
    lastUpdate = 0

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local char = player.Character
            local humanoid = char.Humanoid
            if humanoid.Health > 0 then
                -- ESP
                if espEnabled then
                    createESP(char)
                else
                    removeESP(char)
                end

                -- Chams
                if chamsEnabled then
                    local color = isEnemy(player) and Color3.fromRGB(255, 128, 0) or Color3.fromRGB(0, 128, 255)
                    applyChams(char, color)
                else
                    removeChams(char)
                end
            else
                -- Remove visuals if dead
                removeESP(char)
                removeChams(char)
            end
        else
            -- Cleanup for players without character or localPlayer
            if player.Character then
                removeESP(player.Character)
                removeChams(player.Character)
            end
        end
    end
end)

-- AIMBOT

local aiming = false
local fov = 90

local mousePos = Vector2.new()

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = true
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        uiVisible = not uiVisible
        ScreenGui.Enabled = uiVisible
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    end
end)

-- Cache mouse position once per frame
RunService.RenderStepped:Connect(function()
    mousePos = UserInputService:GetMouseLocation()
end)

local function getClosestEnemy()
    local closest = nil
    local minDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and isEnemy(player) then
            local char = player.Character
            local humanoid = char:FindFirstChild("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")

            if humanoid and humanoid.Health > 0 and root and head then
                local screenPos, onScreen = camera:WorldToScreenPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < minDist and dist <= fov then
                        closest = head
                        minDist = dist
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if aiming and aimbotEnabled then
        local target = getClosestEnemy()
        if target then
            local camPos = camera.CFrame.Position
            local dir = (target.Position - camPos).Unit
            camera.CFrame = CFrame.new(camPos, camPos + dir)
        end
    end
end)
