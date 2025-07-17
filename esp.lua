if game.Players.LocalPlayer.Name ~= "CeFaX" then return end -- Admin-only

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "RobloxGui" -- nom déguisé

-- === UI PRINCIPALE ===
local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0, 250, 0, 350)
mainFrame.Position = UDim2.new(0.01, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

local uiCorner = Instance.new("UICorner", mainFrame)
uiCorner.CornerRadius = UDim.new(0, 10)

-- === TOGGLE BUTTONS ===
local function createToggle(name, y, callback)
	local button = Instance.new("TextButton", mainFrame)
	button.Size = UDim2.new(1, -20, 0, 30)
	button.Position = UDim2.new(0, 10, 0, y)
	button.Text = name
	button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	
	local toggled = false
	button.MouseButton1Click:Connect(function()
		toggled = not toggled
		button.BackgroundColor3 = toggled and Color3.fromRGB(60, 100, 60) or Color3.fromRGB(40, 40, 40)
		callback(toggled)
	end)
end

-- === FOV INDICATEUR ===
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.new(1, 1, 1)
fovCircle.Radius = 150
fovCircle.Thickness = 1
fovCircle.Filled = false
fovCircle.Visible = true

RunService.RenderStepped:Connect(function()
	fovCircle.Position = UserInputService:GetMouseLocation()
end)

-- === VARIABLES ===
local ESP_ON = false
local CHAMS_ON = false
local SKELETON_ON = false
local SILENT_AIM = false
local FOV = 150
local TARGET_PART = "Head"

-- === SLIDER POUR FOV ===
local fovSlider = Instance.new("TextBox", mainFrame)
fovSlider.Size = UDim2.new(1, -20, 0, 30)
fovSlider.Position = UDim2.new(0, 10, 0, 280)
fovSlider.PlaceholderText = "FOV radius (ex: 150)"
fovSlider.TextColor3 = Color3.new(1, 1, 1)
fovSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
fovSlider.FocusLost:Connect(function()
	local value = tonumber(fovSlider.Text)
	if value and value > 0 and value <= 1000 then
		FOV = value
		fovCircle.Radius = value
	end
end)

-- === ESP / CHAMS ===
local function applyESP(plr)
	if plr == LocalPlayer then return end
	local esp = Drawing.new("Text")
	esp.Text = plr.Name
	esp.Color = Color3.new(1, 0, 0)
	esp.Size = 14
	esp.Center = true
	esp.Outline = true
	esp.Visible = false

	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not ESP_ON or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
			esp.Visible = false
			return
		end
		local pos, onscreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
		esp.Position = Vector2.new(pos.X, pos.Y - 30)
		esp.Visible = onscreen
	end)
end

local function updatePlayers()
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			applyESP(p)
		end
	end
end

Players.PlayerAdded:Connect(updatePlayers)
updatePlayers()

-- === SILENT AIM ===
local function getClosestTarget()
	local closest, dist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild(TARGET_PART) then
			local pos, onscreen = Camera:WorldToViewportPoint(plr.Character[TARGET_PART].Position)
			if onscreen then
				local mag = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
				if mag < FOV and mag < dist then
					closest = plr.Character[TARGET_PART]
					dist = mag
				end
			end
		end
	end
	return closest
end

local mt = getrawmetatable(game)
setreadonly(mt, false)
local __namecall = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
	local args = {...}
	if SILENT_AIM and tostring(self) == "HitPart" and getnamecallmethod() == "FireServer" then
		local target = getClosestTarget()
		if target then
			args[1] = target
			return __namecall(self, unpack(args))
		end
	end
	return __namecall(self, ...)
end)

-- === BOUTONS ===
createToggle("ESP", 20, function(state) ESP_ON = state end)
createToggle("Chams", 60, function(state) CHAMS_ON = state end)
createToggle("Skeleton", 100, function(state) SKELETON_ON = state end)
createToggle("Silent Aim", 140, function(state) SILENT_AIM = state end)