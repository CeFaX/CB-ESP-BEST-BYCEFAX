local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("[ESP] Script Chams avec Culling dynamique démarré !")

-- Configuration des éléments de la map en Chams (Highlight)
local OBJECT_CONFIG = {
    ["vault"]     = { Fill = Color3.fromRGB(170, 0, 255),   Outline = Color3.fromRGB(255, 255, 255) }, -- Violet
    ["generator"] = { Fill = Color3.fromRGB(255, 170, 0),   Outline = Color3.fromRGB(255, 255, 255) }, -- Orange
    ["intact"]    = { Fill = Color3.fromRGB(0, 255, 128),  Outline = Color3.fromRGB(255, 255, 255) }  -- Vert
}

-- Configuration spécifique pour les Inviswalls (gérés par distance)
local INVISWALL_CONFIG = { Fill = Color3.fromRGB(255, 255, 0), Outline = Color3.fromRGB(255, 255, 255) }
local MAX_INVISWALL_DISTANCE = 100 -- Distance maximale en studs pour afficher l'ESP de l'Inviswall

-- Configuration des équipes de joueurs
local KILLER_CONFIG   = { Fill = Color3.fromRGB(255, 0, 0),   Outline = Color3.fromRGB(255, 255, 255) } -- Rouge
local SURVIVOR_CONFIG = { Fill = Color3.fromRGB(0, 128, 255),  Outline = Color3.fromRGB(255, 255, 255) } -- Bleu

-- Application du Highlight (Chams traversant les murs)
local function applyHighlight(target, config)
    if not target:IsA("Model") and not target:IsA("BasePart") then return end
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

-- Traitement initial des éléments fixes (Vaults, Generators, Intacts)
local function processObject(obj)
    local objNameLower = obj.Name:lower():gsub("%s+", "")

    for keyword, config in pairs(OBJECT_CONFIG) do
        if objNameLower:find(keyword) then
            applyHighlight(obj, config)
            break
        end
    end
end

-- Gestion des joueurs
local function setupPlayer(player)
    local function checkTeamAndHighlight(character)
        if not character then return end
        
        local existing = character:FindFirstChild("TargetHighlight")
        if existing then existing:Destroy() end

        if player.Team then
            local teamName = player.Team.Name:lower()
            if teamName:find("killer") then
                applyHighlight(character, KILLER_CONFIG)
            elseif teamName:find("survivor") then
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

-- 1. Scan initial sécurisé pour la map fixe
task.spawn(function()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        processObject(descendant)
        task.wait()
    end
end)

-- 2. Détection dynamique des nouveaux objets fixes
workspace.DescendantAdded:Connect(function(descendant)
    processObject(descendant)
end)

-- 3. Boucle de gestion intelligente par distance pour les Inviswalls (contourne la limite de 31)
task.spawn(function()
    while task.wait(0.5) do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            local hrpPos = hrp.Position
            for _, descendant in ipairs(workspace:GetDescendants()) do
                if descendant:IsA("BasePart") and descendant.Name:lower():gsub("%s+", ""):find("inviswall") then
                    local distance = (descendant.Position - hrpPos).Magnitude
                    local existing = descendant:FindFirstChild("TargetHighlight")

                    if distance <= MAX_INVISWALL_DISTANCE then
                        if not existing then
                            applyHighlight(descendant, INVISWALL_CONFIG)
                        end
                    else
                        if existing then
                            existing:Destroy() -- Libère le slot de Highlight quand tu t'éloignes
                        end
                    end
                end
            end
        end
    end
end)

-- 4. Application aux joueurs
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
