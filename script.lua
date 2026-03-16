-- KEEK DUEL HUB (FULL)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local lp = Players.LocalPlayer
local PlayerGui = lp:WaitForChild("PlayerGui")

-- SETTINGS

local grabRadius = 25
local MELEE_RANGE = 45
local SPEED_VALUE = 57

-- AUTO MOVE SETTINGS
local NORMAL_SPEED = 50

local POSITION_L1 = Vector3.new(-10,0,20)
local POSITION_L2 = Vector3.new(-20,0,40)

local POSITION_R1 = Vector3.new(10,0,20)
local POSITION_R2 = Vector3.new(20,0,40)

local autoLeftConnection
local autoRightConnection
local autoLeftPhase = 1
local autoRightPhase = 1

local antiRagdollEnabled = false
local autoBatEnabled = false
local autoStealEnabled = false
local meleeEnabled = false
local speedEnabled = false
local autoLeft = false
local autoRight = false

_G.EgoInfJumpOn = false

--------------------------------------------------
-- AUTO STEAL
--------------------------------------------------

local autoStealEnabled = false
local autoStealThread

local function findNearestSteal(root)

    local nearest
    local dist = math.huge

    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Enabled and v.ActionText == "Steal" then

            local part = v.Parent:IsA("BasePart") and v.Parent or v:FindFirstAncestorWhichIsA("BasePart")

            if part then
                local d = (part.Position - root.Position).Magnitude

                if d < dist and d <= grabRadius then
                    dist = d
                    nearest = v
                end
            end
        end
    end

    return nearest
end

local function startAutoSteal()

    if autoStealThread then return end

    autoStealThread = task.spawn(function()

        while autoStealEnabled do

            local char = lp.Character
            if char then

                local root = char:FindFirstChild("HumanoidRootPart")

                if root then
                    local prompt = findNearestSteal(root)

                    if prompt then
                        pcall(fireproximityprompt,prompt)
                        task.wait(0.05)
                        pcall(fireproximityprompt,prompt)
                    end
                end
            end

            task.wait(0.2)

        end

        autoStealThread = nil
    end)

end

function ToggleAutoSteal(state)

    autoStealEnabled = state

    if state then
        startAutoSteal()
    end

end
--------------------------------------------------
-- NEW MOVEMENT / COMBAT
--------------------------------------------------

local combatEnabled = false
local combatConnection

local function getClosestEnemy()

    local closest
    local dist = math.huge

    local char = lp.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _,p in pairs(Players:GetPlayers()) do
        if p ~= lp then

            local c = p.Character
            if c then

                local root = c:FindFirstChild("HumanoidRootPart")
                local hum = c:FindFirstChildOfClass("Humanoid")

                if root and hum and hum.Health > 0 then

                    local d = (root.Position - hrp.Position).Magnitude

                    if d < dist then
                        dist = d
                        closest = root
                    end

                end
            end
        end
    end

    return closest
end


function ToggleCombat(state)

    combatEnabled = state

    if state then

        combatConnection = RunService.Heartbeat:Connect(function()

            local char = lp.Character
            if not char then return end

            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local target = getClosestEnemy()

            if target then

                local look = CFrame.lookAt(root.Position, Vector3.new(
                    target.Position.X,
                    root.Position.Y,
                    target.Position.Z
                ))

                root.CFrame = look

            end

        end)

    else

        if combatConnection then
            combatConnection:Disconnect()
        end

    end

end
--------------------------------------------------
-- SPEED / CARRY SPEED
--------------------------------------------------

local speedEnabled = false
local normalSpeed = 60
local carrySpeed = 30

local speedConnection

function ToggleSpeed(state)

    speedEnabled = state

    if state then

        speedConnection = RunService.Heartbeat:Connect(function()

            local char = lp.Character
            if not char then return end

            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end

            local carrying = char:FindFirstChild("Carry") ~= nil

            if carrying then
                hum.WalkSpeed = carrySpeed
            else
                hum.WalkSpeed = normalSpeed
            end

        end)

    else

        if speedConnection then
            speedConnection:Disconnect()
        end

    end

end
--------------------------------------------------
-- SPEED BOOST
--------------------------------------------------

local speedConnection

function ToggleSpeed(state)

speedEnabled = state

if state then

speedConnection = RunService.Heartbeat:Connect(function()

local char = lp.Character
if not char then return end

local hrp = char:FindFirstChild("HumanoidRootPart")
local hum = char:FindFirstChildOfClass("Humanoid")

if not hrp or not hum then return end

local moveDir = hum.MoveDirection

if moveDir.Magnitude > 0 then

local vel = moveDir * SPEED_VALUE

hrp.AssemblyLinearVelocity = Vector3.new(
vel.X,
hrp.AssemblyLinearVelocity.Y,
vel.Z
)

end

end)

else

if speedConnection then
speedConnection:Disconnect()
end

end

end

--------------------------------------------------
-- AUTO BAT
--------------------------------------------------

local autoBatEnabled = false

local function getClosestPlayer()

    local closest
    local dist = math.huge

    local char = lp.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _,p in pairs(Players:GetPlayers()) do
        if p ~= lp then

            local c = p.Character
            if c then

                local root = c:FindFirstChild("HumanoidRootPart")
                local hum = c:FindFirstChildOfClass("Humanoid")

                if root and hum and hum.Health > 0 then

                    local d = (root.Position - hrp.Position).Magnitude

                    if d < dist then
                        dist = d
                        closest = p
                    end

                end
            end
        end
    end

    return closest, dist
end

RunService.Heartbeat:Connect(function()

    if not autoBatEnabled then return end

    local target, dist = getClosestPlayer()

    if target and dist and dist < 7 then
        mouse1click()
    end

end)

function ToggleAutoBat(state)
    autoBatEnabled = state
end
--------------------------------------------------
-- AUTO STEAL PATH SYSTEM (L1 -> L2 -> R1 -> R2)
--------------------------------------------------

local GO_SPEED = 57
local RETURN_SPEED = 29

local POSITION_L1 = Vector3.new(-476.48, -6.28, 92.73)
local POSITION_L2 = Vector3.new(-483.12, -4.95, 94.80)

local POSITION_R1 = Vector3.new(-476.16, -6.52, 25.62)
local POSITION_R2 = Vector3.new(-483.04, -5.09, 23.14)

local autoPathEnabled = false
local autoMoveConn
local phase = 1

local positions = {
    POSITION_L1,
    POSITION_L2,
    POSITION_R1,
    POSITION_R2
}

local function startAutoPath()

    if autoMoveConn then return end

    autoMoveConn = RunService.Heartbeat:Connect(function()

        if not autoPathEnabled then return end

        local char = lp.Character
        if not char then return end

        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")

        if not root or not hum then return end

        local target = positions[phase]

        local direction = (target - root.Position)
        local move = Vector3.new(direction.X,0,direction.Z).Unit

        hum:Move(move,false)

        root.AssemblyLinearVelocity = Vector3.new(
            move.X * GO_SPEED,
            root.AssemblyLinearVelocity.Y,
            move.Z * GO_SPEED
        )

        -- reached point
        if (target - root.Position).Magnitude < 2 then

            -- when reaching L2 -> steal
            if phase == 2 then

                local prompt = findNearestSteal(root)
                if prompt then
                    pcall(fireproximityprompt,prompt)
                    task.wait(0.1)
                    pcall(fireproximityprompt,prompt)
                end

            end

            phase += 1

            if phase > 4 then
                phase = 1
            end

        end

    end)

end

function ToggleAutoPath(state)

    autoPathEnabled = state
    phase = 1

    if state then
        startAutoPath()
    else
        if autoMoveConn then
            autoMoveConn:Disconnect()
            autoMoveConn = nil
        end
    end

end

--------------------------------------------------
-- INFINITE JUMP
--------------------------------------------------

local IJF, IJC = 50, 80

RunService.Heartbeat:Connect(function()

if not _G.EgoInfJumpOn then return end

local char = lp.Character
if not char then return end

local hrp = char:FindFirstChild("HumanoidRootPart")
if not hrp then return end

if hrp.AssemblyLinearVelocity.Y < -IJC then
hrp.AssemblyLinearVelocity = Vector3.new(
hrp.AssemblyLinearVelocity.X,
-IJC,
hrp.AssemblyLinearVelocity.Z
)
end

end)

UIS.JumpRequest:Connect(function()

if not _G.EgoInfJumpOn then return end

local char = lp.Character
if not char then return end

local hrp = char:FindFirstChild("HumanoidRootPart")
if not hrp then return end

hrp.AssemblyLinearVelocity = Vector3.new(
hrp.AssemblyLinearVelocity.X,
IJF,
hrp.AssemblyLinearVelocity.Z
)

end)

function ToggleInfJump(state)
_G.EgoInfJumpOn = state
end

--------------------------------------------------
-- ANTI RAGDOLL
--------------------------------------------------

local antiRagdollEnabled = false

RunService.Heartbeat:Connect(function()

    if not antiRagdollEnabled then return end

    local char = lp.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    if not hum then return end

    local state = hum:GetState()

    if state == Enum.HumanoidStateType.Ragdoll
    or state == Enum.HumanoidStateType.FallingDown
    or state == Enum.HumanoidStateType.Physics then

        hum:ChangeState(Enum.HumanoidStateType.GettingUp)

        if root then
            root.Velocity = Vector3.new(0,0,0)
            root.RotVelocity = Vector3.new(0,0,0)
        end
    end

end)

function ToggleAntiRagdoll(state)
    antiRagdollEnabled = state
end
--------------------------------------------------
-- SHINY GRAPHICS
--------------------------------------------------

local Lighting = game:GetService("Lighting")
local shinyEnabled = false
local shinyConn
local shinyBloom
local shinyCC

function ToggleShinyGraphics(state)

    shinyEnabled = state

    if state then

        shinyBloom = Instance.new("BloomEffect")
        shinyBloom.Intensity = 1.5
        shinyBloom.Size = 24
        shinyBloom.Parent = Lighting

        shinyCC = Instance.new("ColorCorrectionEffect")
        shinyCC.Saturation = 0.25
        shinyCC.Contrast = 0.2
        shinyCC.Parent = Lighting

        shinyConn = game:GetService("RunService").Heartbeat:Connect(function()
            local t = tick()*0.5
            Lighting.Ambient = Color3.fromRGB(
                100 + math.sin(t)*30,
                100 + math.sin(t*0.8)*30,
                110 + math.sin(t*1.2)*30
            )
        end)

    else

        if shinyConn then shinyConn:Disconnect() end
        if shinyBloom then shinyBloom:Destroy() end
        if shinyCC then shinyCC:Destroy() end

        Lighting.Ambient = Color3.fromRGB(127,127,127)

    end

end

--------------------------------------------------
-- OPTIMIZER + XRAY
--------------------------------------------------

local optimizerEnabled = false

function ToggleOptimizer(state)

    optimizerEnabled = state

    for _,v in pairs(workspace:GetDescendants()) do

        if v:IsA("BasePart") then

            if state then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            else
                v.Material = Enum.Material.Plastic
            end

        end

    end

end

--------------------------------------------------
-- FLOAT
--------------------------------------------------

local floatEnabled = false
local floatConn
local floatHeight = 10

function ToggleFloat(state)

    floatEnabled = state

    if state then

        floatConn = RunService.Heartbeat:Connect(function()

            local char = lp.Character
            if not char then return end

            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            root.AssemblyLinearVelocity = Vector3.new(
                root.AssemblyLinearVelocity.X,
                0,
                root.AssemblyLinearVelocity.Z
            )

            root.CFrame = root.CFrame + Vector3.new(0,floatHeight*0.01,0)

        end)

    else

        if floatConn then
            floatConn:Disconnect()
        end

    end

end
--------------------------------------------------
-- UNWALK
--------------------------------------------------

local unwalkEnabled = false
local unwalkConn

function ToggleUnwalk(state)

    unwalkEnabled = state

    if state then

        unwalkConn = RunService.Heartbeat:Connect(function()

            local char = lp.Character
            if not char then return end

            local hum = char:FindFirstChildOfClass("Humanoid")

            if hum then
                hum.WalkSpeed = 0
            end

        end)

    else

        if unwalkConn then
            unwalkConn:Disconnect()
        end

        local char = lp.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 16
            end
        end

    end

end
--------------------------------------------------
-- SPINBOT
--------------------------------------------------

local spinbotEnabled = false
local spinConn

function ToggleSpinbot(state)

    spinbotEnabled = state

    if state then

        spinConn = RunService.Heartbeat:Connect(function()

            local char = lp.Character
            if not char then return end

            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(60), 0)

        end)

    else

        if spinConn then
            spinConn:Disconnect()
        end

    end

end
--------------------------------------------------
-- AUTO TP WHEN RAGDOLL
--------------------------------------------------

local autoTPEnabled = false
local safePos = Vector3.new(0,10,0)

RunService.Heartbeat:Connect(function()

    if not autoTPEnabled then return end

    local char = lp.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    if not hum or not root then return end

    if hum:GetState() == Enum.HumanoidStateType.Ragdoll then
        root.CFrame = CFrame.new(safePos)
    end

end)

function ToggleAutoTP(state)
    autoTPEnabled = state
end
--------------------------------------------------
-- UI / GUI
--------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "KeekHubUI"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

-- MAIN FRAME
local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0,260,0,300)
frame.Position = UDim2.new(0.5,-130,0.5,-150)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

-- CORNERS
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,8)
corner.Parent = frame

-- TITLE BAR
local titleBar = Instance.new("Frame")
titleBar.Parent = frame
titleBar.Size = UDim2.new(1,0,0,35)
titleBar.BackgroundColor3 = Color3.fromRGB(35,35,35)
titleBar.BorderSizePixel = 0

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0,8)
titleCorner.Parent = titleBar

-- TITLE TEXT
local title = Instance.new("TextLabel")
title.Parent = titleBar
title.Size = UDim2.new(1,0,1,0)
title.BackgroundTransparency = 1
title.Text = "KEEK DUEL HUB"
title.TextColor3 = Color3.fromRGB(255,80,80)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20

-- BUTTON CONTAINER
local container = Instance.new("ScrollingFrame")
container.Parent = frame
container.Position = UDim2.new(0,0,0,40)
container.Size = UDim2.new(1,0,1,-40)
container.BackgroundTransparency = 1
container.BorderSizePixel = 0
container.ScrollBarThickness = 6
container.CanvasSize = UDim2.new(0,0,0,0)
container.ScrollingDirection = Enum.ScrollingDirection.Y

local layout = Instance.new("UIListLayout")
layout.Parent = container
layout.Padding = UDim.new(0,6)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	container.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
end)

--------------------------------------------------
-- BUTTON CREATOR
--------------------------------------------------

local function createToggle(text,callback)

    local btn = Instance.new("TextButton")
    btn.Parent = container
    btn.Size = UDim2.new(0.9,0,0,32)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.BorderSizePixel = 0
    btn.Text = text.." : OFF"

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0,6)
    btnCorner.Parent = btn

    local state = false

    btn.MouseButton1Click:Connect(function()

        state = not state

        if state then
            btn.Text = text.." : ON"
            btn.BackgroundColor3 = Color3.fromRGB(80,40,40)
        else
            btn.Text = text.." : OFF"
            btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        end

        callback(state)

    end)

end

--------------------------------------------------
-- FEATURE BUTTONS
--------------------------------------------------

createToggle("Auto Steal",ToggleAutoSteal)
createToggle("Combat",ToggleCombat)
createToggle("Speed Boost",ToggleSpeed)
createToggle("Infinite Jump",ToggleInfJump)
createToggle("Auto Bat",ToggleAutoBat)
createToggle("Anti Ragdoll",ToggleAntiRagdoll)

createToggle("Shiny Graphics",ToggleShinyGraphics)
createToggle("Optimizer + XRay",ToggleOptimizer)

createToggle("Float",ToggleFloat)
createToggle("Unwalk",ToggleUnwalk)
createToggle("Auto Left",ToggleAutoLeft)
createToggle("Auto Right",ToggleAutoRight)

createToggle("Spinbot",ToggleSpinbot)
createToggle("Auto TP Ragdoll",ToggleAutoTP)
