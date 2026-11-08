local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("[ESP] Script DBD (Anti-doublon de fenêtres) démarré !")

-- Configurations des Chams (Highlight)
local OBJECT_CONFIG = {
    ["vault"]     = { Fill = Color3.fromRGB(170, 0, 255),   Outline = Color3.fromRGB(255, 255, 255) }, -- Violet
    ["generator"] = { Fill = Color3.fromRGB(255, 170, 0),   Outline = Color3.fromRGB(255, 255, 255) }, -- Orange
    ["intact"]    = { Fill = Color3.fromRGB(0, 255, 128),  Outline = Color3.fromRGB(255, 255, 255) }  -- Vert
}

local KILLER_CONFIG   = { Fill = Color3.fromRGB(255, 0, 0),   Outline = Color3.fromRGB(255, 255, 255) } -- Rouge
local SURVIVOR_CONFIG = { Fill = Color3.fromRGB(0, 128, 255),  Outline = Color3.fromRGB(255, 255, 255) } -- Bleu

local MAX_VAULT_DISTANCE = 12 -- Distance max pour lier l'Inviswall au VaultTrigger
local MIN_WINDOW_SPACING = 15 -- Distance minimale obligatoire entre deux textes [ WINDOW ] pour éviter les doublons

-- Application sécurisée d'un Highlight
local function applyHighlight(target, config)
    if not target or (not target:IsA("Model") and not target:IsA("BasePart")) then return end
    if target:FindFirstChild("TargetHighlight") then return end

    pcall(function()
        local highlight = Instance.new("Highlight")
        highlight.Name = "TargetHighlight"
        highlight.FillColor = config.Fill
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = config.Outline
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = target
        highlight.Parent = target
    end)
end

-- Création sécurisée du texte permanent "WINDOW"
local function applyWindowText(target)
    if not target or target:FindFirstChild("WindowTextESP") then return end

    pcall(function()
        local adornTarget = target
        if target:IsA("Model") then
            adornTarget = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart") or target
        end
        if not adornTarget then return end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "WindowTextESP"
        billboard.Size = UDim2.new(0, 100, 0, 35)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 200
        billboard.Adornee = adornTarget
        billboard.Parent = target

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = "[ WINDOW ]"
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        textLabel.TextSize = 16
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.Parent = billboard
    end)
end

-- Récupération et fusion des positions des VaultTriggers (pour grouper les paires)
funcGetUniqueTriggers = function()
    local rawPositions = {}
    for _, desc in ipairs(workspace:GetDescendants()) do
        local name = desc.Name:lower()
        if name:find("vault") and name:find("trigger") or name:find("vaulttrigger") then
            local pos = nil
            if desc:IsA("BasePart") then
                pos = desc.Position
            elseif desc:IsA("Model") then
                pos = desc:GetPivot().Position
            end
            if pos then
                table.insert(rawPositions, pos)
            end
        end
    end

    -- Regroupe les triggers trop proches (les 2 côtés d'une même fenêtre) en une seule position centrale
    local uniqueTriggers = {}
    for _, pos in ipairs(rawPositions) do
        local isDuplicate = false
        for _, uPos in ipairs(uniqueTriggers) do
            if (pos - uPos).Magnitude < 6 then -- Si à moins de 6 studs, c'est le 2ème trigger de la même fenêtre
                isDuplicate = true
                break
            end
        end
        if not isDuplicate then
            table.insert(uniqueTriggers, pos)
        end
    end
    return uniqueTriggers
end

-- Traitement global ultra-fluide et anti-doublon de textes
task.spawn(function()
    local triggers = funcGetUniqueTriggers()
    local allDescendants = workspace:GetDescendants()
    local spawnedWindowPositions = {} -- Mémoire pour espacer les textes [ WINDOW ]
    
    for i = 1, #allDescendants do
        local obj = allDescendants[i]
        local name = obj.Name:lower()

        -- 1. Éléments de la map (Vault, Generator, Intact)
        local matched = false
        for keyword, config in pairs(OBJECT_CONFIG) do
            if name:find(keyword) then
                applyHighlight(obj, config)
                matched = true
                break
            end
        end

        -- 2. Inviswalls avec vérification stricte d'espacement anti-doublon
        if not matched and name:find("inviswall") then
            local pos = nil
            if obj:IsA("BasePart") then
                pos = obj.Position
            elseif obj:IsA("Model") then
                pos = obj:GetPivot().Position
            end

            if pos then
                -- Vérifie s'il est proche d'un VaultTrigger valide
                local isNearVault = false
                if #triggers == 0 then
                    isNearVault = true -- Fallback si la map n'a pas de trigger nommé explicitement
                else
                    for _, trigPos in ipairs(triggers) do
                        if (pos - trigPos).Magnitude <= MAX_VAULT_DISTANCE then
                            isNearVault = true
                            break
                        end
                    end
                end

                if isNearVault then
                    -- Vérifie qu'aucun autre texte [ WINDOW ] n'est déjà trop près de cette position
                    local tooClose = false
                    for _, existingPos in ipairs(spawnedWindowPositions) do
                        if (pos - existingPos).Magnitude < MIN_WINDOW_SPACING then
                            tooClose = true
                            break
                        end
                    end

                    if not tooClose then
                        table.insert(spawnedWindowPositions, pos)
                        applyWindowText(obj)
                    end
                end
            end
        end

        -- Pause pour garantir un jeu parfaitement fluide à 60 FPS constants
        if i % 50 == 0 then
            task.wait()
        end
    end
end)

-- Gestion propre des joueurs (Killer / Survivor)
local function setupPlayer(player)
    local function updateChar(char)
        if not char then return end
        local existing = char:FindFirstChild("TargetHighlight")
        if existing then existing:Destroy() end

        if player.Team then
            local tName = player.Team.Name:lower()
            if tName:find("killer") then
                applyHighlight(char, KILLER_CONFIG)
            elseif tName:find("survivor") then
                applyHighlight(char, SURVIVOR_CONFIG)
            end
        end
    end

    if player.Character then updateChar(player.Character) end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        updateChar(char)
    end)
    player:GetPropertyChangedSignal("Team"):Connect(function()
        if player.Character then updateChar(player.Character) end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then setupPlayer(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then setupPlayer(p) end
end)
