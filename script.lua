local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

WindUI:Gradient({                                                      
    ["0"] = { Color = Color3.fromHex("#1f1f23"), Transparency = 0 },            
    ["100"]   = { Color = Color3.fromHex("#18181b"), Transparency = 0 },      
}, {                                                                            
    Rotation = 0,                                                               
})

WindUI:SetTheme("My Theme")

local Window = WindUI:CreateWindow({
    Title = "Lavender Hub",
    Icon = "flower",
    Author = "made by 2lev1/sal",
    Folder = "LavenderHub",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    Theme = "Dark",
    Resizable = true,
    User = {
        Enabled = true,
        Anonymous = true,
        Callback = function()
            print("Clicked user profile")
        end,
    },
})

Window:Tag({
    Title = "Discord",
    Icon = "lucide:discord",
    Color = Color3.fromHex("#5865F2"),
    Callback = function()
        setclipboard("https://discord.gg/g52ce8vSa")
        WindUI:Notify({
            Title = "Discord Server",
            Content = "Discord link copied to clipboard!",
            Duration = 3,
            Icon = "lucide:check",
        })
    end
})

Window:Divider()

local AutofarmTab = Window:Tab({
    Title = "Autofarm",
    Icon = "coins",
})
AutofarmTab:Select()

local AutoFarmEnabled = false
local CurrentSpeed = 10
local isRunning = false
local visitedCoins = {}
local hasReset = false

local speedOptions = {}
for i = 1, 12 do
    local speed = 1 + ((i - 1) * 2)
    if speed > 23 then speed = 23 end
    speedOptions[i] = tostring(speed) .. " studs/sec"
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character, humanoidRootPart, humanoid

local function initializeCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
    humanoid = character:WaitForChild("Humanoid", 5)
    return character, humanoidRootPart, humanoid
end

local mapPaths = {
    "IceCastle",
    "SkiLodge",
    "Station",
    "LogCabin",
    "Bank2",
    "BioLab",
    "House2",
    "Factory",
    "Hospital3",
    "Hotel",
    "Mansion2",
    "MilBase",
    "Office3",
    "PoliceStation",
    "Workplace",
    "ResearchFacility",
    "ChristmasItaly"
}

local function findActiveCoinContainer()
    for _, mapName in ipairs(mapPaths) do
        local map = Workspace:FindFirstChild(mapName)
        if map then
            local coinContainer = map:FindFirstChild("CoinContainer")
            if coinContainer then
                return coinContainer
            end
        end
    end
    return nil
end

local function findNearestCoin(coinContainer)
    if not humanoidRootPart then return nil end
    
    local nearestCoin = nil
    local shortestDistance = math.huge

    if coinContainer then
        for _, coin in ipairs(coinContainer:GetChildren()) do
            if coin:IsA("BasePart") and not visitedCoins[coin] then
                local distance = (humanoidRootPart.Position - coin.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestCoin = coin
                end
            end
        end
    end

    return nearestCoin
end

local function tweenToCoin(coin)
    if not coin or not humanoidRootPart then
        return
    end
    
    visitedCoins[coin] = true
    
    local SPEED = CurrentSpeed
    local TARGET_HEIGHT = 3
    local ANTI_FLING_FORCE = Vector3.new(0, -5, 0)
    
    local startPos = humanoidRootPart.Position
    local targetPos = Vector3.new(
        coin.Position.X,
        coin.Position.Y + TARGET_HEIGHT,
        coin.Position.Z
    )
    local originalLookVector = humanoidRootPart.CFrame.LookVector
    
    local directDistance = (startPos - targetPos).Magnitude
    local duration = directDistance / SPEED
    
    humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
    humanoid.AutoRotate = false
    
    if humanoidRootPart:FindFirstChild("MovementActive") then
        humanoidRootPart.MovementActive:Destroy()
    end
    
    local movementTracker = Instance.new("BoolValue")
    movementTracker.Name = "MovementActive"
    movementTracker.Parent = humanoidRootPart
    
    local startTime = tick()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not movementTracker.Parent then
            connection:Disconnect()
            return
        end
        
        local progress = math.min((tick() - startTime) / duration, 1)
        local currentPos = startPos + (targetPos - startPos) * progress
        
        currentPos = Vector3.new(
            currentPos.X,
            startPos.Y + (targetPos.Y - startPos.Y) * progress,
            currentPos.Z
        )
        
        humanoidRootPart.CFrame = CFrame.new(currentPos, currentPos + originalLookVector)
        
        humanoidRootPart.Velocity = progress > 0.9 and ANTI_FLING_FORCE or Vector3.new(0, math.min(humanoidRootPart.Velocity.Y, 0), 0)
        
        if progress >= 1 then
            connection:Disconnect()
            movementTracker:Destroy()
            humanoid.AutoRotate = true
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
            
            local currentOrientation = humanoidRootPart.CFrame.Rotation
            humanoidRootPart.CFrame = CFrame.new(
                coin.Position.X,
                coin.Position.Y + TARGET_HEIGHT,
                coin.Position.Z
            ) * currentOrientation
            
            humanoidRootPart.Velocity = Vector3.zero
            task.wait(0.1)
            humanoidRootPart.Velocity = Vector3.zero
        end
    end)
    
    if character then
        character.AncestryChanged:Connect(function()
            if not character.Parent then
                connection:Disconnect()
                if movementTracker.Parent then 
                    movementTracker:Destroy() 
                end
            end
        end)
    end
    
    task.wait(duration + 0.2)
end

local function checkForAllCoinVisualsGone()
    local coinContainer = findActiveCoinContainer()

    if coinContainer then
        local allCoinVisualsGone = true

        for _, coin in ipairs(coinContainer:GetChildren()) do
            if coin:IsA("BasePart") then
                local coinVisual = coin:FindFirstChild("CoinVisual")
                if coinVisual then
                    allCoinVisualsGone = false
                    break
                end
            end
        end

        if allCoinVisualsGone and not hasReset then
            if character then
                character:BreakJoints()
            end
            visitedCoins = {}
            hasReset = true
            task.wait(1)
        end

        if allCoinVisualsGone then
            isRunning = false
        end
    end
end

local function playFallingAnimation()
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
    end
end

local function collectCoins()
    while isRunning and AutoFarmEnabled do
        if not character or not humanoidRootPart or not humanoid or not character.Parent then
            character, humanoidRootPart, humanoid = initializeCharacter()
        end

        local coinContainer = findActiveCoinContainer()
        if not coinContainer then
            task.wait(1)
            continue
        end

        local targetCoin = findNearestCoin(coinContainer)
        if not targetCoin then
            checkForAllCoinVisualsGone()
            task.wait(0.5)
            continue
        end

        checkForAllCoinVisualsGone()
        if not isRunning then break end

        tweenToCoin(targetCoin)

        playFallingAnimation()

        checkForAllCoinVisualsGone()

        task.wait(0.1)
    end
end

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    hasReset = false
    
    if AutoFarmEnabled and isRunning then
        task.wait(1)
        coroutine.wrap(function()
            character, humanoidRootPart, humanoid = initializeCharacter()
        end)()
    end
end)
local AutofarmSection = AutofarmTab:Section({
    Title = "Coin Autofarm",
    Icon = "zap",
    Opened = true,
})

local AutofarmToggle = AutofarmSection:Toggle({
    Title = "Enable Autofarm",
    Desc = "Automatically collects coins",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        AutoFarmEnabled = state
        
        if state then
            isRunning = true
            hasReset = false
            visitedCoins = {}
            
            character, humanoidRootPart, humanoid = initializeCharacter()
            
            WindUI:Notify({
                Title = "Autofarm",
                Content = "Coin autofarm enabled!",
                Duration = 3,
                Icon = "play",
            })
            
            coroutine.wrap(collectCoins)()
        else
            isRunning = false
            WindUI:Notify({
                Title = "Autofarm",
                Content = "Coin autofarm disabled!",
                Duration = 3,
                Icon = "pause",
            })
        end
    end
})

local SpeedDropdown = AutofarmSection:Dropdown({
    Title = "Tween Speed",
    Desc = "Select movement speed (max: 23 studs/sec)",
    Values = speedOptions,
    Value = "10 studs/sec",
    Callback = function(option)
        CurrentSpeed = tonumber(option:match("%d+"))
        WindUI:Notify({
            Title = "Speed Changed",
            Content = "Tween speed set to " .. CurrentSpeed .. " studs/sec",
            Duration = 3,
            Icon = "gauge",
        })
    end
})

local StatusLabel = AutofarmSection:Paragraph({
    Title = "Status: Inactive",
    Desc = "Autofarm is currently disabled",
    Color = "Red",
})

coroutine.wrap(function()
    while true do
        task.wait(1)
        if AutofarmToggle and StatusLabel then
            if AutoFarmEnabled and isRunning then
                StatusLabel:SetTitle("Status: Active (Speed: " .. CurrentSpeed .. " studs/sec)")
                StatusLabel:SetDesc("Collecting coins...")
                StatusLabel.Color = "Green"
            else
                StatusLabel:SetTitle("Status: Inactive")
                StatusLabel:SetDesc("Autofarm is currently disabled")
                StatusLabel.Color = "Red"
            end
        end
    end
end)()

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESP Holder"
ESPFolder.Parent = game.CoreGui

local function AddBillboard(player)
    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = player.Name .. "Billboard"
    Billboard.AlwaysOnTop = true
    Billboard.Size = UDim2.new(0, 200, 0, 50)
    Billboard.ExtentsOffset = Vector3.new(0, 3, 0)
    Billboard.Enabled = false
    Billboard.Parent = ESPFolder

    local TextLabel = Instance.new("TextLabel")
    TextLabel.TextSize = 20
    TextLabel.Text = player.Name
    TextLabel.Font = Enum.Font.FredokaOne
    TextLabel.BackgroundTransparency = 1
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.TextStrokeTransparency = 0
    TextLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    TextLabel.Parent = Billboard

    repeat
        wait()
        pcall(function()
            Billboard.Adornee = player.Character.Head
            if player.Character:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife") then
                TextLabel.TextColor3 = Color3.new(1, 0, 0)
                if getgenv().MurderEsp then
                    Billboard.Enabled = true
                end
            elseif player.Character:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun") then
                TextLabel.TextColor3 = Color3.new(0, 0, 1)
                if getgenv().SheriffEsp then
                    Billboard.Enabled = true
                end
            else
                TextLabel.TextColor3 = Color3.new(0, 1, 0)
                if getgenv().AllEsp then
                    Billboard.Enabled = true
                end
            end
        end)
    until not player.Parent
end

for _, player in pairs(game.Players:GetPlayers()) do
    if player ~= game.Players.LocalPlayer then
        coroutine.wrap(AddBillboard)(player)
    end
end

game.Players.PlayerAdded:Connect(function(player)
    if player ~= game.Players.LocalPlayer then
        coroutine.wrap(AddBillboard)(player)
    end
end)

game.Players.PlayerRemoving:Connect(function(player)
    local billboard = ESPFolder:FindFirstChild(player.Name .. "Billboard")
    if billboard then
        billboard:Destroy()
    end
end)

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "sword",
})

local ESPSection = MainTab:Section({
    Title = "ESP",
    Icon = "eye",
    Opened = true,
})

local AllESP = ESPSection:Toggle({
    Title = "Every Player ESP",
    Desc = "Shows ESP for all players",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        getgenv().AllEsp = state
        for _, billboard in ipairs(ESPFolder:GetChildren()) do
            if billboard:IsA("BillboardGui") then
                local playerName = billboard.Name:sub(1, -10)
                local player = game.Players:FindFirstChild(playerName)
                if player and player.Character then
                    local hasKnife = player.Character:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife")
                    local hasGun = player.Character:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun")
                    if not (hasKnife or hasGun) then
                        billboard.Enabled = state
                    end
                end
            end
        end
    end
})

local MurderESP = ESPSection:Toggle({
    Title = "Murderer ESP",
    Desc = "Shows ESP for murderer",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        getgenv().MurderEsp = state
        for _, billboard in ipairs(ESPFolder:GetChildren()) do
            if billboard:IsA("BillboardGui") then
                local playerName = billboard.Name:sub(1, -10)
                local player = game.Players:FindFirstChild(playerName)
                if player and (player.Character:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife")) then
                    billboard.Enabled = state
                end
            end
        end
    end
})

local SheriffESP = ESPSection:Toggle({
    Title = "Sheriff ESP",
    Desc = "Shows ESP for sheriff",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        getgenv().SheriffEsp = state
        for _, billboard in ipairs(ESPFolder:GetChildren()) do
            if billboard:IsA("BillboardGui") then
                local playerName = billboard.Name:sub(1, -10)
                local player = game.Players:FindFirstChild(playerName)
                if player and (player.Character:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun")) then
                    billboard.Enabled = state
                end
            end
        end
    end
})

local RoleSection = MainTab:Section({
    Title = "Role Information",
    Icon = "user",
    Opened = true,
})

local MurdererLabel = RoleSection:Paragraph({
    Title = "Murderer is: Unknown",
    Desc = "Detecting murderer...",
    Color = "Red",
})

local SheriffLabel = RoleSection:Paragraph({
    Title = "Sheriff is: Unknown",
    Desc = "Detecting sheriff...",
    Color = "Blue",
})

local GunLabel = RoleSection:Paragraph({
    Title = "Gun Not Dropped",
    Desc = "Waiting for gun drop...",
    Color = "Green",
})

local function updateRolesInfo()
    while true do
        task.wait(1)
        local players = game:GetService("Players"):GetPlayers()
        local murderer, sheriff = "Unknown", "Unknown"

        for _, player in ipairs(players) do
            if player.Character then
                local backpack = player.Backpack
                if backpack then
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if tool:IsA("Tool") then
                            if tool.Name == "Knife" then
                                murderer = player.Name
                            elseif tool.Name == "Gun" then
                                sheriff = player.Name
                            end
                        end
                    end
                end
            end
        end

        if MurdererLabel then
            MurdererLabel:SetTitle("Murderer is: " .. murderer)
        end
        if SheriffLabel then
            SheriffLabel:SetTitle("Sheriff is: " .. sheriff)
        end
    end
end

coroutine.wrap(updateRolesInfo)()

coroutine.wrap(function()
    local gunDropped = false
    while true do
        task.wait(1)
        local gunExists = Workspace:FindFirstChild("GunDrop")
        
        if gunExists then
            if GunLabel then
                GunLabel:SetTitle("Gun Dropped")
                GunLabel:SetDesc("Gun is currently dropped in the map")
                GunLabel.Color = "Yellow"
            end
            
            if not gunDropped then
                gunDropped = true
                WindUI:Notify({
                    Title = "Gun Status",
                    Content = "Gun has been dropped!",
                    Duration = 5,
                    Icon = "alert-circle",
                })
            end
        else
            if GunLabel then
                GunLabel:SetTitle("Gun Not Dropped")
                GunLabel:SetDesc("Waiting for gun drop...")
                GunLabel.Color = "Green"
            end
            gunDropped = false
        end
    end
end)()

local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "settings",
})

local MiscSection = MiscTab:Section({
    Title = "Features",
    Icon = "zap",
    Opened = true,
})

MiscSection:Button({
    Title = "Get Gun",
    Desc = "Attempt to get the gun",
    Callback = function()
        local gunDrop = Workspace:FindFirstChild("GunDrop")
        if gunDrop then
            local char = game.Players.LocalPlayer.Character
            if char then
                local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    humanoidRootPart.CFrame = gunDrop.CFrame
                    WindUI:Notify({
                        Title = "Get Gun",
                        Content = "Teleported to gun!",
                        Duration = 3,
                        Icon = "target",
                    })
                end
            end
        else
            WindUI:Notify({
                Title = "Get Gun",
                Content = "Gun not found in workspace",
                Duration = 3,
                Icon = "x-circle",
            })
        end
    end
})

MiscSection:Button({
    Title = "Expose Roles in Chat",
    Desc = "Reveal murderer and sheriff in chat",
    Callback = function()
        local allPlayers = game.Players:GetPlayers()

        for _, player in pairs(allPlayers) do
            local backpack = player:FindFirstChild("Backpack")
            
            if backpack then
                if backpack:FindFirstChild("Knife") then
                    local args = {
                        [1] = player.Name .. ": Has The Knife",
                        [2] = "normalchat"
                    }

                    game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest"):FireServer(unpack(args))
                end
                
                if backpack:FindFirstChild("Gun") then
                    local args = {
                        [1] = player.Name .. ": Has The Gun",
                        [2] = "normalchat"
                    }

                    game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest"):FireServer(unpack(args))
                end
            end
        end
        
        WindUI:Notify({
            Title = "Roles Exposed",
            Content = "Murderer and Sheriff revealed in chat",
            Duration = 3,
            Icon = "message-square",
        })
    end
})

WindUI:Notify({
    Title = "Lavender Hub",
    Content = "Successfully loaded! Made by 2lev1/sal",
    Duration = 5,
    Icon = "flower",
})

character, humanoidRootPart, humanoid = initializeCharacter()
