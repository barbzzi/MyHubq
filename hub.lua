--[[ 
   Minimalist Clean Hub — v5.1.0 (Auto Kill Refactored & Smart Switch)
  Compatible : OpiumWare / Real / Xeno / Synapse / Krnl / Fluxus
]]--

-- ==================== SERVICES ====================
local cloneref = cloneref or function(o) return o end
local function svc(name)
    local s = game:GetService(name)
    local ok, r = pcall(cloneref, s)
    return ok and r or s
end

local Players = svc("Players")
local UserInputService = svc("UserInputService")
local RunService = svc("RunService")
local Lighting = svc("Lighting")
local Workspace = svc("Workspace")
local HttpService = svc("HttpService")
local SoundService = svc("SoundService")
local LocalizationService = svc("LocalizationService")
local MarketplaceService = svc("MarketplaceService")
local CoreGui = svc("CoreGui")
local VirtualInputManager = svc("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do task.wait() LocalPlayer = Players.LocalPlayer end
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ==================== SYSTEM VARIABLES ====================
local CurrentToggleKey = Enum.KeyCode.Q
local CamlockKey = Enum.KeyCode.C
local SpeedKeyBind = Enum.KeyCode.V
local JumpKeyBind = Enum.KeyCode.B
local NoclipKeyBind = Enum.KeyCode.N
local Connections = {}
local UnloadHub
local ConfigsFolder = "CleanHubConfigs"

-- ==================== GUN / WORLD VARS ====================
local GunFlashColor = Color3.fromRGB(255, 255, 255)
local GunFlashBrightness = 0.5
local GunFlashDuration = 0.15
local HitboxColor = Color3.fromRGB(60, 120, 255)
local ESPColor = Color3.fromRGB(147, 112, 219)
local SkeletonColor = Color3.fromRGB(255, 255, 255)
local GunToolCache = setmetatable({}, { __mode = "k" })
local MeleeToolCache = setmetatable({}, { __mode = "k" })

local GUN_KEYWORDS = {"gun","rifle","pistol","smg","shotgun","sniper","lmg","carbine","revolver","deagle","glock","ak","m4","mp5","uzi","magnum","dmr","weapon","scar","awp","tommy","tec","p90","vector","famas","g36","aug","hk","mp7","mp9","m16","m14","ar15","fiveseven","barrett","hunting","double barrel"}
local MELEE_KEYWORDS = {"knife","sword","bat","melee","dagger","blade","axe","hammer","karambit","machete","katana","scythe","club","stick","wrench","crowbar","pan","fist"}
local FOOD_KEYWORDS = {"food","burger","pizza","apple","banana","drink","soda","water","cola","taco","donut","bread","sandwich","chicken","potion","juice","milk","snack","cake","candy","fries","meat","berry","eat","energy"}

local function GetEquippedTool()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Tool")
end

local function NameHas(name, list)
    for _, k in ipairs(list) do
        if name:find(k, 1, true) then return true end
    end
    return false
end

local function IsGunTool(tool)
    if not tool then return false end
    local cached = GunToolCache[tool]
    if cached ~= nil then return cached end
    local name = tool.Name:lower()
    local result = false
    if NameHas(name, MELEE_KEYWORDS) or NameHas(name, FOOD_KEYWORDS) then
        result = false
    elseif NameHas(name, GUN_KEYWORDS) then
        result = true
    else
        for _, d in ipairs(tool:GetDescendants()) do
            local dn = d.Name:lower()
            if dn:find("muzzle") or dn:find("firepoint") or dn:find("bullet") or dn:find("ammo") or dn:find("firerate") or dn:find("recoil") or dn:find("spread") then
                result = true
                break
            end
        end
    end
    GunToolCache[tool] = result
    return result
end

local function IsMeleeTool(tool)
    if not tool then return false end
    local cached = MeleeToolCache[tool]
    if cached ~= nil then return cached end
    local name = tool.Name:lower()
    local result = false
    if NameHas(name, MELEE_KEYWORDS) then
        result = true
    elseif NameHas(name, GUN_KEYWORDS) or NameHas(name, FOOD_KEYWORDS) then
        result = false
    else
        result = not IsGunTool(tool)
    end
    MeleeToolCache[tool] = result
    return result
end

-- ==================== SOUND ====================
local function PlayClickSound()
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://9061473708"
        sound.Volume = 1.5
        sound.Parent = SoundService
        sound:Play()
        sound.Ended:Connect(function() sound:Destroy() end)
    end)
end

-- ==================== CUSTOM THEME ====================
local DefaultTheme = {
    Primary  = Color3.fromRGB(147, 112, 219),
    Text     = Color3.fromRGB(240, 240, 245),
    Outline  = Color3.fromRGB(147, 112, 219),
    BG       = Color3.fromRGB(18, 18, 23),
}
local function CopyTheme(t)
    return { Primary = t.Primary, Text = t.Text, Outline = t.Outline, BG = t.BG }
end
local CurrentTheme = CopyTheme(DefaultTheme)
local OutlineEnabled = true

local function SidebarColor()
    local c = CurrentTheme.BG
    return Color3.new(math.clamp(c.R * 0.72, 0, 1), math.clamp(c.G * 0.72, 0, 1), math.clamp(c.B * 0.72, 0, 1))
end

-- ==================== SETTINGS ====================
local Settings = {
    UIVisible = true,
    Walkspeed = 24,
    JumpPower = 80,
    SpeedEnabled = false,
    JumpEnabled = false,
    Noclip = false,
    ESP_Name = false,
    ESP_Distance = false,
    ESP_Speed = false,
    ESP_ItemHeld = false,
    ESP_AliveDead = false,
    ESP_Tracer = false,
    ESP_Skeleton = false,
    HitboxEnabled = false,
    HitboxSize = 8,
    ShowHitbox = true,
    GunLight = false,
    Fullbright = false,
    CustomFogEnabled = false,
    CustomFogColor = Color3.fromRGB(255, 60, 60),
    CustomFogStart = 0,
    CustomFogEnd = 1000,
    ForceTimeEnabled = false,
    ForceTime = 14,
    AimPart = "Head",
    Camlock = false,
    CamlockTarget = nil,
    CamlockSmoothness = 0.5,
    
    -- Paramètres Auto Kill Améliorés
    AutoKill_Enabled = false,
    AutoKill_SelectedTargets = {},
    AutoKill_OrbitSpeed = 6,
    AutoKill_Distance = 5,
    AutoKill_Height = 1,
    AutoKill_HitboxSize = 12,
    AutoKill_SmartSwitch = true, -- Switch auto Gun / Couteau intelligent
    AutoKill_MeleeRange = 8,     -- Distance de bascule vers le couteau
    SpectateTargetEnabled = false,
    VoidSpeedEnabled = false,
    VoidSpeedValue = 50,
    SpinbotEnabled = false,
    SpinbotSpeed = 50,
    WaitRespawnEnabled = true
}

local function ColorToTable(c)
    return { R = math.floor(c.R * 255 + 0.5), G = math.floor(c.G * 255 + 0.5), B = math.floor(c.B * 255 + 0.5) }
end
local function TableToColor(t)
    if type(t) ~= "table" then return Color3.new(1,1,1) end
    return Color3.fromRGB(t.R or 255, t.G or 255, t.B or 255)
end

-- ==================== DRAWING (fallback) ====================
local DrawingLib
pcall(function() if Drawing and Drawing.new then DrawingLib = Drawing end end)
if not DrawingLib and getgenv and getgenv().Drawing then DrawingLib = getgenv().Drawing end

local PolyGui
if not DrawingLib then
    PolyGui = Instance.new("ScreenGui")
    PolyGui.Name = "CleanHub_Drawings"
    PolyGui.IgnoreGuiInset = true
    PolyGui.ResetOnSpawn = false
    PolyGui.DisplayOrder = 100
    pcall(function()
        if gethui then PolyGui.Parent = gethui() else PolyGui.Parent = CoreGui end
    end)
    local Poly = {}
    Poly.__index = Poly
    local function NewPolyObj(class)
        local self = setmetatable({}, Poly)
        rawset(self, "_class", class)
        rawset(self, "_props", {})
        local frame
        if class == "Text" then
            frame = Instance.new("TextLabel")
            frame.BackgroundTransparency = 1
            frame.Font = Enum.Font.GothamBold
            frame.TextSize = 13
            frame.TextColor3 = Color3.new(1,1,1)
            frame.AnchorPoint = Vector2.new(0.5, 0.5)
        elseif class == "Line" then
            frame = Instance.new("Frame")
            frame.BorderSizePixel = 0
            frame.AnchorPoint = Vector2.new(0.5, 0.5)
        elseif class == "Circle" then
            frame = Instance.new("Frame")
            frame.BackgroundTransparency = 1
            frame.BorderSizePixel = 0
            frame.AnchorPoint = Vector2.new(0.5, 0.5)
            local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1,0) c.Parent = frame
        else
            frame = Instance.new("Frame")
            frame.BorderSizePixel = 0
        end
        frame.Parent = PolyGui
        rawset(self, "_frame", frame)
        return self
    end
    Poly.__newindex = function(self, key, value)
        local frame = rawget(self, "_frame")
        local props = rawget(self, "_props")
        local class = rawget(self, "_class")
        props[key] = value
        local stroke = frame:FindFirstChildOfClass("UIStroke")
        if key == "Visible" then
            frame.Visible = value
        elseif key == "Color" then
            if class == "Text" then frame.TextColor3 = value
            elseif props.Filled then frame.BackgroundColor3 = value
            elseif stroke then stroke.Color = value
            else frame.BackgroundColor3 = value end
        elseif key == "Transparency" then
            if props.Filled then frame.BackgroundTransparency = value
            elseif stroke then stroke.Transparency = value end
        elseif key == "Thickness" then
            if class == "Line" then
                frame.BackgroundTransparency = 0
                if props.Color then frame.BackgroundColor3 = props.Color end
            else
                if not stroke then stroke = Instance.new("UIStroke") stroke.Parent = frame end
                stroke.Thickness = value
                if not props.Filled then frame.BackgroundTransparency = 1 end
            end
        elseif key == "Filled" then
            if value then
                if stroke then stroke:Destroy() end
                frame.BackgroundTransparency = 0
                if props.Color then frame.BackgroundColor3 = props.Color end
            else
                frame.BackgroundTransparency = 1
                if not frame:FindFirstChildOfClass("UIStroke") then
                    local s = Instance.new("UIStroke") s.Thickness = props.Thickness or 1 s.Parent = frame
                    if props.Color then s.Color = props.Color end
                end
            end
        elseif key == "Position" then
            frame.Position = UDim2.fromOffset(value.X, value.Y)
        elseif key == "Size" then
            if class == "Text" then frame.TextSize = value
            else frame.Size = UDim2.fromOffset(value.X, value.Y) end
        elseif key == "Radius" then
            frame.Size = UDim2.fromOffset(value * 2, value * 2)
        elseif key == "Text" then
            frame.Text = value
        elseif key == "Center" then
            frame.TextXAlignment = value and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
        elseif key == "Outline" then
            frame.TextStrokeTransparency = value and 0.4 or 1
        elseif key == "From" or key == "To" then
            local from = props.From or Vector2.new(0,0)
            local to = props.To or Vector2.new(0,0)
            local delta = to - from
            frame.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
            frame.Size = UDim2.fromOffset(math.max(delta.Magnitude, 1), props.Thickness or 1.5)
            frame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
            frame.BackgroundTransparency = 0
            if props.Color then frame.BackgroundColor3 = props.Color end
        end
    end
    Poly.Remove = function(self)
        local f = rawget(self, "_frame")
        if f then f:Destroy() end
    end
    DrawingLib = { new = function(class) return NewPolyObj(class) end }
end

-- ==================== GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CleanMinimalHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    if gethui then
        ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 520, 0, 380)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -190)
MainFrame.BackgroundColor3 = CurrentTheme.BG
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner") UICorner.CornerRadius = UDim.new(0, 12) UICorner.Parent = MainFrame
local UIStroke = Instance.new("UIStroke") UIStroke.Thickness = 1.5 UIStroke.Color = CurrentTheme.Outline UIStroke.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, 0)
Sidebar.BackgroundColor3 = SidebarColor()
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local dragging, dragInput, dragStart, startPos
Sidebar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

Sidebar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))

local SidebarCorner = Instance.new("UICorner") SidebarCorner.CornerRadius = UDim.new(0, 12) SidebarCorner.Parent = Sidebar

local SidebarTitle = Instance.new("TextLabel")
SidebarTitle.Size = UDim2.new(1, 0, 0, 40)
SidebarTitle.BackgroundTransparency = 1
SidebarTitle.Text = "HUB"
SidebarTitle.TextColor3 = CurrentTheme.Primary
SidebarTitle.TextSize = 16
SidebarTitle.Font = Enum.Font.GothamBold
SidebarTitle.Parent = Sidebar

local TabContainer = Instance.new("ScrollingFrame")
TabContainer.Size = UDim2.new(1, -10, 1, -50)
TabContainer.Position = UDim2.new(0, 5, 0, 45)
TabContainer.BackgroundTransparency = 1
TabContainer.BorderSizePixel = 0
TabContainer.ScrollBarThickness = 0
TabContainer.Parent = Sidebar

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 6)
TabListLayout.Parent = TabContainer

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -140, 1, -40)
ContentContainer.Position = UDim2.new(0, 135, 0, 10)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

local UserTagLabel = Instance.new("TextLabel")
UserTagLabel.Size = UDim2.new(0, 0, 0, 24)
UserTagLabel.Position = UDim2.new(1, -12, 1, -28)
UserTagLabel.AnchorPoint = Vector2.new(1, 0)
UserTagLabel.BackgroundColor3 = CurrentTheme.Primary
UserTagLabel.BackgroundTransparency = 0.1
UserTagLabel.Text = "  " .. LocalPlayer.Name .. "  "
UserTagLabel.TextColor3 = Color3.fromRGB(255,255,255)
UserTagLabel.Font = Enum.Font.GothamBold
UserTagLabel.TextSize = 11
UserTagLabel.AutomaticSize = Enum.AutomaticSize.X
UserTagLabel.ZIndex = 5
UserTagLabel.Parent = MainFrame

local UserTagCorner = Instance.new("UICorner") UserTagCorner.CornerRadius = UDim.new(0, 6) UserTagCorner.Parent = UserTagLabel

local CloseBtn = Instance.new("ImageButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, 0, 0, 0)
CloseBtn.AnchorPoint = Vector2.new(1, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Image = "rbxassetid://6023426915"
CloseBtn.ImageColor3 = Color3.fromRGB(255, 60, 60)
CloseBtn.ZIndex = 10
CloseBtn.Parent = MainFrame

-- ==================== THEME REFRESH ENGINE ====================
local ThemeUpdaters = {}

local function RefreshTheme()
    local sb = SidebarColor()
    MainFrame.BackgroundColor3 = CurrentTheme.BG
    Sidebar.BackgroundColor3 = sb
    UIStroke.Color = CurrentTheme.Outline
    UIStroke.Transparency = OutlineEnabled and 0 or 1
    UserTagLabel.BackgroundColor3 = CurrentTheme.Primary
    SidebarTitle.TextColor3 = CurrentTheme.Primary
    for _, fn in ipairs(ThemeUpdaters) do pcall(fn) end
end

-- ==================== TABS ====================
local Tabs, Pages = {}, {}
local function CreateTab(name, order)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 32)
    Btn.BackgroundColor3 = SidebarColor()
    Btn.Text = name
    Btn.TextColor3 = Color3.fromRGB(180,180,190)
    Btn.TextSize = 12
    Btn.Font = Enum.Font.GothamMedium
    Btn.LayoutOrder = order
    Btn.Parent = TabContainer
    local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 8) Corner.Parent = Btn
    Tabs[name] = Btn
    return Btn
end

local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, -10)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = CurrentTheme.Primary
    Page.Visible = false
    Page.Parent = ContentContainer
    local Layout = Instance.new("UIListLayout")
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 8)
    Layout.Parent = Page
    Pages[name] = Page
    table.insert(ThemeUpdaters, function() Page.ScrollBarImageColor3 = CurrentTheme.Primary end)
    return Page
end

local tabList = {"Welcome", "Main", "Combat", "Auto Kill", "Hitbox", "Gun", "Teleport", "Sky / Fog", "ESP", "Configs", "Settings", "Players"}
for i, name in ipairs(tabList) do
    CreateTab(name, i)
    CreatePage(name)
end

local CurrentTab = "Welcome"
local function SwitchTab(selected, silent)
    CurrentTab = selected
    if not silent then PlayClickSound() end
    for name, page in pairs(Pages) do page.Visible = (name == selected) end
    for name, btn in pairs(Tabs) do
        if name == selected then
            btn.BackgroundColor3 = CurrentTheme.Primary
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.Font = Enum.Font.GothamBold
        else
            btn.BackgroundColor3 = SidebarColor()
            btn.TextColor3 = Color3.fromRGB(180,180,190)
            btn.Font = Enum.Font.GothamMedium
        end
    end
end
table.insert(ThemeUpdaters, function() SwitchTab(CurrentTab, true) end)

for name, btn in pairs(Tabs) do
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
end
SwitchTab("Welcome", true)

-- ==================== UI HELPERS ====================
local ToggleElements = {}
local SliderElements = {}
local KeybindBtns = {}

local function CreateToggle(parent, text, defaultKey, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 36)
    Frame.BackgroundColor3 = SidebarColor()
    Frame.Parent = parent
    local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 8) Corner.Parent = Frame
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = CurrentTheme.Text
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 50, 0, 24)
    Btn.Position = UDim2.new(1, -60, 0.5, -12)
    Btn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    Btn.Text = "OFF"
    Btn.TextColor3 = Color3.fromRGB(200,200,200)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 10
    Btn.Parent = Frame
    local BtnCorner = Instance.new("UICorner") BtnCorner.CornerRadius = UDim.new(0, 6) BtnCorner.Parent = Btn
    local state = false
    local function SetState(val)
        state = val
        Btn.Text = state and "ON" or "OFF"
        Btn.BackgroundColor3 = state and CurrentTheme.Primary or Color3.fromRGB(40,40,50)
        Btn.TextColor3 = state and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)
        callback(state)
    end
    Btn.MouseButton1Click:Connect(function() PlayClickSound() SetState(not state) end)
    table.insert(ThemeUpdaters, function()
        Frame.BackgroundColor3 = SidebarColor()
        Label.TextColor3 = CurrentTheme.Text
        Btn.BackgroundColor3 = state and CurrentTheme.Primary or Color3.fromRGB(40,40,50)
    end)
    if defaultKey then ToggleElements[defaultKey] = SetState end
    return SetState
end

local function CreateKeybind(parent, text, defaultKey, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 36)
    Frame.BackgroundColor3 = SidebarColor()
    Frame.Parent = parent
    local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 8) Corner.Parent = Frame
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = CurrentTheme.Text
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 70, 0, 24)
    Btn.Position = UDim2.new(1, -80, 0.5, -12)
    Btn.BackgroundColor3 = CurrentTheme.Primary
    Btn.Text = "[" .. defaultKey.Name .. "]"
    Btn.TextColor3 = Color3.fromRGB(255,255,255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 11
    Btn.Parent = Frame
    local BtnCorner = Instance.new("UICorner") BtnCorner.CornerRadius = UDim.new(0, 6) BtnCorner.Parent = Btn
    local listening = false
    Btn.MouseButton1Click:Connect(function()
        PlayClickSound()
        listening = true
        Btn.Text = "[...]"
    end)
    table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            Btn.Text = "[" .. input.KeyCode.Name .. "]"
            callback(input.KeyCode)
        end
    end))
    table.insert(ThemeUpdaters, function()
        Frame.BackgroundColor3 = SidebarColor()
        Label.TextColor3 = CurrentTheme.Text
        Btn.BackgroundColor3 = CurrentTheme.Primary
    end)
    return Btn
end

local function CreateSlider(parent, text, min, max, default, decimals, keyName, callback, suffix)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 50)
    Frame.BackgroundColor3 = SidebarColor()
    Frame.Parent = parent
    local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 8) Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 0, 20)
    Label.Position = UDim2.new(0, 10, 0, 4)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = CurrentTheme.Text
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Size = UDim2.new(0.3, 0, 0, 20)
    ValLabel.Position = UDim2.new(0.7, -10, 0, 4)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Text = tostring(default) .. (suffix or "")
    ValLabel.TextColor3 = CurrentTheme.Primary
    ValLabel.Font = Enum.Font.GothamBold
    ValLabel.TextSize = 12
    ValLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValLabel.Parent = Frame

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, -20, 0, 8)
    Bar.Position = UDim2.new(0, 10, 0, 32)
    Bar.BackgroundColor3 = Color3.fromRGB(35,35,45)
    Bar.BorderSizePixel = 0
    Bar.Parent = Frame
    local BarCorner = Instance.new("UICorner") BarCorner.CornerRadius = UDim.new(1, 0) BarCorner.Parent = Bar

    local scale0 = math.clamp((default - min) / (max - min), 0, 1)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(scale0, 0, 1, 0)
    Fill.BackgroundColor3 = CurrentTheme.Primary
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar
    local FillCorner = Instance.new("UICorner") FillCorner.CornerRadius = UDim.new(1, 0) FillCorner.Parent = Fill

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 14, 0, 18)
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.Position = UDim2.new(scale0, 0, 0.5, 0)
    Knob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 4
    Knob.Parent = Bar
    local KnobCorner = Instance.new("UICorner") KnobCorner.CornerRadius = UDim.new(0, 3) KnobCorner.Parent = Knob
    local KnobStroke = Instance.new("UIStroke") KnobStroke.Thickness = 1 KnobStroke.Color = Color3.fromRGB(15,15,20) KnobStroke.Parent = Knob

    local HitZone = Instance.new("TextButton")
    HitZone.Size = UDim2.new(1, -20, 0, 26)
    HitZone.Position = UDim2.new(0, 10, 0, 23)
    HitZone.BackgroundTransparency = 1
    HitZone.Text = ""
    HitZone.ZIndex = 5
    HitZone.Parent = Frame

    local function SetValue(val)
        val = math.clamp(val, min, max)
        if decimals then
            val = math.floor(val * 100 + 0.5) / 100
            ValLabel.Text = string.format("%.2f", val) .. (suffix or "")
        else
            val = math.floor(val + 0.5)
            ValLabel.Text = tostring(val) .. (suffix or "")
        end
        local sc = (val - min) / (max - min)
        Fill.Size = UDim2.new(sc, 0, 1, 0)
        Knob.Position = UDim2.new(sc, 0, 0.5, 0)
        callback(val)
    end

    local draggingBar = false
    local function UpdateFromX(x)
        local p = math.clamp((x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        SetValue(min + (p * (max - min)))
    end

    HitZone.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingBar = true
            UpdateFromX(input.Position.X)
        end
    end)
    table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingBar = false
        end
    end))
    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if draggingBar and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateFromX(input.Position.X)
        end
    end))

    table.insert(ThemeUpdaters, function()
        Frame.BackgroundColor3 = SidebarColor()
        Label.TextColor3 = CurrentTheme.Text
        ValLabel.TextColor3 = CurrentTheme.Primary
        Fill.BackgroundColor3 = CurrentTheme.Primary
    end)

    if keyName then SliderElements[keyName] = SetValue end
    return SetValue
end

local function CreateButton(parent, text, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -10, 0, 32)
    Btn.BackgroundColor3 = CurrentTheme.Primary
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(255,255,255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.Parent = parent
    local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 8) Corner.Parent = Btn
    Btn.MouseButton1Click:Connect(function() PlayClickSound() callback() end)
    table.insert(ThemeUpdaters, function() Btn.BackgroundColor3 = CurrentTheme.Primary end)
    return Btn
end

local function CreateLabel(parent, text, color, size, height, followAccent)
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -10, 0, height or 20)
    L.BackgroundTransparency = 1
    L.Text = text
    L.TextColor3 = color or Color3.fromRGB(200,200,200)
    L.Font = Enum.Font.GothamBold
    L.TextSize = size or 12
    L.TextWrapped = true
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = parent
    if followAccent then
        table.insert(ThemeUpdaters, function() L.TextColor3 = CurrentTheme.Primary end)
    end
    return L
end

local function CreateColorGrid(parent, title, onSelect)
    CreateLabel(parent, title, CurrentTheme.Text, 13, 20)
    local Grid = Instance.new("Frame")
    Grid.Size = UDim2.new(1, -10, 0, 40)
    Grid.BackgroundTransparency = 1
    Grid.Parent = parent
    local Layout = Instance.new("UIListLayout")
    Layout.FillDirection = Enum.FillDirection.Horizontal
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 6)
    Layout.Parent = Grid

    local Colors = {
        Color3.fromRGB(255, 50, 50),
        Color3.fromRGB(255, 130, 40),
        Color3.fromRGB(255, 235, 50),
        Color3.fromRGB(50, 220, 70),
        Color3.fromRGB(40, 150, 255),
        Color3.fromRGB(150, 50, 255),
        Color3.fromRGB(255, 105, 180),
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(30, 35, 45)
    }

    for i, col in ipairs(Colors) do
        local Box = Instance.new("TextButton")
        Box.Size = UDim2.new(0, 32, 0, 32)
        Box.BackgroundColor3 = col
        Box.Text = ""
        Box.LayoutOrder = i
        Box.Parent = Grid
        local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 6) Corner.Parent = Box
        Box.MouseButton1Click:Connect(function()
            PlayClickSound()
            onSelect(col)
        end)
    end
end

-- ==================== TAB: WELCOME ====================
local WelcomePage = Pages["Welcome"]
local WelcomeTitle = Instance.new("TextLabel")
WelcomeTitle.Size = UDim2.new(1, -10, 0, 30)
WelcomeTitle.BackgroundTransparency = 1
WelcomeTitle.Text = "Bienvenue, " .. LocalPlayer.Name .. " !"
WelcomeTitle.TextColor3 = CurrentTheme.Primary
WelcomeTitle.Font = Enum.Font.GothamBold
WelcomeTitle.TextSize = 18
WelcomeTitle.TextXAlignment = Enum.TextXAlignment.Left
WelcomeTitle.Parent = WelcomePage
table.insert(ThemeUpdaters, function() WelcomeTitle.TextColor3 = CurrentTheme.Primary end)

local WelcomeDesc = Instance.new("TextLabel")
WelcomeDesc.Size = UDim2.new(1, -10, 0, 90)
WelcomeDesc.BackgroundTransparency = 1
WelcomeDesc.Text = "Nous sommes ravis de vous compter parmi nous aujourd'hui.\nPrenez le temps de configurer vos préférences et profitez d'une expérience de jeu fluide, optimisée et entièrement sécurisée pour dominer chaque partie avec élégance."
WelcomeDesc.TextColor3 = Color3.fromRGB(200,200,200)
WelcomeDesc.Font = Enum.Font.Gotham
WelcomeDesc.TextSize = 12
WelcomeDesc.TextWrapped = true
WelcomeDesc.TextXAlignment = Enum.TextXAlignment.Left
WelcomeDesc.Parent = WelcomePage

-- ==================== TAB: MAIN ====================
local MainPage = Pages["Main"]
local NoclipOriginal = {}
local function SetNoclip(state)
    Settings.Noclip = state
    local char = LocalPlayer.Character
    if not char then return end
    if state then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if NoclipOriginal[part] == nil then NoclipOriginal[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    else
        for part, orig in pairs(NoclipOriginal) do
            if part and part.Parent then part.CanCollide = orig end
        end
        NoclipOriginal = {}
    end
end

local OrigJump = nil
local JumpSignalConns = {}
local function ClearJumpSignals()
    for _, c in ipairs(JumpSignalConns) do pcall(function() c:Disconnect() end) end
    JumpSignalConns = {}
end

local function GetHum()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function ApplyJump(force)
    local hum = GetHum()
    if not hum then return end
    if Settings.JumpEnabled then
        if OrigJump == nil then
            OrigJump = {Power = hum.JumpPower, UsePower = hum.UseJumpPower, Height = hum.JumpHeight}
        end
        if hum.UseJumpPower ~= true then hum.UseJumpPower = true end
        if math.abs(hum.JumpPower - Settings.JumpPower) > 0.01 then
            hum.JumpPower = Settings.JumpPower
        end
    elseif force and OrigJump ~= nil then
        local snap = OrigJump
        OrigJump = nil
        pcall(function()
            hum.UseJumpPower = snap.UsePower
            if snap.UsePower then
                hum.JumpPower = snap.Power
            else
                hum.JumpHeight = snap.Height
            end
        end)
    end
end

local function SetupCharacter(char)
    NoclipOriginal = {}
    OrigJump = nil
    ClearJumpSignals()
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        table.insert(JumpSignalConns, hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
            if Settings.JumpEnabled and math.abs(hum.JumpPower - Settings.JumpPower) > 0.01 then
                hum.JumpPower = Settings.JumpPower
            end
        end))
    end
    task.wait(0.15)
    if Settings.Noclip then SetNoclip(true) end
    if Settings.JumpEnabled then ApplyJump() end
end

if LocalPlayer.Character then task.spawn(SetupCharacter, LocalPlayer.Character) end
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(SetupCharacter))

CreateToggle(MainPage, " Enable Speed", "SpeedEnabled", function(s) Settings.SpeedEnabled = s end)
KeybindBtns["Speed"] = CreateKeybind(MainPage, " Speed Keybind", SpeedKeyBind, function(k) SpeedKeyBind = k end)
CreateSlider(MainPage, "Speed Value", 16, 500, 24, false, "Walkspeed", function(v) Settings.Walkspeed = v end)

CreateToggle(MainPage, "Void Speed", "VoidSpeedEnabled", function(s) Settings.VoidSpeedEnabled = s end)
CreateSlider(MainPage, "Void Speed Valeur", 10, 200, 50, false, "VoidSpeedValue", function(v) Settings.VoidSpeedValue = v end)

CreateToggle(MainPage, "Spinbot", "SpinbotEnabled", function(s) Settings.SpinbotEnabled = s end)
CreateSlider(MainPage, "Spinbot Vitesse", 10, 200, 50, false, "SpinbotSpeed", function(v) Settings.SpinbotSpeed = v end)

CreateToggle(MainPage, " Enable Jump", "JumpEnabled", function(s)
    Settings.JumpEnabled = s
    ApplyJump(true)
end)
KeybindBtns["Jump"] = CreateKeybind(MainPage, " Jump Keybind", JumpKeyBind, function(k) JumpKeyBind = k end)
CreateSlider(MainPage, "Jump Power", 50, 350, 80, false, "JumpPower", function(v)
    Settings.JumpPower = v
    if Settings.JumpEnabled then ApplyJump() end
end)

CreateToggle(MainPage, " No Clip", "Noclip", function(s) SetNoclip(s) end)
KeybindBtns["Noclip"] = CreateKeybind(MainPage, " Noclip Keybind", NoclipKeyBind, function(k) NoclipKeyBind = k end)

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe then
        if input.KeyCode == SpeedKeyBind then
            Settings.SpeedEnabled = not Settings.SpeedEnabled
            if ToggleElements["SpeedEnabled"] then ToggleElements["SpeedEnabled"](Settings.SpeedEnabled) end
        elseif input.KeyCode == JumpKeyBind then
            if ToggleElements["JumpEnabled"] then ToggleElements["JumpEnabled"](not Settings.JumpEnabled) end
        elseif input.KeyCode == NoclipKeyBind then
            SetNoclip(not Settings.Noclip)
        end
    end
end))

table.insert(Connections, RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    
    if Settings.SpeedEnabled and hum.MoveDirection.Magnitude > 0 then
        local currentY = hrp.AssemblyLinearVelocity.Y
        local targetVelocity = hum.MoveDirection * Settings.Walkspeed
        hrp.AssemblyLinearVelocity = Vector3.new(targetVelocity.X, currentY, targetVelocity.Z)
    end

    if Settings.VoidSpeedEnabled and hum.MoveDirection.Magnitude > 0 then
        hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (Settings.VoidSpeedValue / 50))
    end

    if Settings.SpinbotEnabled then
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Settings.SpinbotSpeed), 0)
    end
end))

-- ==================== TAB: COMBAT ====================
local CombatPage = Pages["Combat"]

CreateToggle(CombatPage, " Camlock Toggle", "Camlock", function(s)
    Settings.Camlock = s
    if not s then Settings.CamlockTarget = nil end
end)
KeybindBtns["Camlock"] = CreateKeybind(CombatPage, " Camlock Keybind", CamlockKey, function(k) CamlockKey = k end)
CreateSlider(CombatPage, " Smoothness", 1, 10, 5, false, "CamlockSmoothness", function(v) Settings.CamlockSmoothness = v / 10 end)

local AimParts = {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}
local AimPartBtn = Instance.new("TextButton")
AimPartBtn.Size = UDim2.new(1, -10, 0, 32)
AimPartBtn.BackgroundColor3 = CurrentTheme.Primary
AimPartBtn.TextColor3 = Color3.fromRGB(255,255,255)
AimPartBtn.Font = Enum.Font.GothamBold
AimPartBtn.TextSize = 12
AimPartBtn.Parent = CombatPage
local AimPartCorner = Instance.new("UICorner") AimPartCorner.CornerRadius = UDim.new(0, 8) AimPartCorner.Parent = AimPartBtn
table.insert(ThemeUpdaters, function() AimPartBtn.BackgroundColor3 = CurrentTheme.Primary end)

local function UpdateAimPartBtn() AimPartBtn.Text = " Aim Part: " .. Settings.AimPart end
AimPartBtn.MouseButton1Click:Connect(function()
    PlayClickSound()
    local idx = 1
    for i, v in ipairs(AimParts) do if v == Settings.AimPart then idx = i end end
    Settings.AimPart = AimParts[idx % #AimParts + 1]
    UpdateAimPartBtn()
end)
UpdateAimPartBtn()

local function GetAimPartFor(plr)
    if not plr or not plr.Character then return nil end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return nil end
    return plr.Character:FindFirstChild(Settings.AimPart) or plr.Character:FindFirstChild("HumanoidRootPart")
end

local function GetClosestPlayer()
    local target, shortestDist = nil, math.huge
    local mpos = UserInputService:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local part = GetAimPartFor(p)
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mpos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        target = p
                    end
                end
            end
        end
    end
    return target
end

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == CamlockKey then
        if Settings.Camlock then
            Settings.CamlockTarget = (not Settings.CamlockTarget) and GetClosestPlayer() or nil
        end
    end
end))

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if Settings.Camlock and Settings.CamlockTarget and Settings.CamlockTarget.Character then
        local part = Settings.CamlockTarget.Character:FindFirstChild(Settings.AimPart) or Settings.CamlockTarget.Character:FindFirstChild("HumanoidRootPart")
        if part then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, part.Position), Settings.CamlockSmoothness)
        end
    end
end))

-- ==================== TAB: AUTO KILL (REFONDU ET AMÉLIORÉ) ====================
local AutoKillPage = Pages["Auto Kill"]
CreateLabel(AutoKillPage, "Auto Kill - Cibles & Smart Switch", CurrentTheme.Primary, 14, 24, true)

CreateToggle(AutoKillPage, "Activer l'Auto Kill", "AutoKill_Enabled", function(s) Settings.AutoKill_Enabled = s end)
CreateToggle(AutoKillPage, "Smart Switch (Arme / Couteau auto)", "AutoKill_SmartSwitch", function(s) Settings.AutoKill_SmartSwitch = s end)
CreateToggle(AutoKillPage, "Spectater la cible active", "SpectateTargetEnabled", function(s) Settings.SpectateTargetEnabled = s end)
CreateToggle(AutoKillPage, "Attendre Respawn en l'air (Sécurité)", "WaitRespawnEnabled", function(s) Settings.WaitRespawnEnabled = s end)

local TargetDropBtn = Instance.new("TextButton")
TargetDropBtn.Size = UDim2.new(1, -10, 0, 32)
TargetDropBtn.BackgroundColor3 = SidebarColor()
TargetDropBtn.Text = "    Sélectionner les cibles..."
TargetDropBtn.TextColor3 = CurrentTheme.Text
TargetDropBtn.Font = Enum.Font.GothamBold
TargetDropBtn.TextSize = 12
TargetDropBtn.TextXAlignment = Enum.TextXAlignment.Left
TargetDropBtn.Parent = AutoKillPage
Instance.new("UICorner", TargetDropBtn).CornerRadius = UDim.new(0, 8)
table.insert(ThemeUpdaters, function() TargetDropBtn.BackgroundColor3 = SidebarColor() TargetDropBtn.TextColor3 = CurrentTheme.Text end)

local TargetDropList = Instance.new("ScrollingFrame")
TargetDropList.Size = UDim2.new(1, -10, 0, 0)
TargetDropList.BackgroundColor3 = SidebarColor()
TargetDropList.BorderSizePixel = 0
TargetDropList.ScrollBarThickness = 3
TargetDropList.ScrollBarImageColor3 = CurrentTheme.Primary
TargetDropList.AutomaticCanvasSize = Enum.AutomaticSize.Y
TargetDropList.CanvasSize = UDim2.new(0, 0, 0, 0)
TargetDropList.Visible = false
TargetDropList.Parent = AutoKillPage
Instance.new("UICorner", TargetDropList).CornerRadius = UDim.new(0, 8)
local TargetDropLayout = Instance.new("UIListLayout") TargetDropLayout.Padding = UDim.new(0, 4) TargetDropLayout.Parent = TargetDropList
local TargetDropPad = Instance.new("UIPadding") TargetDropPad.PaddingTop = UDim.new(0, 6) TargetDropPad.PaddingLeft = UDim.new(0, 6) TargetDropPad.PaddingRight = UDim.new(0, 6) TargetDropPad.PaddingBottom = UDim.new(0, 6) TargetDropPad.Parent = TargetDropList
table.insert(ThemeUpdaters, function() TargetDropList.BackgroundColor3 = SidebarColor() TargetDropList.ScrollBarImageColor3 = CurrentTheme.Primary end)

local PlayerButtonsCache = {}

local function RefreshTargetMultiList()
    for _, btn in pairs(PlayerButtonsCache) do
        if btn and btn.Parent then btn:Destroy() end
    end
    PlayerButtonsCache = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local isSelected = Settings.AutoKill_SelectedTargets[p] == true
            local B = Instance.new("TextButton")
            B.Size = UDim2.new(1, -6, 0, 26)
            B.BackgroundColor3 = isSelected and CurrentTheme.Primary or CurrentTheme.BG
            B.Text = "   " .. (isSelected and "[X] " or "[ ] ") .. p.DisplayName
            B.TextColor3 = isSelected and Color3.fromRGB(255,255,255) or CurrentTheme.Text
            B.Font = Enum.Font.GothamMedium
            B.TextSize = 11
            B.TextXAlignment = Enum.TextXAlignment.Left
            B.Parent = TargetDropList
            Instance.new("UICorner", B).CornerRadius = UDim.new(0, 6)
            
            B.MouseButton1Click:Connect(function()
                PlayClickSound()
                if Settings.AutoKill_SelectedTargets[p] then
                    Settings.AutoKill_SelectedTargets[p] = nil
                else
                    Settings.AutoKill_SelectedTargets[p] = true
                end
                RefreshTargetMultiList()
            end)
            table.insert(PlayerButtonsCache, B)
        end
    end
end

TargetDropBtn.MouseButton1Click:Connect(function()
    PlayClickSound()
    if TargetDropList.Visible then
        TargetDropList.Visible = false
        TargetDropList.Size = UDim2.new(1, -10, 0, 0)
    else
        RefreshTargetMultiList()
        TargetDropList.Size = UDim2.new(1, -10, 0, 150)
        TargetDropList.Visible = true
    end
end)

CreateLabel(AutoKillPage, "Paramètres Orbit, Distance & Combat", CurrentTheme.Primary, 13, 20, true)
CreateSlider(AutoKillPage, "Vitesse d'Orbite", 1, 20, 6, false, "AutoKill_OrbitSpeed", function(v) Settings.AutoKill_OrbitSpeed = v end)
CreateSlider(AutoKillPage, "Distance d'Orbite", 1, 50, 5, false, "AutoKill_Distance", function(v) Settings.AutoKill_Distance = v end)
CreateSlider(AutoKillPage, "Hauteur d'Orbite", -20, 20, 1, false, "AutoKill_Height", function(v) Settings.AutoKill_Height = v end)
CreateSlider(AutoKillPage, "Taille Hitbox Client", 1, 50, 12, false, "AutoKill_HitboxSize", function(v) Settings.AutoKill_HitboxSize = v end)
CreateSlider(AutoKillPage, "Distance Switch Couteau", 2, 20, 8, false, "AutoKill_MeleeRange", function(v) Settings.AutoKill_MeleeRange = v end, "m")

-- Fonction intelligente de récupération et de switch d'arme (Gun ou Melee selon le contexte)
local function GetOptimalTool(preferMelee)
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not char then return nil end

    -- Vérifier si l'outil déjà équipé est correct
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool then
        if preferMelee and IsMeleeTool(currentTool) then return currentTool end
        if not preferMelee and IsGunTool(currentTool) then return currentTool end
    end

    -- Chercher dans le character ou le backpack
    local bestTool = nil
    local allTools = {}
    
    if backpack then
        for _, t in ipairs(backpack:GetChildren()) do
            if t:IsA("Tool") then table.insert(allTools, t) end
        end
    end
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then table.insert(allTools, t) end
    end

    -- Chercher en priorité selon la préférence (Melee vs Gun)
    for _, t in ipairs(allTools) do
        if preferMelee and IsMeleeTool(t) then
            bestTool = t
            break
        elseif not preferMelee and IsGunTool(t) then
            bestTool = t
            break
        end
    end

    -- Si non trouvé, prendre n'importe quel outil disponible
    if not bestTool and #allTools > 0 then
        bestTool = allTools[1]
    end

    if bestTool and bestTool.Parent == backpack then
        pcall(function() char.Humanoid:EquipTool(bestTool) end)
    end

    return bestTool or currentTool
end

-- Boucle principale Auto Kill ultra optimisée
task.spawn(function()
    local angle = 0
    while true do
        task.wait(0.05)
        pcall(function()
            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHrp then return end

            local activeTarget = nil
            angle = angle + (Settings.AutoKill_OrbitSpeed * 0.05)

            for p, selected in pairs(Settings.AutoKill_SelectedTargets) do
                if selected and p and p.Character then
                    activeTarget = p
                    local tChar = p.Character
                    local tHum = tChar:FindFirstChildOfClass("Humanoid")
                    local tHrp = tChar:FindFirstChild("HumanoidRootPart")
                    
                    if tHum and tHrp then
                        -- Ajustement de la hitbox client pour faciliter les touches
                        tHrp.Size = Vector3.new(Settings.AutoKill_HitboxSize, Settings.AutoKill_HitboxSize, Settings.AutoKill_HitboxSize)
                        tHrp.Transparency = 0.85
                        tHrp.CanCollide = false

                        if Settings.AutoKill_Enabled then
                            local bodyEffects = tChar:FindFirstChild("BodyEffects")
                            local isKnocked = bodyEffects and ((bodyEffects:FindFirstChild("Killed") and bodyEffects.Killed.Value) or (bodyEffects:FindFirstChild("Ko") and bodyEffects.Ko.Value)) or (tHum.Health <= 5)
                            
                            if isKnocked or tHum.Health <= 0 then
                                -- Si la cible est morte / au sol, contact direct pour achever
                                pcall(function()
                                    firetouchinterest(myHrp, tHrp, 0)
                                    firetouchinterest(myHrp, tHrp, 1)
                                    local head = tChar:FindFirstChild("Head")
                                    if head then
                                        firetouchinterest(myHrp, head, 0)
                                        firetouchinterest(myHrp, head, 1)
                                    end
                                end)
                            else
                                if Settings.WaitRespawnEnabled and (not tChar.Parent or tHum.Health <= 0) then
                                    myHrp.CFrame = CFrame.new(myHrp.Position + Vector3.new(0, 350, 0))
                                else
                                    local distToTarget = (myHrp.Position - tHrp.Position).Magnitude
                                    
                                    -- Calcul de l'orbite fluide autour de l'ennemi
                                    local radius = Settings.AutoKill_Distance
                                    local height = Settings.AutoKill_Height
                                    local offsetX = math.cos(angle) * radius
                                    local offsetZ = math.sin(angle) * radius
                                    myHrp.CFrame = CFrame.new(tHrp.Position + Vector3.new(offsetX, height, offsetZ), tHrp.Position)
                                    
                                    -- Gestion intelligente du Smart Switch (Arme à distance vs Couteau)
                                    local preferMelee = false
                                    if Settings.AutoKill_SmartSwitch then
                                        if distToTarget <= Settings.AutoKill_MeleeRange then
                                            preferMelee = true -- Trop près -> Sortir le couteau/mêlée
                                        else
                                            preferMelee = false -- Éloigné -> Sortir l'arme à feu
                                        end
                                    end

                                    local activeTool = GetOptimalTool(preferMelee)
                                    if activeTool then
                                        pcall(function()
                                            activeTool:Activate()
                                        end)
                                        local handle = activeTool:FindFirstChild("Handle") or activeTool:FindFirstChildOfClass("BasePart")
                                        if handle and firetouchinterest then
                                            firetouchinterest(handle, tHrp, 0)
                                            task.wait(0.02)
                                            firetouchinterest(handle, tHrp, 1)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if Settings.SpectateTargetEnabled and activeTarget and activeTarget.Character and activeTarget.Character:FindFirstChild("HumanoidRootPart") then
                Camera.CameraSubject = activeTarget.Character.Humanoid
            else
                if myChar and myChar:FindFirstChildOfClass("Humanoid") then
                    Camera.CameraSubject = myChar.Humanoid
                end
            end
        end)
    end
end)

-- ==================== TAB: HITBOX ====================
local HitboxPage = Pages["Hitbox"]
CreateToggle(HitboxPage, " Enable Hitbox", "HitboxEnabled", function(s) Settings.HitboxEnabled = s end)
CreateToggle(HitboxPage, " Show Hitbox", "ShowHitbox", function(s) Settings.ShowHitbox = s end)
CreateSlider(HitboxPage, " Hitbox Size", 1, 25, 8, false, "HitboxSize", function(v) Settings.HitboxSize = v end)
CreateColorGrid(HitboxPage, "Hitbox Color", function(col) HitboxColor = col end)

local Hitboxes = {}
local function CreateHitbox(plr)
    local char = plr.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local existing = Hitboxes[plr]
    if existing and existing.Char == char and existing.Part and existing.Part.Parent then
        return existing
    end
    if existing and existing.Part then existing.Part:Destroy() end

    local part = Instance.new("Part")
    part.Name = "CleanHubHitbox"
    part.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
    part.CFrame = hrp.CFrame
    part.Anchored = false
    part.Massless = true
    part.CanCollide = false
    part.CastShadow = false
    part.Material = Enum.Material.SmoothPlastic
    part.Color = HitboxColor
    part.Transparency = 0.8
    pcall(function() part.CanQuery = true part.CanTouch = false end)
    part.Parent = char

    local weld = Instance.new("WeldConstraint") weld.Part0 = part weld.Part1 = hrp weld.Parent = part
    local box = Instance.new("SelectionBox") box.Adornee = part box.Color3 = HitboxColor box.LineThickness = 0.03 box.SurfaceTransparency = 1 box.Visible = Settings.ShowHitbox box.Parent = part

    Hitboxes[plr] = {Part = part, Box = box, Char = char}
    return Hitboxes[plr]
end

table.insert(Connections, RunService.Heartbeat:Connect(function()
    if not Settings.HitboxEnabled then
        for plr, h in pairs(Hitboxes) do
            if h.Part then pcall(function() h.Part:Destroy() end) end
            Hitboxes[plr] = nil
        end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        local h = CreateHitbox(plr)
        if h and h.Part then
            local s = Settings.HitboxSize
            if math.abs(h.Part.Size.X - s) > 0.01 then h.Part.Size = Vector3.new(s, s, s) end
            if h.Part.Color ~= HitboxColor then h.Part.Color = HitboxColor end
            if h.Box.Color3 ~= HitboxColor then h.Box.Color3 = HitboxColor end
            h.Box.Visible = Settings.ShowHitbox
            h.Part.Transparency = Settings.ShowHitbox and 0.8 or 1
        end
    end
end))

-- ==================== TAB: GUN ====================
local GunPage = Pages["Gun"]
CreateToggle(GunPage, " Gun Flash Light", "GunLight", function(s) Settings.GunLight = s end)
CreateSlider(GunPage, " Flash Intensity", 0.1, 1, 0.5, true, "GunFlashBrightness", function(v) GunFlashBrightness = v end)
CreateSlider(GunPage, " Flash Duration", 0.05, 10, 0.15, true, "GunFlashDuration", function(v) GunFlashDuration = math.clamp(v, 0.05, 10) end, "s")
CreateColorGrid(GunPage, "Flash Color", function(col) GunFlashColor = col end)

local FlashLight = nil
local FlashHoldUntil = 0
local FlashStartBrightness = 0
local FLASH_FADE_TIME = 0.5

local function EnsureFlashLight()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    if FlashLight == nil or FlashLight.Parent == nil then
        FlashLight = Instance.new("PointLight")
        FlashLight.Brightness = 0
        FlashLight.Range = 25
        FlashLight.Shadows = false
        FlashLight.Parent = hrp
    elseif FlashLight.Parent ~= hrp then
        FlashLight.Parent = hrp
    end
    return FlashLight
end

local function TriggerFlash()
    if not Settings.GunLight then return end
    local tool = GetEquippedTool()
    if not tool or not IsGunTool(tool) then return end
    local light = EnsureFlashLight()
    if not light then return end
    light.Color = GunFlashColor
    FlashStartBrightness = GunFlashBrightness * 20
    light.Brightness = FlashStartBrightness
    FlashHoldUntil = os.clock() + math.clamp(GunFlashDuration, 0.05, 10)
end

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        TriggerFlash()
    end
end))

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if not FlashLight or not FlashLight.Parent then return end
    local now = os.clock()
    if now < FlashHoldUntil then
        FlashLight.Brightness = FlashStartBrightness
    else
        local t = (now - FlashHoldUntil) / FLASH_FADE_TIME
        if t >= 1 then FlashLight.Brightness = 0
        else FlashLight.Brightness = FlashStartBrightness * (1 - t) end
    end
end))

-- ==================== TAB: TELEPORT ====================
local TPPage = Pages["Teleport"]
local SubNav = Instance.new("Frame") SubNav.Size = UDim2.new(1, 0, 0, 30) SubNav.BackgroundTransparency = 1 SubNav.Parent = TPPage
local TPSections, TPFrames = {}, {}
local ActiveTPSection = "All Players"

local function CreateTPSubTab(name, pos)
    local Btn = Instance.new("TextButton") Btn.Size = UDim2.new(0, 115, 0, 26) Btn.Position = pos Btn.BackgroundColor3 = SidebarColor() Btn.Text = name Btn.TextColor3 = CurrentTheme.Text Btn.Font = Enum.Font.GothamBold Btn.TextSize = 11 Btn.Parent = SubNav
    local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 6) Corner.Parent = Btn
    local ListFrame = Instance.new("ScrollingFrame") ListFrame.Size = UDim2.new(1, 0, 1, -35) ListFrame.Position = UDim2.new(0, 0, 0, 35) ListFrame.BackgroundTransparency = 1 ListFrame.BorderSizePixel = 0 ListFrame.ScrollBarThickness = 3 ListFrame.ScrollBarImageColor3 = CurrentTheme.Primary ListFrame.Visible = false ListFrame.Parent = TPPage
    local Layout = Instance.new("UIListLayout") Layout.Padding = UDim.new(0, 4) Layout.Parent = ListFrame
    TPSections[name] = Btn TPFrames[name] = ListFrame
    table.insert(ThemeUpdaters, function()
        ListFrame.ScrollBarImageColor3 = CurrentTheme.Primary
        local active = (name == ActiveTPSection)
        Btn.BackgroundColor3 = active and CurrentTheme.Primary or SidebarColor()
        Btn.TextColor3 = active and Color3.fromRGB(255,255,255) or CurrentTheme.Text
    end)
    Btn.MouseButton1Click:Connect(function()
        PlayClickSound()
        ActiveTPSection = name
        for k, v in pairs(TPFrames) do v.Visible = (k == name) end
        for k, v in pairs(TPSections) do
            v.BackgroundColor3 = (k == name) and CurrentTheme.Primary or SidebarColor()
            v.TextColor3 = (k == name) and Color3.fromRGB(255,255,255) or CurrentTheme.Text
        end
    end)
end
CreateTPSubTab("All Players", UDim2.new(0, 0, 0, 0))
CreateTPSubTab("Friends", UDim2.new(0, 122, 0, 0))
CreateTPSubTab("Not Friends", UDim2.new(0, 244, 0, 0))

local function PopulateTPLists()
    for _, frame in pairs(TPFrames) do for _, child in ipairs(frame:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local isFriend = false pcall(function() isFriend = LocalPlayer:IsFriendsWith(p.UserId) end)
            local function AddPlayerButton(container)
                local Item = Instance.new("Frame") Item.Size = UDim2.new(1, -5, 0, 32) Item.BackgroundColor3 = SidebarColor() Item.Parent = container
                local Corner = Instance.new("UICorner") Corner.CornerRadius = UDim.new(0, 6) Corner.Parent = Item
                local NameLbl = Instance.new("TextLabel") NameLbl.Size = UDim2.new(0.6, 0, 1, 0) NameLbl.Position = UDim2.new(0, 8, 0, 0) NameLbl.BackgroundTransparency = 1 NameLbl.Text = p.DisplayName NameLbl.TextColor3 = CurrentTheme.Text NameLbl.Font = Enum.Font.GothamBold NameLbl.TextSize = 11 NameLbl.TextXAlignment = Enum.TextXAlignment.Left NameLbl.Parent = Item
                local TPBtn = Instance.new("TextButton") TPBtn.Size = UDim2.new(0, 75, 0, 22) TPBtn.Position = UDim2.new(1, -80, 0.5, -11) TPBtn.BackgroundColor3 = CurrentTheme.Primary TPBtn.Text = "Teleport" TPBtn.TextColor3 = Color3.fromRGB(255,255,255) TPBtn.Font = Enum.Font.GothamBold TPBtn.TextSize = 10 TPBtn.Parent = Item
                local BtnCorner = Instance.new("UICorner") BtnCorner.CornerRadius = UDim.new(0, 5) BtnCorner.Parent = TPBtn
                TPBtn.MouseButton1Click:Connect(function()
                    PlayClickSound()
                    local myChar = LocalPlayer.Character
                    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and myChar and myChar:FindFirstChild("HumanoidRootPart") then
                        myChar.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame
                    end
                end)
            end
            AddPlayerButton(TPFrames["All Players"])
            if isFriend then AddPlayerButton(TPFrames["Friends"]) else AddPlayerButton(TPFrames["Not Friends"]) end
        end
    end
end
PopulateTPLists()
table.insert(Connections, Players.PlayerAdded:Connect(PopulateTPLists))
table.insert(Connections, Players.PlayerRemoving:Connect(PopulateTPLists))
TPFrames["All Players"].Visible = true
TPSections["All Players"].BackgroundColor3 = CurrentTheme.Primary
TPSections["All Players"].TextColor3 = Color3.fromRGB(255,255,255)

-- ==================== TAB: SKY / FOG ====================
local FogPage = Pages["Sky / Fog"]
local OriginalLighting = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, GlobalShadows = Lighting.GlobalShadows, OutdoorAmbient = Lighting.OutdoorAmbient, FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd, FogColor = Lighting.FogColor }

local function UpdateWorldFog()
    if Settings.CustomFogEnabled then
        pcall(function()
            Lighting.FogColor = Settings.CustomFogColor
            Lighting.FogStart = Settings.CustomFogStart
            Lighting.FogEnd = Settings.CustomFogEnd
        end)
    else
        pcall(function()
            Lighting.FogColor = OriginalLighting.FogColor
            Lighting.FogStart = OriginalLighting.FogStart
            Lighting.FogEnd = OriginalLighting.FogEnd
        end)
    end
end

CreateLabel(FogPage, "Environment Settings", CurrentTheme.Primary, 14, 24, true)
CreateToggle(FogPage, " Custom Fog", "CustomFogEnabled", function(s) Settings.CustomFogEnabled = s UpdateWorldFog() end)
CreateSlider(FogPage, "Fog Start", 0, 10000, 0, false, "CustomFogStart", function(v) Settings.CustomFogStart = v if Settings.CustomFogEnabled then UpdateWorldFog() end end)
CreateSlider(FogPage, "Fog End", 10, 20000, 1000, false, "CustomFogEnd", function(v) Settings.CustomFogEnd = v if Settings.CustomFogEnabled then UpdateWorldFog() end end)
CreateColorGrid(FogPage, "Fog Color", function(col) Settings.CustomFogColor = col if Settings.CustomFogEnabled then UpdateWorldFog() end end)
CreateToggle(FogPage, " Fullbright (World Light)", "Fullbright", function(s)
    Settings.Fullbright = s
    if s then pcall(function() Lighting.Brightness = 3 Lighting.GlobalShadows = false Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255) end)
    else pcall(function() Lighting.Brightness = OriginalLighting.Brightness Lighting.GlobalShadows = OriginalLighting.GlobalShadows Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient end) end
end)
CreateToggle(FogPage, " Force Time", "ForceTimeEnabled", function(s) Settings.ForceTimeEnabled = s if s then pcall(function() Lighting.ClockTime = Settings.ForceTime end) else pcall(function() Lighting.ClockTime = OriginalLighting.ClockTime end) end end)
CreateSlider(FogPage, " Time Of Day", 0, 24, 14, true, "ForceTime", function(v) Settings.ForceTime = v if Settings.ForceTimeEnabled then pcall(function() Lighting.ClockTime = v end) end end, "h")

table.insert(Connections, RunService.Heartbeat:Connect(function()
    if Settings.ForceTimeEnabled then
        pcall(function()
            if math.abs(Lighting.ClockTime - Settings.ForceTime) > 0.05 then
                Lighting.ClockTime = Settings.ForceTime
            end
        end)
    end
    if Settings.CustomFogEnabled then
        pcall(function()
            if Lighting.FogColor ~= Settings.CustomFogColor then Lighting.FogColor = Settings.CustomFogColor end
            if math.abs(Lighting.FogStart - Settings.CustomFogStart) > 0.5 then Lighting.FogStart = Settings.CustomFogStart end
            if math.abs(Lighting.FogEnd - Settings.CustomFogEnd) > 0.5 then Lighting.FogEnd = Settings.CustomFogEnd end
        end)
    end
end))

-- ==================== TAB: ESP ====================
local ESPPage = Pages["ESP"]
CreateLabel(ESPPage, " Info", CurrentTheme.Primary, 14, 24, true)
CreateToggle(ESPPage, "Name", "ESP_Name", function(s) Settings.ESP_Name = s end)
CreateToggle(ESPPage, "Distance", "ESP_Distance", function(s) Settings.ESP_Distance = s end)
CreateToggle(ESPPage, "Speed", "ESP_Speed", function(s) Settings.ESP_Speed = s end)
CreateToggle(ESPPage, "Item Held", "ESP_ItemHeld", function(s) Settings.ESP_ItemHeld = s end)
CreateToggle(ESPPage, "Alive / Dead", "ESP_AliveDead", function(s) Settings.ESP_AliveDead = s end)
CreateLabel(ESPPage, " Visuals", CurrentTheme.Primary, 14, 24, true)
CreateToggle(ESPPage, "Tracers", "ESP_Tracer", function(s) Settings.ESP_Tracer = s end)
CreateToggle(ESPPage, "Skeleton", "ESP_Skeleton", function(s) Settings.ESP_Skeleton = s end)
CreateColorGrid(ESPPage, "ESP Color", function(col) ESPColor = col end)
CreateColorGrid(ESPPage, "Skeleton Color", function(col) SkeletonColor = col end)

local SKELETON_R15 = {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"}
}
local SKELETON_R6 = {
    {"Head","Torso"}, {"Torso","Left Arm"}, {"Torso","Right Arm"}, {"Torso","Left Leg"}, {"Torso","Right Leg"}
}
local MAX_BONES = #SKELETON_R15
local ESPCache = {}

local function GetPlayerESP(p)
    if not ESPCache[p] then
        local bones = {}
        for i = 1, MAX_BONES do
            local l = DrawingLib.new("Line")
            l.Thickness = 1.5
            l.Visible = false
            bones[i] = l
        end
        local info = DrawingLib.new("Text")
        info.Size = 13
        info.Center = true
        info.Outline = true
        info.Color = Color3.fromRGB(255,255,255)
        local tracer = DrawingLib.new("Line")
        tracer.Thickness = 1.5
        tracer.Visible = false
        ESPCache[p] = { Info = info, Tracer = tracer, Bones = bones }
    end
    return ESPCache[p]
end

local function HideESP(esp)
    esp.Info.Visible = false
    esp.Tracer.Visible = false
    for _, l in ipairs(esp.Bones) do l.Visible = false end
end

local function RemoveESP(p)
    local esp = ESPCache[p]
    if esp then
        pcall(function()
            esp.Info:Remove()
            esp.Tracer:Remove()
            for _, l in ipairs(esp.Bones) do l:Remove() end
        end)
        ESPCache[p] = nil
    end
end
table.insert(Connections, Players.PlayerRemoving:Connect(RemoveESP))

table.insert(Connections, RunService.RenderStepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local esp = GetPlayerESP(p)
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if char and hum and hrp then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen and pos.Z > 0 then
                    local topV = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                    local lines = {}
                    local myChar = LocalPlayer.Character
                    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if Settings.ESP_Name then table.insert(lines, p.DisplayName) end
                    if Settings.ESP_Distance then
                        local dist = myHrp and math.floor((myHrp.Position - hrp.Position).Magnitude) or 0
                        table.insert(lines, "[" .. dist .. "m]")
                    end
                    if Settings.ESP_Speed then table.insert(lines, "Speed: " .. math.floor(hrp.AssemblyLinearVelocity.Magnitude + 0.5)) end
                    if Settings.ESP_ItemHeld then
                        local tool = char:FindFirstChildOfClass("Tool")
                        table.insert(lines, "Item: " .. (tool and tool.Name or "None"))
                    end
                    if Settings.ESP_AliveDead then table.insert(lines, hum.Health > 0 and "Alive " or "Dead ") end
                    if #lines > 0 then
                        esp.Info.Visible = true
                        esp.Info.Text = table.concat(lines, "\n")
                        esp.Info.Color = ESPColor
                        esp.Info.Position = Vector2.new(pos.X, topV.Y - 10 - (#lines * 7))
                    else
                        esp.Info.Visible = false
                    end

                    esp.Tracer.Visible = Settings.ESP_Tracer
                    if Settings.ESP_Tracer then
                        esp.Tracer.Color = ESPColor
                        esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                    end

                    if Settings.ESP_Skeleton then
                        local rig = char:FindFirstChild("UpperTorso") and SKELETON_R15 or SKELETON_R6
                        local idx = 1
                        for _, pair in ipairs(rig) do
                            local line = esp.Bones[idx]
                            local pA = char:FindFirstChild(pair[1])
                            local pB = char:FindFirstChild(pair[2])
                            if line and pA and pB then
                                local a, aOn = Camera:WorldToViewportPoint(pA.Position)
                                local b, bOn = Camera:WorldToViewportPoint(pB.Position)
                                if aOn and bOn and a.Z > 0 and b.Z > 0 then
                                    line.Visible = true
                                    line.Color = SkeletonColor
                                    line.From = Vector2.new(a.X, a.Y)
                                    line.To = Vector2.new(b.X, b.Y)
                                else
                                    line.Visible = false
                                end
                            elseif line then
                                line.Visible = false
                            end
                            idx = idx + 1
                        end
                        for i = idx, MAX_BONES do esp.Bones[i].Visible = false end
                    else
                        for _, l in ipairs(esp.Bones) do l.Visible = false end
                    end
                else
                    HideESP(esp)
                end
            else
                HideESP(esp)
            end
        end
    end
end))

-- ==================== TAB: CONFIGS ====================
local ConfigsPage = Pages["Configs"]
local SelectedConfig = nil
local RefreshThemeRows = function() end

CreateLabel(ConfigsPage, " Config Manager", CurrentTheme.Primary, 14, 24, true)

local ConfigInput = Instance.new("TextBox")
ConfigInput.Size = UDim2.new(1, -10, 0, 32)
ConfigInput.BackgroundColor3 = SidebarColor()
ConfigInput.PlaceholderText = "Enter config name..."
ConfigInput.Text = ""
ConfigInput.TextColor3 = CurrentTheme.Text
ConfigInput.PlaceholderColor3 = Color3.fromRGB(120,120,130)
ConfigInput.Font = Enum.Font.GothamMedium
ConfigInput.TextSize = 12
ConfigInput.ClearTextOnFocus = false
ConfigInput.Parent = ConfigsPage
Instance.new("UICorner", ConfigInput).CornerRadius = UDim.new(0, 8)
table.insert(ThemeUpdaters, function() ConfigInput.BackgroundColor3 = SidebarColor() ConfigInput.TextColor3 = CurrentTheme.Text end)

local function BuildConfigData()
    return {
        Walkspeed = Settings.Walkspeed, JumpPower = Settings.JumpPower,
        SpeedEnabled = Settings.SpeedEnabled, JumpEnabled = Settings.JumpEnabled, Noclip = Settings.Noclip,
        ESP_Name = Settings.ESP_Name, ESP_Distance = Settings.ESP_Distance, ESP_Speed = Settings.ESP_Speed,
        ESP_ItemHeld = Settings.ESP_ItemHeld, ESP_AliveDead = Settings.ESP_AliveDead,
        ESP_Tracer = Settings.ESP_Tracer, ESP_Skeleton = Settings.ESP_Skeleton,
        HitboxEnabled = Settings.HitboxEnabled, HitboxSize = Settings.HitboxSize, ShowHitbox = Settings.ShowHitbox,
        AimPart = Settings.AimPart, Camlock = Settings.Camlock, CamlockSmoothness = Settings.CamlockSmoothness * 10,
        GunLight = Settings.GunLight, GunFlashBrightness = GunFlashBrightness, GunFlashDuration = GunFlashDuration,
        Fullbright = Settings.Fullbright,
        CustomFogEnabled = Settings.CustomFogEnabled, CustomFogColor = ColorToTable(Settings.CustomFogColor),
        CustomFogStart = Settings.CustomFogStart, CustomFogEnd = Settings.CustomFogEnd,
        ForceTimeEnabled = Settings.ForceTimeEnabled, ForceTime = Settings.ForceTime,
        ESPColor = ColorToTable(ESPColor), SkeletonColor = ColorToTable(SkeletonColor),
        HitboxColor = ColorToTable(HitboxColor), GunFlashColor = ColorToTable(GunFlashColor),
        Theme = { Primary = ColorToTable(CurrentTheme.Primary), Text = ColorToTable(CurrentTheme.Text), Outline = ColorToTable(CurrentTheme.Outline), BG = ColorToTable(CurrentTheme.BG) },
        OutlineEnabled = OutlineEnabled,
        Keybinds = { Menu = CurrentToggleKey.Name, Speed = SpeedKeyBind.Name, Jump = JumpKeyBind.Name, Noclip = NoclipKeyBind.Name, Camlock = CamlockKey.Name }
    }
end

local function ApplyConfigData(data)
    local ToggleKeys = {"SpeedEnabled","JumpEnabled","Noclip","ESP_Name","ESP_Distance","ESP_Speed","ESP_ItemHeld","ESP_AliveDead","ESP_Tracer","ESP_Skeleton","HitboxEnabled","ShowHitbox","Camlock","GunLight","Fullbright","CustomFogEnabled","ForceTimeEnabled"}
    for _, k in ipairs(ToggleKeys) do
        if data[k] ~= nil and ToggleElements[k] then ToggleElements[k](data[k] and true or false) end
    end
    local SliderKeys = {"Walkspeed","JumpPower","CamlockSmoothness","HitboxSize","GunFlashBrightness","GunFlashDuration","CustomFogStart","CustomFogEnd","ForceTime"}
    for _, k in ipairs(SliderKeys) do
        if data[k] ~= nil and SliderElements[k] then SliderElements[k](data[k]) end
    end
    if data.AimPart then Settings.AimPart = data.AimPart end
    if data.ESPColor then ESPColor = TableToColor(data.ESPColor) end
    if data.SkeletonColor then SkeletonColor = TableToColor(data.SkeletonColor) end
    if data.HitboxColor then HitboxColor = TableToColor(data.HitboxColor) end
    if data.GunFlashColor then GunFlashColor = TableToColor(data.GunFlashColor) end
    if data.CustomFogColor then Settings.CustomFogColor = TableToColor(data.CustomFogColor) if Settings.CustomFogEnabled then UpdateWorldFog() end end
    if data.Theme then
        CurrentTheme.Primary = TableToColor(data.Theme.Primary)
        CurrentTheme.Text = TableToColor(data.Theme.Text)
        CurrentTheme.Outline = TableToColor(data.Theme.Outline)
        CurrentTheme.BG = TableToColor(data.Theme.BG)
        RefreshTheme()
        RefreshThemeRows()
    end
    if data.OutlineEnabled ~= nil and ToggleElements["OutlineMaster"] then ToggleElements["OutlineMaster"](data.OutlineEnabled) end
end

local function EnsureConfigFolder()
    pcall(function()
        if makefolder and isfolder and not isfolder(ConfigsFolder) then makefolder(ConfigsFolder) end
    end)
end

local function ListConfigs()
    local list = {}
    pcall(function()
        if listfiles then
            EnsureConfigFolder()
            for _, f in ipairs(listfiles(ConfigsFolder)) do
                local name = f:match("([^/\\]+)%.json$")
                if name then table.insert(list, name) end
            end
        end
    end)
    table.sort(list)
    return list
end

local DropBtn = Instance.new("TextButton")
DropBtn.Size = UDim2.new(1, -10, 0, 32)
DropBtn.BackgroundColor3 = SidebarColor()
DropBtn.Text = "    Select Config..."
DropBtn.TextColor3 = CurrentTheme.Text
DropBtn.Font = Enum.Font.GothamBold
DropBtn.TextSize = 12
DropBtn.TextXAlignment = Enum.TextXAlignment.Left
DropBtn.Parent = ConfigsPage
Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 8)
table.insert(ThemeUpdaters, function() DropBtn.BackgroundColor3 = SidebarColor() DropBtn.TextColor3 = CurrentTheme.Text end)

local DropList = Instance.new("ScrollingFrame")
DropList.Size = UDim2.new(1, -10, 0, 0)
DropList.BackgroundColor3 = SidebarColor()
DropList.BorderSizePixel = 0
DropList.ScrollBarThickness = 3
DropList.ScrollBarImageColor3 = CurrentTheme.Primary
DropList.AutomaticCanvasSize = Enum.AutomaticSize.Y
DropList.CanvasSize = UDim2.new(0, 0, 0, 0)
DropList.Visible = false
DropList.Parent = ConfigsPage
Instance.new("UICorner", DropList).CornerRadius = UDim.new(0, 8)
local DropLayout = Instance.new("UIListLayout") DropLayout.Padding = UDim.new(0, 4) DropLayout.Parent = DropList
local DropPad = Instance.new("UIPadding") DropPad.PaddingTop = UDim.new(0, 6) DropPad.PaddingLeft = UDim.new(0, 6) DropPad.PaddingRight = UDim.new(0, 6) DropPad.PaddingBottom = UDim.new(0, 6) DropPad.Parent = DropList
table.insert(ThemeUpdaters, function() DropList.BackgroundColor3 = SidebarColor() DropList.ScrollBarImageColor3 = CurrentTheme.Primary end)

local function RefreshConfigList()
    for _, c in ipairs(DropList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, name in ipairs(ListConfigs()) do
        local B = Instance.new("TextButton")
        B.Size = UDim2.new(1, -6, 0, 26)
        B.BackgroundColor3 = CurrentTheme.BG
        B.Text = "   " .. name
        B.TextColor3 = CurrentTheme.Text
        B.Font = Enum.Font.GothamMedium
        B.TextSize = 11
        B.TextXAlignment = Enum.TextXAlignment.Left
        B.Parent = DropList
        Instance.new("UICorner", B).CornerRadius = UDim.new(0, 6)
        B.MouseButton1Click:Connect(function()
            PlayClickSound()
            SelectedConfig = name
            DropBtn.Text = "    " .. name
            DropList.Visible = false
            DropList.Size = UDim2.new(1, -10, 0, 0)
        end)
    end
end

DropBtn.MouseButton1Click:Connect(function()
    PlayClickSound()
    if DropList.Visible then
        DropList.Visible = false
        DropList.Size = UDim2.new(1, -10, 0, 0)
    else
        RefreshConfigList()
        DropList.Size = UDim2.new(1, -10, 0, 110)
        DropList.Visible = true
    end
end)

CreateButton(ConfigsPage, " Save Config", function()
    local name = ConfigInput.Text ~= "" and ConfigInput.Text or "Default"
    EnsureConfigFolder()
    pcall(function()
        if writefile then writefile(ConfigsFolder .. "/" .. name .. ".json", HttpService:JSONEncode(BuildConfigData())) end
    end)
    SelectedConfig = name
    DropBtn.Text = "    " .. name
    ConfigInput.Text = ""
    RefreshConfigList()
end)

CreateButton(ConfigsPage, " Load Config", function()
    if not SelectedConfig then return end
    pcall(function()
        if readfile and isfile and isfile(ConfigsFolder .. "/" .. SelectedConfig .. ".json") then
            ApplyConfigData(HttpService:JSONDecode(readfile(ConfigsFolder .. "/" .. SelectedConfig .. ".json")))
        end
    end)
end)

CreateButton(ConfigsPage, " Delete Config", function()
    if not SelectedConfig then return end
    pcall(function()
        if delfile and isfile and isfile(ConfigsFolder .. "/" .. SelectedConfig .. ".json") then
            delfile(ConfigsFolder .. "/" .. SelectedConfig .. ".json")
        end
    end)
    SelectedConfig = nil
    DropBtn.Text = "    Select Config..."
    RefreshConfigList()
end)

CreateButton(ConfigsPage, " Refresh List", function() RefreshConfigList() end)

-- ==================== TAB: SETTINGS ====================
local SettingsPage = Pages["Settings"]
KeybindBtns["Menu"] = CreateKeybind(SettingsPage, " Menu Keybind", CurrentToggleKey, function(k) CurrentToggleKey = k end)

local OutlineMasterSet = CreateToggle(SettingsPage, " Outline (Master)", "OutlineMaster", function(s)
    OutlineEnabled = s
    RefreshTheme()
end)
OutlineMasterSet(true)

local PickerFrame = Instance.new("Frame")
PickerFrame.Size = UDim2.new(0, 300, 0, 305)
PickerFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
PickerFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
PickerFrame.BorderSizePixel = 0
PickerFrame.Visible = false
PickerFrame.ZIndex = 50
PickerFrame.Active = true
PickerFrame.Parent = MainFrame
Instance.new("UICorner", PickerFrame).CornerRadius = UDim.new(0, 10)
local PickerStroke = Instance.new("UIStroke") PickerStroke.Thickness = 1.5 PickerStroke.Color = CurrentTheme.Primary PickerStroke.Parent = PickerFrame
table.insert(ThemeUpdaters, function() PickerStroke.Color = CurrentTheme.Primary end)

local PickerPreview = Instance.new("Frame")
PickerPreview.Size = UDim2.new(0, 24, 0, 24)
PickerPreview.Position = UDim2.new(0, 12, 0, 10)
PickerPreview.BackgroundColor3 = Color3.new(1, 1, 1)
PickerPreview.ZIndex = 51
PickerPreview.Parent = PickerFrame
Instance.new("UICorner", PickerPreview).CornerRadius = UDim.new(0, 5)

local PickerTitle = Instance.new("TextLabel")
PickerTitle.Size = UDim2.new(1, -80, 0, 24)
PickerTitle.Position = UDim2.new(0, 44, 0, 10)
PickerTitle.BackgroundTransparency = 1
PickerTitle.Text = "Color"
PickerTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
PickerTitle.Font = Enum.Font.GothamBold
PickerTitle.TextSize = 14
PickerTitle.TextXAlignment = Enum.TextXAlignment.Left
PickerTitle.ZIndex = 51
PickerTitle.Parent = PickerFrame

local PickerClose = Instance.new("TextButton")
PickerClose.Size = UDim2.new(0, 24, 0, 24)
PickerClose.Position = UDim2.new(1, -32, 0, 10)
PickerClose.BackgroundTransparency = 1
PickerClose.Text = ""
PickerClose.TextColor3 = Color3.fromRGB(255, 80, 80)
PickerClose.Font = Enum.Font.GothamBold
PickerClose.TextSize = 14
PickerClose.ZIndex = 51
PickerClose.Parent = PickerFrame

local SVFrame = Instance.new("Frame")
SVFrame.Size = UDim2.new(1, -24, 0, 150)
SVFrame.Position = UDim2.new(0, 12, 0, 44)
SVFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
SVFrame.BorderSizePixel = 0
SVFrame.ZIndex = 51
SVFrame.Active = true
SVFrame.Parent = PickerFrame
Instance.new("UICorner", SVFrame).CornerRadius = UDim.new(0, 6)

local SVWhite = Instance.new("Frame")
SVWhite.Size = UDim2.new(1, 0, 1, 0)
SVWhite.BackgroundColor3 = Color3.new(1, 1, 1)
SVWhite.BorderSizePixel = 0
SVWhite.ZIndex = 52
SVWhite.Parent = SVFrame
Instance.new("UICorner", SVWhite).CornerRadius = UDim.new(0, 6)
local SVWhiteGrad = Instance.new("UIGradient")
SVWhiteGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
SVWhiteGrad.Parent = SVWhite

local SVBlack = Instance.new("Frame")
SVBlack.Size = UDim2.new(1, 0, 1, 0)
SVBlack.BackgroundColor3 = Color3.new(0, 0, 0)
SVBlack.BorderSizePixel = 0
SVBlack.ZIndex = 53
SVBlack.Parent = SVFrame
Instance.new("UICorner", SVBlack).CornerRadius = UDim.new(0, 6)
local SVBlackGrad = Instance.new("UIGradient")
SVBlackGrad.Rotation = 90
SVBlackGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
SVBlackGrad.Parent = SVBlack

local SVKnob = Instance.new("Frame")
SVKnob.Size = UDim2.new(0, 12, 0, 12)
SVKnob.AnchorPoint = Vector2.new(0.5, 0.5)
SVKnob.Position = UDim2.new(1, 0, 0, 0)
SVKnob.BackgroundColor3 = Color3.new(1, 1, 1)
SVKnob.BorderSizePixel = 0
SVKnob.ZIndex = 55
SVKnob.Parent = SVFrame
Instance.new("UICorner", SVKnob).CornerRadius = UDim.new(0, 3)
local SVKnobStroke = Instance.new("UIStroke") SVKnobStroke.Thickness = 1.5 SVKnobStroke.Color = Color3.new(0, 0, 0) SVKnobStroke.Parent = SVKnob

local HueFrame = Instance.new("Frame")
HueFrame.Size = UDim2.new(1, -24, 0, 16)
HueFrame.Position = UDim2.new(0, 12, 0, 204)
HueFrame.BackgroundColor3 = Color3.new(1, 1, 1)
HueFrame.BorderSizePixel = 0
HueFrame.ZIndex = 51
HueFrame.Active = true
HueFrame.Parent = PickerFrame
Instance.new("UICorner", HueFrame).CornerRadius = UDim.new(0, 6)
local HueGrad = Instance.new("UIGradient")
HueGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
})
HueGrad.Parent = HueFrame

local HueKnob = Instance.new("Frame")
HueKnob.Size = UDim2.new(0, 10, 0, 22)
HueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
HueKnob.Position = UDim2.new(0, 0, 0.5, 0)
HueKnob.BackgroundColor3 = Color3.new(1, 1, 1)
HueKnob.BorderSizePixel = 0
HueKnob.ZIndex = 55
HueKnob.Parent = HueFrame
Instance.new("UICorner", HueKnob).CornerRadius = UDim.new(0, 3)
local HueKnobStroke = Instance.new("UIStroke") HueKnobStroke.Thickness = 1.5 HueKnobStroke.Color = Color3.new(0, 0, 0) HueKnobStroke.Parent = HueKnob

local HexLabel = Instance.new("TextLabel")
HexLabel.Size = UDim2.new(1, -24, 0, 22)
HexLabel.Position = UDim2.new(0, 12, 0, 230)
HexLabel.BackgroundTransparency = 1
HexLabel.Text = "#FF0000"
HexLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
HexLabel.Font = Enum.Font.GothamBold
HexLabel.TextSize = 14
HexLabel.ZIndex = 51
HexLabel.Parent = PickerFrame

local RGBBoxes = {}
local rgbLabels = { "R", "G", "B" }
for i = 1, 3 do
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(0, 18, 0, 20)
    L.Position = UDim2.new(0, 14 + (i - 1) * 96, 0, 262)
    L.BackgroundTransparency = 1
    L.Text = rgbLabels[i]
    L.TextColor3 = Color3.fromRGB(150, 150, 160)
    L.Font = Enum.Font.GothamBold
    L.TextSize = 12
    L.ZIndex = 51
    L.Parent = PickerFrame
    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(0, 62, 0, 24)
    Box.Position = UDim2.new(0, 34 + (i - 1) * 96, 0, 260)
    Box.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    Box.Text = "255"
    Box.TextColor3 = Color3.new(1, 1, 1)
    Box.Font = Enum.Font.GothamBold
    Box.TextSize = 12
    Box.ZIndex = 51
    Box.ClearTextOnFocus = false
    Box.Parent = PickerFrame
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)
    RGBBoxes[i] = Box
end

local PickerState = { H = 0, S = 1, V = 1, Callback = nil }

local function PickerComputeColor()
    return Color3.fromHSV(PickerState.H, PickerState.S, PickerState.V)
end

local function PickerRefreshUI()
    local col = PickerComputeColor()
    SVFrame.BackgroundColor3 = Color3.fromHSV(PickerState.H, 1, 1)
    SVKnob.Position = UDim2.new(PickerState.S, 0, 1 - PickerState.V, 0)
    HueKnob.Position = UDim2.new(PickerState.H, 0, 0.5, 0)
    PickerPreview.BackgroundColor3 = col
    HexLabel.Text = "#" .. string.upper(col:ToHex())
    RGBBoxes[1].Text = tostring(math.floor(col.R * 255 + 0.5))
    RGBBoxes[2].Text = tostring(math.floor(col.G * 255 + 0.5))
    RGBBoxes[3].Text = tostring(math.floor(col.B * 255 + 0.5))
    if PickerState.Callback then PickerState.Callback(col) end
end

local svDragging, hueDragging = false, false

local function UpdateSVFromInput(input)
    local px = math.clamp((input.Position.X - SVFrame.AbsolutePosition.X) / SVFrame.AbsoluteSize.X, 0, 1)
    local py = math.clamp((input.Position.Y - SVFrame.AbsolutePosition.Y) / SVFrame.AbsoluteSize.Y, 0, 1)
    PickerState.S = px
    PickerState.V = 1 - py
    PickerRefreshUI()
end

local function UpdateHueFromInput(input)
    PickerState.H = math.clamp((input.Position.X - HueFrame.AbsolutePosition.X) / HueFrame.AbsoluteSize.X, 0, 0.9999)
    PickerRefreshUI()
end

SVFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        svDragging = true
        UpdateSVFromInput(input)
    end
end)
HueFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        hueDragging = true
        UpdateHueFromInput(input)
    end
end)
table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        svDragging = false
        hueDragging = false
    end
end))
table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if svDragging then UpdateSVFromInput(input)
        elseif hueDragging then UpdateHueFromInput(input) end
    end
end))

for i, box in ipairs(RGBBoxes) do
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then
            n = math.clamp(math.floor(n), 0, 255)
            local col = PickerComputeColor()
            local r = math.floor(col.R * 255 + 0.5)
            local g = math.floor(col.G * 255 + 0.5)
            local b = math.floor(col.B * 255 + 0.5)
            if i == 1 then r = n elseif i == 2 then g = n else b = n end
            local h, s, v = Color3.toHSV(Color3.fromRGB(r, g, b))
            PickerState.H, PickerState.S, PickerState.V = h, s, v
            PickerRefreshUI()
        end
    end)
end

local function OpenPicker(title, startColor, callback)
    PickerTitle.Text = title
    local h, s, v = Color3.toHSV(startColor)
    PickerState.H, PickerState.S, PickerState.V = h, s, v
    PickerState.Callback = callback
    PickerFrame.Visible = true
    PickerRefreshUI()
end

PickerClose.MouseButton1Click:Connect(function()
    PlayClickSound()
    PickerFrame.Visible = false
end)

CreateLabel(SettingsPage, " Theme Colors", CurrentTheme.Primary, 14, 24, true)

local ThemeRowPreviews = {}
local function CreateThemeRow(labelText, getColor, setColor)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 36)
    Frame.BackgroundColor3 = SidebarColor()
    Frame.Parent = SettingsPage
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(0, 22, 0, 22)
    Box.Position = UDim2.new(0, 8, 0.5, -11)
    Box.BackgroundColor3 = getColor()
    Box.Parent = Frame
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 5)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 1, 0)
    Label.Position = UDim2.new(0, 38, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = labelText
    Label.TextColor3 = CurrentTheme.Text
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    local EditBtn = Instance.new("TextButton")
    EditBtn.Size = UDim2.new(0, 70, 0, 24)
    EditBtn.Position = UDim2.new(1, -78, 0.5, -12)
    EditBtn.BackgroundColor3 = CurrentTheme.Primary
    EditBtn.Text = "Edit"
    EditBtn.TextColor3 = Color3.new(1, 1, 1)
    EditBtn.Font = Enum.Font.GothamBold
    EditBtn.TextSize = 11
    EditBtn.Parent = Frame
    Instance.new("UICorner", EditBtn).CornerRadius = UDim.new(0, 6)
    EditBtn.MouseButton1Click:Connect(function()
        PlayClickSound()
        OpenPicker(labelText, getColor(), function(col)
            setColor(col)
            Box.BackgroundColor3 = col
            RefreshTheme()
        end)
    end)
    table.insert(ThemeUpdaters, function()
        Frame.BackgroundColor3 = SidebarColor()
        Label.TextColor3 = CurrentTheme.Text
        EditBtn.BackgroundColor3 = CurrentTheme.Primary
    end)
    table.insert(ThemeRowPreviews, function() Box.BackgroundColor3 = getColor() end)
end

CreateThemeRow("Accent", function() return CurrentTheme.Primary end, function(c) CurrentTheme.Primary = c end)
CreateThemeRow("Text", function() return CurrentTheme.Text end, function(c) CurrentTheme.Text = c end)
CreateThemeRow("Outline", function() return CurrentTheme.Outline end, function(c) CurrentTheme.Outline = c end)
CreateThemeRow("Background", function() return CurrentTheme.BG end, function(c) CurrentTheme.BG = c end)

RefreshThemeRows = function()
    for _, fn in ipairs(ThemeRowPreviews) do pcall(fn) end
end

CreateButton(SettingsPage, " Reset Theme to Default", function()
    CurrentTheme = CopyTheme(DefaultTheme)
    RefreshTheme()
    RefreshThemeRows()
end)

-- ==================== TAB: PLAYERS ====================
local PlayersPage = Pages["Players"]
CreateLabel(PlayersPage, " Session Info", CurrentTheme.Primary, 14, 24, true)

local GameName = "Unknown"
pcall(function() GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name end)
local RegionName = "Unknown"
pcall(function() RegionName = LocalizationService.RobloxLocaleId end)
task.spawn(function()
    pcall(function()
        local r = LocalizationService:GetCountryRegionForPlayerAsync(LocalPlayer)
        if r and r ~= "" then RegionName = r end
    end)
end)

local function CreateInfoRow(parent, title)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, 36)
    Frame.BackgroundColor3 = SidebarColor()
    Frame.Parent = parent
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(0.45, 0, 1, 0)
    L.Position = UDim2.new(0, 10, 0, 0)
    L.BackgroundTransparency = 1
    L.Text = title
    L.TextColor3 = CurrentTheme.Text
    L.Font = Enum.Font.GothamMedium
    L.TextSize = 12
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = Frame
    local V = Instance.new("TextLabel")
    V.Size = UDim2.new(0.5, -10, 1, 0)
    V.Position = UDim2.new(0.5, 0, 0, 0)
    V.BackgroundTransparency = 1
    V.Text = "..."
    V.TextColor3 = CurrentTheme.Primary
    V.Font = Enum.Font.GothamBold
    V.TextSize = 12
    V.TextXAlignment = Enum.TextXAlignment.Right
    V.TextTruncate = Enum.TextTruncate.AtEnd
    V.Parent = Frame
    table.insert(ThemeUpdaters, function()
        Frame.BackgroundColor3 = SidebarColor()
        L.TextColor3 = CurrentTheme.Text
        V.TextColor3 = CurrentTheme.Primary
    end)
    return V
end

local GameValue = CreateInfoRow(PlayersPage, " Game")
local PlaceValue = CreateInfoRow(PlayersPage, " Place ID")
local RegionValue = CreateInfoRow(PlayersPage, " Region")
local FPSValue = CreateInfoRow(PlayersPage, " FPS")
local CountValue = CreateInfoRow(PlayersPage, " Players in Server")
local PingValue = CreateInfoRow(PlayersPage, " Ping")

GameValue.Text = GameName
PlaceValue.Text = tostring(game.PlaceId)
RegionValue.Text = RegionName

local fpsFrames, fpsTimer = 0, 0
table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
    fpsFrames = fpsFrames + 1
    fpsTimer = fpsTimer + dt
    if fpsTimer >= 0.5 then
        FPSValue.Text = tostring(math.floor(fpsFrames / fpsTimer + 0.5))
        fpsFrames, fpsTimer = 0, 0
        CountValue.Text = #Players:GetPlayers() .. " / " .. tostring(Players.MaxPlayers)
        RegionValue.Text = RegionName
        local pingMs = 0
        pcall(function() pingMs = math.floor(LocalPlayer:GetNetworkPing() * 1000 + 0.5) end)
        PingValue.Text = tostring(pingMs) .. " ms"
    end
end))

-- ==================== UNLOAD ====================
UnloadHub = function()
    PlayClickSound()
    ClearJumpSignals()
    for _, conn in pairs(Connections) do pcall(function() conn:Disconnect() end) end
    for p in pairs(ESPCache) do RemoveESP(p) end
    for plr, h in pairs(Hitboxes) do if h.Part then pcall(function() h.Part:Destroy() end) end end
    pcall(function()
        Lighting.FogColor = OriginalLighting.FogColor
        Lighting.FogStart = OriginalLighting.FogStart
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    end)
    if PolyGui then PolyGui:Destroy() end
    ScreenGui:Destroy()
end

CloseBtn.MouseButton1Click:Connect(function() UnloadHub() end)

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == CurrentToggleKey then
        Settings.UIVisible = not Settings.UIVisible
        MainFrame.Visible = Settings.UIVisible
    end
end))

print("[CleanHub] Successfully loaded v5.1.0 with Smart AutoKill!")
