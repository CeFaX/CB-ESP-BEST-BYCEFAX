local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configuration des couleurs pour les éléments du décor
local OBJECT_CONFIG = {
    ["Intact"]    = { Fill = Color3.fromRGB(0, 255, 128),  Outline = Color3.fromRGB(255, 255, 255) }, -- Vert
    ["Generator"] = { Fill = Color3.fromRGB(255, 170, 0),   Outline = Color3.fromRGB(255, 255, 0) },   -- Orange
    ["Vault"]     = { Fill = Color3.fromRGB(170, 0, 255),   Outline = Color3.fromRGB(255, 255, 255) }, -- Violet
    ["Window"]    = { Fill = Color3.fromRGB(0, 170, 255),   Outline = Color3.fromRGB(255, 255, 255) }  -- Bleu
}

-- Configuration des couleurs pour les équipes de joueurs
local KILLER_CONFIG  = { Fill = Color3.fromRGB(255, 0, 0),   Outline = Color3.fromRGB(255, 255, 255) } -- Rouge
local SURVIVOR_CONFIG = { Fill = Color3.fromRGB(0, 128, 255),  Outline = Color3.fromRGB(255, 255, 255) } -- Bleu

-- Fonction générique pour appliquer un Chams (Highlight)
local function applyHighlight(target, config)
    if target:FindFirstChild("TargetHighlight") then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "TargetHighlight"
    highlight.FillColor = config.Fill
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = config.Outline
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = target
    highlight.Parent = target
end

-- Traitement des objets du décor
local function processModel(model)
    if not model:IsA("Model") then return end

    for keyword, config in pairs(OBJECT_CONFIG) do
        if model.Name:find(keyword) then
            applyHighlight(model, config)
            break
        end
    end
end

-- Gestion des équipes de joueurs (Killer & Survivors)
local function setupPlayer(player)
    local function checkTeamAndHighlight(character)
        if not character then return end
        
        -- Retire l'ancien highlight s'il existe pour éviter les conflits lors d'un changement d'équipe
        local existing = character:FindFirstChild("TargetHighlight")
        if existing then existing:Destroy() end

        if player.Team then
            local teamName = player.Team.Name
            if teamName:find("Killer") then
                applyHighlight(character, KILLER_CONFIG)
            elseif teamName:find("Survivor") then
                applyHighlight(character, SURVIVOR_CONFIG)
            end
        end
    end

    if player.Character then
        checkTeamAndHighlight(player.Character)
    end

    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        checkTeamAndHighlight(char)
    end)

    player:GetPropertyChangedSignal("Team"):Connect(function()
        if player.Character then
            checkTeamAndHighlight(player.Character)
        end
    end)
end

-- 1. Scan initial du workspace
for _, descendant in ipairs(workspace:GetDescendants()) do
    processModel(descendant)
end

-- 2. Détection dynamique des objets du décor
workspace.DescendantAdded:Connect(function(descendant)
    processModel(descendant)
end)

-- 3. Application aux joueurs actuels et futurs
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        setupPlayer(p)
    end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        setupPlayer(p)
    end
end)
