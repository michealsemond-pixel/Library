local InputService = game:GetService('UserInputService')
local TextService = game:GetService('TextService')
local CoreGui = game:GetService('CoreGui')
local Teams = game:GetService('Teams')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local RenderStepped = RunService.RenderStepped
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local ScreenGui = Instance.new('ScreenGui')
ProtectGui(ScreenGui)
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Toggles = {}
local Options = {}
getgenv().Toggles = Toggles
getgenv().Options = Options

local Library = {
    Registry = {},
    RegistryMap = {},
    HudRegistry = {},
    FontColor = Color3.fromRGB(220, 220, 230),
    DimColor = Color3.fromRGB(100, 100, 120),
    MutedColor = Color3.fromRGB(60, 60, 75),
    MainColor = Color3.fromRGB(22, 22, 30),
    BackgroundColor = Color3.fromRGB(12, 12, 16),
    SidebarColor = Color3.fromRGB(16, 16, 22),
    AccentColor = Color3.fromRGB(120, 180, 255),
    AccentDark = Color3.fromRGB(80, 130, 200),
    BorderColor = Color3.fromRGB(35, 35, 48),
    OutlineColor = Color3.fromRGB(35, 35, 48),
    SliderTrack = Color3.fromRGB(40, 40, 55),
    CardHover = Color3.fromRGB(30, 30, 40),
    Green = Color3.fromRGB(80, 220, 120),
    Red = Color3.fromRGB(220, 80, 80),
    RiskColor = Color3.fromRGB(255, 50, 50),
    Black = Color3.new(0, 0, 0),
    White = Color3.fromRGB(240, 240, 245),
    Font = Enum.Font.Gotham,
    ScreenGui = ScreenGui,
    Signals = {},
    OpenedFrames = {},
    DependencyBoxes = {},
    NotifyOnError = false,
    SaveManager = nil,
    OnUnload = nil,
    ColorClipboard = nil,
    CurrentRainbowHue = 0,
    CurrentRainbowColor = Color3.new(1, 1, 1),
}

-- Rainbow (kept for theme compatibility)
local RainbowStep = 0
local Hue = 0
table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta
    if RainbowStep >= (1 / 60) then
        RainbowStep = 0
        Hue = Hue + (1 / 400)
        if Hue > 1 then Hue = 0 end
        Library.CurrentRainbowHue = Hue
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers()
    for i = 1, #PlayerList do PlayerList[i] = PlayerList[i].Name end
    table.sort(PlayerList, function(a, b) return a < b end)
    return PlayerList
end

local function GetTeamsString()
    local TeamList = Teams:GetTeams()
    for i = 1, #TeamList do TeamList[i] = TeamList[i].Name end
    table.sort(TeamList, function(a, b) return a < b end)
    return TeamList
end

function Library:SafeCallback(f, ...)
    if not f then return end
    if not Library.NotifyOnError then return f(...) end
    local ok, err = pcall(f, ...)
    if not ok then
        local _, i = err:find(":%d+: ")
        Library:Notify(i and err:sub(i + 1) or err, 3)
    end
end

function Library:AttemptSave()
    if Library.SaveManager then Library.SaveManager:Save() end
end

function Library:Create(Class, Properties)
    local Inst = type(Class) == 'string' and Instance.new(Class) or Class
    for Prop, Val in next, Properties do Inst[Prop] = Val end
    return Inst
end

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1
    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0),
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = Inst,
    })
end

function Library:CreateLabel(Properties, IsHud)
    local Inst = Library:Create('TextLabel', {
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextColor3 = Library.FontColor,
        TextSize = 13,
        TextStrokeTransparency = 1,
    })
    Library:AddToRegistry(Inst, { TextColor3 = 'FontColor' }, IsHud)
    return Library:Create(Inst, Properties)
end

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(
                Mouse.X - Instance.AbsolutePosition.X,
                Mouse.Y - Instance.AbsolutePosition.Y
            )
            if ObjPos.Y > (Cutoff or 40) then return end
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                Instance.Position = UDim2.new(
                    0,
                    Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
                    0,
                    Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
                )
                RenderStepped:Wait()
            end
        end
    end)
end

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = TextService:GetTextSize(InfoStr, Library.Font, 12, Vector2.new(1920, 1080))
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Size = UDim2.fromOffset(X + 10, Y + 8),
        ZIndex = 100,
        Parent = Library.ScreenGui,
        Visible = false,
    })
    Library:Create('UICorner', { CornerRadius = UDim.new(0, 6), Parent = Tooltip })
    Library:CreateLabel({
        Position = UDim2.fromOffset(5, 2),
        Size = UDim2.fromOffset(X, Y),
        TextSize = 12,
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = Tooltip.ZIndex + 1,
        Parent = Tooltip,
    })
    Library:AddToRegistry(Tooltip, { BackgroundColor3 = 'MainColor', BorderColor3 = 'OutlineColor' })
    local IsHovering = false
    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then return end
        IsHovering = true
        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true
        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)
    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        for Property, ColorIdx in next, Properties do
            Instance[Property] = type(ColorIdx) == 'string' and Library[ColorIdx] or ColorIdx
        end
    end)
    HighlightInstance.MouseLeave:Connect(function()
        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = type(ColorIdx) == 'string' and Library[ColorIdx] or ColorIdx
        end
    end)
end

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
            return true
        end
    end
    return false
end

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
        return true
    end
    return false
end

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update()
    end
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB
end

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, V / 1.5)
end
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1
    local Data = { Instance = Instance, Properties = Properties, Idx = Idx }
    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data
    if IsHud then table.insert(Library.HudRegistry, Data) end
end

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance]
    if Data then
        for i = #Library.Registry, 1, -1 do
            if Library.Registry[i] == Data then table.remove(Library.Registry, i) end
        end
        for i = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[i] == Data then table.remove(Library.HudRegistry, i) end
        end
        Library.RegistryMap[Instance] = nil
    end
end

function Library:UpdateColorsUsingRegistry()
    for _, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == 'string' then
                Object.Instance[Property] = Library[ColorIdx]
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end
    end
end

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    for i = #Library.Signals, 1, -1 do
        table.remove(Library.Signals, i):Disconnect()
    end
    if Library.OnUnload then Library.OnUnload() end
    ScreenGui:Destroy()
end

function Library:OnUnload(cb) Library.OnUnload = cb end

function Library:Notify(Text, Duration)
    local NotifContainer = ScreenGui:FindFirstChild("NotifContainer")
    if not NotifContainer then
        NotifContainer = Library:Create('Frame', {
            Name = "NotifContainer",
            Size = UDim2.new(0, 240, 1, 0),
            Position = UDim2.new(1, -250, 0, 0),
            BackgroundTransparency = 1,
            Parent = ScreenGui,
        })
        Library:Create('UIListLayout', {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Parent = NotifContainer,
        })
        Library:Create('UIPadding', { PaddingBottom = UDim.new(0, 12), Parent = NotifContainer })
    end
    local f = Library:Create('Frame', {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        Parent = NotifContainer,
    })
    Library:Create('UICorner', { CornerRadius = UDim.new(0, 6), Parent = f })
    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = f })
    Library:Create('TextLabel', {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        TextColor3 = Library.AccentColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = Text or "Notification",
        Parent = f,
    })
    task.spawn(function()
        task.wait(Duration or 2.5)
        local tw = TweenService:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
        tw:Play()
        tw.Completed:Connect(function() f:Destroy() end)
    end)
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then Library:RemoveFromRegistry(Instance) end
end))

-- Fixed: strip CornerRadius before passing to Frame
local function RoundFrame(props)
    local radius = props.CornerRadius or 8
    props.CornerRadius = nil
    local f = Library:Create('Frame', props)
    Library:Create('UICorner', { CornerRadius = UDim.new(0, radius), Parent = f })
    return f
end

-- ========== Color Picker (standalone) ==========
local function CreateColorPicker(DispFrame, CInfo, Idx)
    CInfo = CInfo or {}
    CInfo.Default = CInfo.Default or Color3.new(1, 1, 1)
    local CP = {
        Value = CInfo.Default,
        Transparency = CInfo.Transparency or 0,
        Type = 'ColorPicker',
        Title = CInfo.Title or 'Color picker',
        Callback = CInfo.Callback or function() end,
    }
    Options[Idx] = CP

    local CheckerFrame = Library:Create('ImageLabel', {
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 5,
        Image = 'http://www.roblox.com/asset/?id=12977615774',
        Visible = not not CInfo.Transparency,
        Parent = DispFrame,
    })

    local PickerOuter = Library:Create('Frame', {
        Name = 'Color',
        BackgroundColor3 = Color3.new(0, 0, 0),
        Size = UDim2.fromOffset(230, CInfo.Transparency and 271 or 253),
        Visible = false,
        ZIndex = 15,
        Parent = ScreenGui,
    })
    local PickerInner = RoundFrame({
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.BackgroundColor,
        CornerRadius = 8,
        ZIndex = 16,
        Parent = PickerOuter,
    })
    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, ZIndex = 16, Parent = PickerInner })
    Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 17,
        Parent = PickerInner,
    })

    local SatVibMapOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0),
        Position = UDim2.new(0, 4, 0, 25),
        Size = UDim2.new(0, 200, 0, 200),
        ZIndex = 17,
        Parent = PickerInner,
    })
    local SatVibMapInner = RoundFrame({
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.BackgroundColor,
        CornerRadius = 0,
        ZIndex = 18,
        Parent = SatVibMapOuter,
    })
    local SatVibMap = Library:Create('ImageLabel', {
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 18,
        Image = 'rbxassetid://4155801252',
        Parent = SatVibMapInner,
    })
    local CursorOuter = Library:Create('ImageLabel', {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 6, 0, 6),
        BackgroundTransparency = 1,
        Image = 'http://www.roblox.com/asset/?id=9619665977',
        ImageColor3 = Color3.new(0, 0, 0),
        ZIndex = 19,
        Parent = SatVibMap,
    })
    local CursorInner = Library:Create('ImageLabel', {
        Size = UDim2.new(0, 4, 0, 4),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundTransparency = 1,
        Image = 'http://www.roblox.com/asset/?id=9619665977',
        ZIndex = 20,
        Parent = CursorOuter,
    })

    local HueOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0),
        Position = UDim2.new(0, 208, 0, 25),
        Size = UDim2.new(0, 15, 0, 200),
        ZIndex = 17,
        Parent = PickerInner,
    })
    local HueInner = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 18,
        Parent = HueOuter,
    })
    local HueCursor = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1),
        AnchorPoint = Vector2.new(0, 0.5),
        BorderColor3 = Color3.new(0, 0, 0),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 18,
        Parent = HueInner,
    })

    local SeqTable = {}
    for h = 0, 1, 0.1 do
        table.insert(SeqTable, ColorSequenceKeypoint.new(h, Color3.fromHSV(h, 1, 1)))
    end
    Library:Create('UIGradient', { Color = ColorSequence.new(SeqTable), Rotation = 90, Parent = HueInner })

    local HexBoxOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0),
        Position = UDim2.fromOffset(4, 228),
        Size = UDim2.new(0.5, -6, 0, 20),
        ZIndex = 18,
        Parent = PickerInner,
    })
    local HexBoxInner = RoundFrame({
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.MainColor,
        CornerRadius = 0,
        ZIndex = 18,
        Parent = HexBoxOuter,
    })
    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = HexBoxInner })
    local HexBox = Library:Create('TextBox', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 5, 0, 0),
        Size = UDim2.new(1, -5, 1, 0),
        Font = Library.Font,
        PlaceholderColor3 = Color3.fromRGB(190, 190, 190),
        PlaceholderText = 'Hex color',
        Text = '#FFFFFF',
        TextColor3 = Library.FontColor,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 20,
        Parent = HexBoxInner,
    })

    local RgbBoxOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0),
        Position = UDim2.new(0.5, 2, 0, 228),
        Size = UDim2.new(0.5, -6, 0, 20),
        ZIndex = 18,
        Parent = PickerInner,
    })
    local RgbBoxInner = RoundFrame({
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.MainColor,
        CornerRadius = 0,
        ZIndex = 18,
        Parent = RgbBoxOuter,
    })
    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = RgbBoxInner })
    local RgbBox = Library:Create('TextBox', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 5, 0, 0),
        Size = UDim2.new(1, -5, 1, 0),
        Font = Library.Font,
        PlaceholderColor3 = Color3.fromRGB(190, 190, 190),
        PlaceholderText = 'RGB color',
        Text = '255, 255, 255',
        TextColor3 = Library.FontColor,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 20,
        Parent = RgbBoxInner,
    })

    local TransBoxOuter, TransBoxInner, TransCursor
    if CInfo.Transparency then
        TransBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.fromOffset(4, 251),
            Size = UDim2.new(1, -8, 0, 15),
            ZIndex = 19,
            Parent = PickerInner,
        })
        TransBoxInner = RoundFrame({
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundColor3 = CP.Value,
            CornerRadius = 0,
            ZIndex = 19,
            Parent = TransBoxOuter,
        })
        Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = TransBoxInner })
        Library:Create('ImageLabel', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Image = 'http://www.roblox.com/asset/?id=12978095818',
            ZIndex = 20,
            Parent = TransBoxInner,
        })
        TransCursor = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1),
            AnchorPoint = Vector2.new(0.5, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 1, 1, 0),
            ZIndex = 21,
            Parent = TransBoxInner,
        })
    end

    Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.fromOffset(5, 5),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 13,
        Text = CP.Title,
        ZIndex = 16,
        Parent = PickerInner,
    })

    -- Context menu
    local ContextMenu = {}
    ContextMenu.Options = {}
    ContextMenu.Container = Library:Create('Frame', {
        BorderColor3 = Color3.new(),
        ZIndex = 14,
        Visible = false,
        Parent = ScreenGui,
    })
    ContextMenu.Inner = RoundFrame({
        BackgroundColor3 = Library.BackgroundColor,
        CornerRadius = 6,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 15,
        Parent = ContextMenu.Container,
    })
    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, ZIndex = 16, Parent = ContextMenu.Inner })
    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ContextMenu.Inner,
    })
    Library:Create('UIPadding', { PaddingLeft = UDim.new(0, 4), Parent = ContextMenu.Inner })

    local function updateMenuPos()
        ContextMenu.Container.Position = UDim2.fromOffset(
            DispFrame.AbsolutePosition.X + DispFrame.AbsoluteSize.X + 4,
            DispFrame.AbsolutePosition.Y + 1
        )
    end
    local function updateMenuSize()
        local w = 60
        for _, lbl in next, ContextMenu.Inner:GetChildren() do
            if lbl:IsA('TextLabel') then w = math.max(w, lbl.TextBounds.X) end
        end
        ContextMenu.Container.Size = UDim2.fromOffset(w + 8, ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4)
    end
    DispFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPos)
    ContextMenu.Inner:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)
    task.spawn(updateMenuPos)
    task.spawn(updateMenuSize)

    function ContextMenu:Show() self.Container.Visible = true end
    function ContextMenu:Hide() self.Container.Visible = false end
    function ContextMenu:AddOption(Str, Callback)
        if type(Callback) ~= 'function' then Callback = function() end end
        local Button = Library:CreateLabel({
            Active = false,
            Size = UDim2.new(1, 0, 0, 18),
            TextSize = 12,
            Text = Str,
            ZIndex = 16,
            Parent = self.Inner,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        Library:OnHighlight(Button, Button,
            { TextColor3 = 'AccentColor' },
            { TextColor3 = 'FontColor' }
        )
        Button.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then Callback() end
        end)
    end
    ContextMenu:AddOption('Copy color', function()
        Library.ColorClipboard = CP.Value
        Library:Notify('Copied color!', 2)
    end)
    ContextMenu:AddOption('Paste color', function()
        if not Library.ColorClipboard then return Library:Notify('No color copied!', 2) end
        CP:SetValueRGB(Library.ColorClipboard)
    end)
    ContextMenu:AddOption('Copy HEX', function()
        pcall(setclipboard, CP.Value:ToHex())
        Library:Notify('Copied hex!', 2)
    end)
    ContextMenu:AddOption('Copy RGB', function()
        pcall(setclipboard, table.concat({math.floor(CP.Value.R*255), math.floor(CP.Value.G*255), math.floor(CP.Value.B*255)}, ', '))
        Library:Notify('Copied RGB!', 2)
    end)

    -- Registry
    Library:AddToRegistry(PickerInner, { BackgroundColor3 = 'BackgroundColor' })
    Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor' })
    Library:AddToRegistry(HexBoxInner, { BackgroundColor3 = 'MainColor' })
    Library:AddToRegistry(RgbBoxInner, { BackgroundColor3 = 'MainColor' })
    Library:AddToRegistry(ContextMenu.Inner, { BackgroundColor3 = 'BackgroundColor' })

    local cH, cS, cV = Color3.toHSV(CP.Value)

    function CP:Display()
        CP.Value = Color3.fromHSV(cH, cS, cV)
        SatVibMap.BackgroundColor3 = Color3.fromHSV(cH, 1, 1)
        DispFrame.BackgroundColor3 = CP.Value
        DispFrame.BackgroundTransparency = CP.Transparency
        if TransBoxInner then
            TransBoxInner.BackgroundColor3 = CP.Value
            TransCursor.Position = UDim2.new(1 - CP.Transparency, 0, 0, 0)
        end
        CursorOuter.Position = UDim2.new(cS, 0, 1 - cV, 0)
        HueCursor.Position = UDim2.new(0, 0, cH, 0)
        HexBox.Text = '#' .. CP.Value:ToHex()
        RgbBox.Text = table.concat({math.floor(CP.Value.R*255), math.floor(CP.Value.G*255), math.floor(CP.Value.B*255)}, ', ')
        Library:SafeCallback(CP.Callback, CP.Value)
        Library:SafeCallback(CP.Changed, CP.Value)
    end

    function CP:OnChanged(Func)
        CP.Changed = Func
        Func(CP.Value)
    end

    function CP:Show()
        for Frame, Val in next, Library.OpenedFrames do
            if Frame.Name == 'Color' then
                Frame.Visible = false
                Library.OpenedFrames[Frame] = nil
            end
        end
        PickerOuter.Position = UDim2.fromOffset(DispFrame.AbsolutePosition.X, DispFrame.AbsolutePosition.Y + 18)
        PickerOuter.Visible = true
        Library.OpenedFrames[PickerOuter] = true
    end

    function CP:Hide()
        PickerOuter.Visible = false
        Library.OpenedFrames[PickerOuter] = nil
    end

    function CP:SetValue(HSV, Transparency)
        CP.Transparency = Transparency or 0
        cH, cS, cV = HSV[1], HSV[2], HSV[3]
        CP:Display()
    end

    function CP:SetValueRGB(Color, Transparency)
        CP.Transparency = Transparency or 0
        cH, cS, cV = Color3.toHSV(Color)
        CP:Display()
    end

    SatVibMap.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local MinX, MaxX = SatVibMap.AbsolutePosition.X, SatVibMap.AbsolutePosition.X + SatVibMap.AbsoluteSize.X
                local MinY, MaxY = SatVibMap.AbsolutePosition.Y, SatVibMap.AbsolutePosition.Y + SatVibMap.AbsoluteSize.Y
                cS = (math.clamp(Mouse.X, MinX, MaxX) - MinX) / (MaxX - MinX)
                cV = 1 - ((math.clamp(Mouse.Y, MinY, MaxY) - MinY) / (MaxY - MinY))
                CP:Display()
                RenderStepped:Wait()
            end
            Library:AttemptSave()
        end
    end)

    HueInner.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local MinY = HueInner.AbsolutePosition.Y
                local MaxY = MinY + HueInner.AbsoluteSize.Y
                cH = (math.clamp(Mouse.Y, MinY, MaxY) - MinY) / (MaxY - MinY)
                CP:Display()
                RenderStepped:Wait()
            end
            Library:AttemptSave()
        end
    end)

    if TransBoxInner then
        TransBoxInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinX = TransBoxInner.AbsolutePosition.X
                    local MaxX = MinX + TransBoxInner.AbsoluteSize.X
                    CP.Transparency = 1 - ((math.clamp(Mouse.X, MinX, MaxX) - MinX) / (MaxX - MinX))
                    CP:Display()
                    RenderStepped:Wait()
                end
                Library:AttemptSave()
            end
        end)
    end

    DispFrame.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
            if PickerOuter.Visible then CP:Hide() else ContextMenu:Hide() CP:Show() end
        elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
            ContextMenu:Show()
            CP:Hide()
        end
    end)

    DispFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
        if PickerOuter.Visible then
            PickerOuter.Position = UDim2.fromOffset(DispFrame.AbsolutePosition.X, DispFrame.AbsolutePosition.Y + 18)
        end
        updateMenuPos()
    end)

    HexBox.FocusLost:Connect(function(enter)
        if enter then
            local ok, res = pcall(Color3.fromHex, HexBox.Text)
            if ok and typeof(res) == 'Color3' then cH, cS, cV = Color3.toHSV(res) end
        end
        CP:Display()
    end)

    RgbBox.FocusLost:Connect(function(enter)
        if enter then
            local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
            if r and g and b then cH, cS, cV = Color3.toHSV(Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))) end
        end
        CP:Display()
    end)

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local p, s = PickerOuter.AbsolutePosition, PickerOuter.AbsoluteSize
            if Mouse.X < p.X or Mouse.X > p.X + s.X or Mouse.Y < (p.Y - 20 - 1) or Mouse.Y > p.Y + s.Y then
                CP:Hide()
            end
            if not Library:IsMouseOverFrame(ContextMenu.Container) then ContextMenu:Hide() end
        end
        if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
            if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DispFrame) then
                ContextMenu:Hide()
            end
        end
    end))

    CP:Display()
    CP.DisplayFrame = DispFrame
    return CP
end

-- ========== Key Picker (standalone) ==========
local function CreateKeyPicker(ParentRow, KInfo, Idx, ParentObj)
    KInfo = KInfo or {}
    KInfo.Default = KInfo.Default or 'None'
    local KP = {
        Value = KInfo.Default,
        Toggled = false,
        Mode = KInfo.Mode or 'Toggle',
        Type = 'KeyPicker',
        Callback = KInfo.Callback or function() end,
        ChangedCallback = KInfo.ChangedCallback or function() end,
        SyncToggleState = KInfo.SyncToggleState or false,
    }
    if KP.SyncToggleState then
        KInfo.Modes = { 'Toggle' }
        KInfo.Mode = 'Toggle'
    end
    Options[Idx] = KP

    local PickOuter = RoundFrame({
        Size = UDim2.new(0, 28, 0, 15),
        BackgroundColor3 = Color3.new(0, 0, 0),
        CornerRadius = 4,
        ZIndex = 6,
        Parent = ParentRow,
    })
    local PickInner = RoundFrame({
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.BackgroundColor,
        CornerRadius = 3,
        ZIndex = 7,
        Parent = PickOuter,
    })
    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = PickInner })
    Library:AddToRegistry(PickInner, { BackgroundColor3 = 'BackgroundColor' })

    local DisplayLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 1, 0),
        TextSize = 10,
        Text = KInfo.Default,
        TextWrapped = true,
        ZIndex = 8,
        Parent = PickInner,
    })

    -- Mode select
    local ModeSelectOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0),
        Size = UDim2.new(0, 60, 0, 47),
        Visible = false,
        ZIndex = 14,
        Parent = ScreenGui,
    })
    local ModeSelectInner = RoundFrame({
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Library.BackgroundColor,
        CornerRadius = 6,
        ZIndex = 15,
        Parent = ModeSelectOuter,
    })
    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, ZIndex = 16, Parent = ModeSelectInner })
    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ModeSelectInner,
    })
    Library:AddToRegistry(ModeSelectInner, { BackgroundColor3 = 'BackgroundColor' })

    local Modes = KInfo.Modes or { 'Always', 'Toggle', 'Hold' }
    local ModeButtons = {}

    for _, Mode in next, Modes do
        local ModeButton = {}
        local Label = Library:CreateLabel({
            Active = false,
            Size = UDim2.new(1, 0, 0, 15),
            TextSize = 12,
            Text = Mode,
            ZIndex = 16,
            Parent = ModeSelectInner,
        })
        function ModeButton:Select()
            for _, B in next, ModeButtons do B:Deselect() end
            KP.Mode = Mode
            Label.TextColor3 = Library.AccentColor
            Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor'
            ModeSelectOuter.Visible = false
        end
        function ModeButton:Deselect()
            Label.TextColor3 = Library.FontColor
            Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor'
        end
        Label.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                ModeButton:Select()
                Library:AttemptSave()
            end
        end)
        if Mode == KP.Mode then ModeButton:Select() end
        ModeButtons[Mode] = ModeButton
    end

    local function updateModePos()
        ModeSelectOuter.Position = UDim2.fromOffset(
            ParentRow.AbsolutePosition.X + ParentRow.AbsoluteSize.X + 4,
            ParentRow.AbsolutePosition.Y + 1
        )
    end
    ParentRow:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateModePos)
    task.spawn(updateModePos)

    function KP:Update()
        -- HUD keybind display stub
    end

    function KP:GetState()
        if KP.Mode == 'Always' then return true end
        if KP.Mode == 'Hold' then
            if KP.Value == 'None' then return false end
            if KP.Value == 'MB1' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
            if KP.Value == 'MB2' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
            return InputService:IsKeyDown(Enum.KeyCode[KP.Value])
        end
        return KP.Toggled
    end

    function KP:SetValue(Data)
        local Key, Mode = Data[1], Data[2]
        DisplayLabel.Text = Key
        KP.Value = Key
        if ModeButtons[Mode] then ModeButtons[Mode]:Select() end
        KP:Update()
    end

    function KP:OnClick(Callback) KP.Clicked = Callback end
    function KP:OnChanged(Callback) KP.Changed = Callback Callback(KP.Value) end

    function KP:DoClick()
        if ParentObj and ParentObj.Type == 'Toggle' and KP.SyncToggleState then
            ParentObj:SetValue(not ParentObj.Value)
        end
        Library:SafeCallback(KP.Callback, KP.Toggled)
        Library:SafeCallback(KP.Clicked, KP.Toggled)
    end

    local Picking = false
    PickOuter.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
            Picking = true
            DisplayLabel.Text = ''
            local Break
            local Dots = ''
            task.spawn(function()
                while not Break do
                    if Dots == '...' then Dots = '' end
                    Dots = Dots .. '.'
                    DisplayLabel.Text = Dots
                    wait(0.4)
                end
            end)
            wait(0.2)
            local Event
            Event = InputService.InputBegan:Connect(function(I2)
                local Key
                if I2.UserInputType == Enum.UserInputType.Keyboard then Key = I2.KeyCode.Name
                elseif I2.UserInputType == Enum.UserInputType.MouseButton1 then Key = 'MB1'
                elseif I2.UserInputType == Enum.UserInputType.MouseButton2 then Key = 'MB2' end
                if Key then
                    Break = true
                    Picking = false
                    DisplayLabel.Text = Key
                    KP.Value = Key
                    Library:SafeCallback(KP.ChangedCallback, I2.KeyCode or I2.UserInputType)
                    Library:SafeCallback(KP.Changed, I2.KeyCode or I2.UserInputType)
                    Library:AttemptSave()
                    Event:Disconnect()
                end
            end)
        elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
            ModeSelectOuter.Visible = true
        end
    end)

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
        if not Picking then
            if KP.Mode == 'Toggle' then
                local Key = KP.Value
                if Key == 'MB1' or Key == 'MB2' then
                    if (Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1)
                        or (Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2) then
                        KP.Toggled = not KP.Toggled
                        KP:DoClick()
                    end
                elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                    if Input.KeyCode.Name == Key then
                        KP.Toggled = not KP.Toggled
                        KP:DoClick()
                    end
                end
            end
            KP:Update()
        end
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local p, s = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize
            if Mouse.X < p.X or Mouse.X > p.X + s.X or Mouse.Y < (p.Y - 20 - 1) or Mouse.Y > p.Y + s.Y then
                ModeSelectOuter.Visible = false
            end
        end
    end))

    Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
        if not Picking then KP:Update() end
    end))

    KP:Update()
    return KP
end

-- ========== Window ==========
function Library:CreateWindow(Info)
    Info = Info or {}
    local Window = { Tabs = {} }

    local Main = RoundFrame({
        Size = UDim2.new(0, 880, 0, 560),
        Position = UDim2.new(0.5, -440, 0.5, -280),
        BackgroundColor3 = Library.BackgroundColor,
        CornerRadius = 10,
        Parent = ScreenGui,
    })
    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = Main })
    Library:MakeDraggable(Main, 580)

    -- Close
    local CloseBtn = RoundFrame({
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -34, 0, 8),
        BackgroundColor3 = Color3.fromRGB(40, 15, 15),
        CornerRadius = 6,
        ZIndex = 10,
        Parent = Main,
    })
    Library:Create('TextLabel', {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Library.Red,
        Text = "\195\151",
        ZIndex = 11,
        Parent = CloseBtn,
    })
    CloseBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then Library:Unload() end
    end)

    -- Minimize
    local MinBtn = RoundFrame({
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -62, 0, 8),
        BackgroundColor3 = Color3.fromRGB(25, 25, 40),
        CornerRadius = 6,
        ZIndex = 10,
        Parent = Main,
    })
    local MinLabel = Library:Create('TextLabel', {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Library.DimColor,
        Text = "\226\128\148",
        ZIndex = 11,
        Parent = MinBtn,
    })

    -- Sidebar
    local Sidebar = RoundFrame({
        Size = UDim2.new(0, 155, 1, 0),
        BackgroundColor3 = Library.SidebarColor,
        CornerRadius = 10,
        ClipsDescendants = true,
        Parent = Main,
    })
    Library:AddToRegistry(Sidebar, { BackgroundColor3 = 'SidebarColor' })
    -- Cover right rounded corners
    Library:Create('Frame', {
        Size = UDim2.new(0, 12, 1, 0),
        Position = UDim2.new(1, -12, 0, 0),
        BackgroundColor3 = Library.SidebarColor,
        BorderSizePixel = 0,
        Parent = Sidebar,
    })
    -- Accent top line
    Library:Create('Frame', {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Parent = Sidebar,
    })
    -- Title
    Library:Create('TextLabel', {
        Size = UDim2.new(0, 100, 0, 22),
        Position = UDim2.new(0, 14, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Library.AccentColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "fragrastic",
        Parent = Sidebar,
    })
    Library:Create('TextLabel', {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(0, 114, 0, 16),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Library.DimColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = ".tech",
        Parent = Sidebar,
    })
    -- Separator
    Library:Create('Frame', {
        Size = UDim2.new(0, 127, 0, 1),
        Position = UDim2.new(0, 14, 0, 42),
        BackgroundColor3 = Library.BorderColor,
        BorderSizePixel = 0,
        Parent = Sidebar,
    })

    -- Tab container
    local TabContainer = Library:Create('Frame', {
        Size = UDim2.new(1, -28, 1, -100),
        Position = UDim2.new(0, 14, 0, 56),
        BackgroundTransparency = 1,
        Parent = Sidebar,
    })
    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabContainer,
    })

    -- Bottom version
    Library:Create('TextLabel', {
        Size = UDim2.new(0, 60, 0, 14),
        Position = UDim2.new(0, 14, 1, -38),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = Library.MutedColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "v2.4.1",
        Parent = Sidebar,
    })
    Library:Create('TextLabel', {
        Size = UDim2.new(0, 70, 0, 14),
        Position = UDim2.new(0, 14, 1, -22),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = Library.MutedColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "build 2025",
        Parent = Sidebar,
    })

    -- Content scroll
    local ContentScroll = Library:Create('ScrollingFrame', {
        Size = UDim2.new(1, -167, 1, -12),
        Position = UDim2.new(0, 159, 0, 6),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Main,
    })
    Library:Create('UIListLayout', {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = ContentScroll,
    })
    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 8),
        Parent = ContentScroll,
    })

    local activeTabObj = nil
    local minimized = false

    MinBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            minimized = not minimized
            if minimized then
                TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 880, 0, 38)
                }):Play()
                Sidebar.Visible = false
                ContentScroll.Visible = false
                CloseBtn.Visible = false
                MinBtn.Position = UDim2.new(1, -34, 0, 6)
                MinLabel.Text = "+"
            else
                TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 880, 0, 560)
                }):Play()
                task.wait(0.3)
                Sidebar.Visible = true
                ContentScroll.Visible = true
                CloseBtn.Visible = true
                MinBtn.Position = UDim2.new(1, -62, 0, 8)
                MinLabel.Text = "\226\128\148"
            end
        end
    end)

    function Window:AddTab(Info)
        Info = Info or {}
        local Tab = { Groupboxes = {}, TabFrame = nil, _colIndex = 0 }

        local TabBtn = RoundFrame({
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = Library.SidebarColor,
            CornerRadius = 6,
            Parent = TabContainer,
        })
        local Indicator = Library:Create('Frame', {
            Size = UDim2.new(0, 3, 0, 18),
            Position = UDim2.new(0, 0, 0.5, -9),
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            Parent = TabBtn,
        })
        local TabLabel = Library:Create('TextLabel', {
            Size = UDim2.new(1, -14, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Library.DimColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = (Info.Title or "tab"):upper(),
            Parent = TabBtn,
        })

        local TabContent = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = ContentScroll,
        })
        Library:Create('UIListLayout', {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = TabContent,
        })

        local LeftCol = Library:Create('Frame', {
            Size = UDim2.new(0.5, -4, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = TabContent,
        })
        Library:Create('UIListLayout', {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = LeftCol,
        })
        local RightCol = Library:Create('Frame', {
            Size = UDim2.new(0.5, -4, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Parent = TabContent,
        })
        Library:Create('UIListLayout', {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = RightCol,
        })

        Tab.TabFrame = TabContent
        Tab.LeftCol = LeftCol
        Tab.RightCol = RightCol
        Tab.Button = TabBtn
        Tab.ButtonLabel = TabLabel
        Tab.Indicator = Indicator

        local function selectTab()
            if activeTabObj then activeTabObj.TabFrame.Visible = false end
            TabContent.Visible = true
            activeTabObj = Tab
            for _, t in pairs(Window.Tabs) do
                t.Button.BackgroundColor3 = Library.SidebarColor
                t.ButtonLabel.TextColor3 = Library.DimColor
                t.Indicator.BackgroundTransparency = 1
            end
            TabBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 45)
            TabLabel.TextColor3 = Library.AccentColor
            Indicator.BackgroundTransparency = 0
        end

        Tab.Select = selectTab
        TabBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then selectTab() end
        end)
        TabBtn.MouseEnter:Connect(function()
            if Tab ~= activeTabObj then
                TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(25, 25, 35)}):Play()
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if Tab ~= activeTabObj then
                TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundColor3 = Library.SidebarColor}):Play()
            end
        end)

        Window.Tabs[Info.Title] = Tab
        if #Window.Tabs == 1 then selectTab() end

        function Tab:AddGroupbox(Info)
            Info = Info or {}
            local Groupbox = { Container = nil, Addons = {} }

            local col = Tab._colIndex % 2 == 0 and LeftCol or RightCol
            Tab._colIndex = Tab._colIndex + 1

            local Card = RoundFrame({
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = Library.MainColor,
                CornerRadius = 8,
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = col,
            })
            Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = Card })
            Library:AddToRegistry(Card, { BackgroundColor3 = 'MainColor' })

            Card.MouseEnter:Connect(function()
                TweenService:Create(Card, TweenInfo.new(0.15), {BackgroundColor3 = Library.CardHover}):Play()
            end)
            Card.MouseLeave:Connect(function()
                TweenService:Create(Card, TweenInfo.new(0.15), {BackgroundColor3 = Library.MainColor}):Play()
            end)

            -- Accent bar + title
            Library:Create('Frame', {
                Size = UDim2.new(0, 3, 0, 14),
                Position = UDim2.new(0, 14, 0, 14),
                BackgroundColor3 = Library.AccentColor,
                BorderSizePixel = 0,
                Parent = Card,
            })
            Library:Create('TextLabel', {
                Size = UDim2.new(0, 200, 0, 20),
                Position = UDim2.new(0, 24, 0, 12),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = Library.FontColor,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = Info.Title or "",
                Parent = Card,
            })

            local Container = Library:Create('Frame', {
                Size = UDim2.new(1, -20, 0, 0),
                Position = UDim2.new(0, 10, 0, 38),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = Card,
            })
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Container,
            })

            Groupbox.Container = Container

            -- AddBlank
            function Groupbox:AddBlank(Size)
                Library:Create('Frame', {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, Size or 10),
                    ZIndex = 1,
                    Parent = Container,
                })
            end

            -- AddLabel
            function Groupbox:AddLabel(Text, DoesWrap)
                local Label = { Container = Container, Addons = {} }
                local TextLabel = Library:CreateLabel({
                    Size = UDim2.new(1, -4, 0, 16),
                    TextSize = 13,
                    Text = Text or "",
                    TextWrapped = DoesWrap or false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 5,
                    Parent = Container,
                })
                if DoesWrap then
                    local Y = select(2, Library:GetTextBounds(Text, Library.Font, 13, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                    TextLabel.Size = UDim2.new(1, -4, 0, Y)
                else
                    Library:Create('UIListLayout', {
                        Padding = UDim.new(0, 4),
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Right,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Parent = TextLabel,
                    })
                end
                Label.TextLabel = TextLabel

                function Label:SetText(t)
                    TextLabel.Text = t
                    if DoesWrap then
                        local Y = select(2, Library:GetTextBounds(t, Library.Font, 13, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                        TextLabel.Size = UDim2.new(1, -4, 0, Y)
                    end
                end

                function Label:AddColorPicker(Idx, CInfo)
                    CInfo = CInfo or {}
                    CInfo.Default = CInfo.Default or Color3.new(1, 1, 1)
                    local Disp = RoundFrame({
                        Size = UDim2.new(0, 28, 0, 14),
                        Position = UDim2.new(0, 0, 0, 1),
                        BackgroundColor3 = CInfo.Default,
                        CornerRadius = 3,
                        Parent = TextLabel,
                    })
                    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = Disp })
                    local cp = CreateColorPicker(Disp, CInfo, Idx)
                    table.insert(Label.Addons, cp)
                    return Label
                end

                function Label:AddKeyPicker(Idx, KInfo)
                    KInfo = KInfo or {}
                    KInfo.Default = KInfo.Default or 'None'
                    local kp = CreateKeyPicker(TextLabel, KInfo, Idx, nil)
                    table.insert(Label.Addons, kp)
                    return Label
                end

                function Label:AddTooltip(t)
                    Library:AddToolTip(t, TextLabel)
                    return Label
                end

                setmetatable(Label, {__index = function(self, key)
                    if key == 'AddColorPicker' then return Label.AddColorPicker
                    elseif key == 'AddKeyPicker' then return Label.AddKeyPicker
                    elseif key == 'AddTooltip' then return Label.AddTooltip end
                end})

                Groupbox:AddBlank(4)
                return Label
            end

            -- AddButton
            function Groupbox:AddButton(...)
                local Button = {}
                local Props = select(1, ...)
                if type(Props) == 'table' then
                    Button.Text = Props.Text or Props.Title or ""
                    Button.Func = Props.Func or Props.Callback or function() end
                    Button.DoubleClick = Props.DoubleClick
                    Button.Tooltip = Props.Tooltip
                else
                    Button.Text = select(1, ...) or ""
                    Button.Func = select(2, ...) or function() end
                end

                local Row = Library:Create('Frame', {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    Parent = Container,
                })
                local Btn = RoundFrame({
                    Size = UDim2.new(1, -8, 0, 26),
                    Position = UDim2.new(0, 4, 0, 2),
                    BackgroundColor3 = Library.SliderTrack,
                    CornerRadius = 6,
                    Parent = Row,
                })
                local BtnLabel = Library:Create('TextLabel', {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    TextColor3 = Library.DimColor,
                    Text = Button.Text,
                    Parent = Btn,
                })

                Library:AddToRegistry(Btn, { BackgroundColor3 = 'SliderTrack' })
                Library:OnHighlight(Btn, Btn,
                    { BackgroundColor3 = 'AccentDark' },
                    { BackgroundColor3 = 'SliderTrack' }
                )
                Library:OnHighlight(Btn, BtnLabel,
                    { TextColor3 = 'White' },
                    { TextColor3 = 'DimColor' }
                )

                if Button.Tooltip then
                    Library:AddToolTip(Button.Tooltip, Btn)
                end

                local LastClick = 0
                Btn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        if Button.DoubleClick then
                            local now = tick()
                            if now - LastClick < 0.4 then
                                Library:SafeCallback(Button.Func)
                            end
                            LastClick = now
                        else
                            Library:SafeCallback(Button.Func)
                        end
                    end
                end)

                function Button:AddTooltip(t)
                    Library:AddToolTip(t, Btn)
                    return Button
                end

                return Button
            end

            -- AddToggle
            function Groupbox:AddToggle(Info)
                Info = Info or {}
                assert(Info.Default ~= nil, 'AddToggle: Missing default value')
                local Toggle = {
                    Value = Info.Default,
                    Type = 'Toggle',
                    Callback = Info.Callback or function() end,
                    Addons = {},
                }
                Toggles[Info.Title] = Toggle

                local Row = Library:Create('Frame', {
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    Parent = Container,
                })
                local Label = Library:Create('TextLabel', {
                    Size = UDim2.new(0, 200, 0, 20),
                    Position = UDim2.new(0, 4, 0, 7),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextColor3 = Info.Default and Library.FontColor or Library.DimColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = Info.Title,
                    Parent = Row,
                })
                local ToggleBg = RoundFrame({
                    Size = UDim2.new(0, 40, 0, 20),
                    Position = UDim2.new(1, -44, 0, 7),
                    BackgroundColor3 = Info.Default and Library.AccentColor or Library.SliderTrack,
                    CornerRadius = 10,
                    Parent = Row,
                })
                local Knob = RoundFrame({
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = Info.Default and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 4, 0.5, -7),
                    BackgroundColor3 = Library.White,
                    CornerRadius = 7,
                    Parent = ToggleBg,
                })

                if Info.Tooltip then Library:AddToolTip(Info.Tooltip, Row) end

                function Toggle:SetValue(val)
                    Toggle.Value = val
                    TweenService:Create(ToggleBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = val and Library.AccentColor or Library.SliderTrack
                    }):Play()
                    TweenService:Create(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        Position = val and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 4, 0.5, -7)
                    }):Play()
                    TweenService:Create(Label, TweenInfo.new(0.15), {
                        TextColor3 = val and Library.FontColor or Library.DimColor
                    }):Play()
                    Library:SafeCallback(Toggle.Callback, val)
                    Library:AttemptSave()
                end

                ToggleBg.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        Toggle:SetValue(not Toggle.Value)
                    end
                end)

                function Toggle:AddColorPicker(Idx, CInfo)
                    CInfo = CInfo or {}
                    CInfo.Default = CInfo.Default or Color3.new(1, 1, 1)
                    local Disp = RoundFrame({
                        Size = UDim2.new(0, 28, 0, 14),
                        Position = UDim2.new(0, 0, 0, 3),
                        BackgroundColor3 = CInfo.Default,
                        CornerRadius = 3,
                        Parent = Label,
                    })
                    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = Disp })
                    local cp = CreateColorPicker(Disp, CInfo, Idx)
                    table.insert(Toggle.Addons, cp)
                    return Toggle
                end

                function Toggle:AddKeyPicker(Idx, KInfo)
                    local kp = CreateKeyPicker(Label, KInfo, Idx, Toggle)
                    table.insert(Toggle.Addons, kp)
                    return Toggle
                end

                setmetatable(Toggle, {__index = function(self, key)
                    if key == 'AddColorPicker' then return Toggle.AddColorPicker
                    elseif key == 'AddKeyPicker' then return Toggle.AddKeyPicker end
                end})

                return Toggle
            end

            -- AddSlider
            function Groupbox:AddSlider(Info)
                Info = Info or {}
                assert(Info.Default ~= nil, 'AddSlider: Missing default value')
                Info.Min = Info.Min or 0
                Info.Max = Info.Max or 100
                Info.Rounding = Info.Rounding or 0
                local Slider = {
                    Value = Info.Default, Min = Info.Min, Max = Info.Max,
                    Type = 'Slider', Callback = Info.Callback or function() end,
                    Addons = {},
                }
                Options[Info.Title] = Slider

                local Row = Library:Create('Frame', {
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    Parent = Container,
                })
                Library:Create('TextLabel', {
                    Size = UDim2.new(0, 120, 0, 20),
                    Position = UDim2.new(0, 4, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextColor3 = Library.DimColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = Info.Title,
                    Parent = Row,
                })
                local function fmtVal(v)
                    if Info.Rounding and Info.Rounding > 0 then return string.format("%." .. Info.Rounding .. "f", v) end
                    return tostring(math.floor(v))
                end
                local ValLabel = Library:Create('TextLabel', {
                    Size = UDim2.new(0, 40, 0, 20),
                    Position = UDim2.new(0, 130, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    TextColor3 = Library.AccentColor,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Text = fmtVal(Info.Default),
                    Parent = Row,
                })
                local TrackOuter = Library:Create('Frame', {
                    Size = UDim2.new(1, -180, 0, 10),
                    Position = UDim2.new(0, 180, 0, 4),
                    BackgroundTransparency = 1,
                    Parent = Row,
                })
                local Track = RoundFrame({
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.new(0, 0, 0, 2),
                    BackgroundColor3 = Library.SliderTrack,
                    CornerRadius = 3,
                    Parent = TrackOuter,
                })
                local Fill = RoundFrame({
                    Size = UDim2.new(0, 0, 0, 6),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundColor3 = Library.AccentColor,
                    CornerRadius = 3,
                    Parent = Track,
                })
                local Knob = RoundFrame({
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 0, 0, -4),
                    BackgroundColor3 = Library.AccentColor,
                    CornerRadius = 7,
                    ZIndex = 5,
                    Parent = Track,
                })

                if Info.Tooltip then Library:AddToolTip(Info.Tooltip, Row) end

                local function updateVisual(val)
                    val = math.clamp(val, Info.Min, Info.Max)
                    local step = (Info.Rounding and Info.Rounding > 0) and (10 ^ -Info.Rounding) or 1
                    val = math.round(val / step) * step
                    Slider.Value = val
                    local pct = (val - Info.Min) / (Info.Max - Info.Min)
                    local tw = Track.AbsoluteSize.X
                    local px = pct * tw
                    Fill.Size = UDim2.new(0, math.max(6, px), 0, 6)
                    Knob.Position = UDim2.new(0, px - 7, 0, -4)
                    ValLabel.Text = fmtVal(val)
                end
                updateVisual(Info.Default)

                local sliding = false
                Knob.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.Touch then sliding = true end
                end)
                Track.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.Touch then
                        local rel = inp.Position.X - Track.AbsolutePosition.X
                        updateVisual(Info.Min + (rel / Track.AbsoluteSize.X) * (Info.Max - Info.Min))
                        Library:SafeCallback(Slider.Callback, Slider.Value)
                        sliding = true
                    end
                end)
                TrackOuter.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.Touch then
                        local rel = inp.Position.X - Track.AbsolutePosition.X
                        updateVisual(Info.Min + (rel / Track.AbsoluteSize.X) * (Info.Max - Info.Min))
                        Library:SafeCallback(Slider.Callback, Slider.Value)
                        sliding = true
                    end
                end)
                Library:GiveSignal(InputService.InputEnded:Connect(function(inp)
                    if (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.Touch) and sliding then
                        sliding = false
                        Library:AttemptSave()
                    end
                end))
                Library:GiveSignal(InputService.InputChanged:Connect(function(inp)
                    if sliding and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.Touch) then
                        local rel = inp.Position.X - Track.AbsolutePosition.X
                        updateVisual(Info.Min + (rel / Track.AbsoluteSize.X) * (Info.Max - Info.Min))
                        Library:SafeCallback(Slider.Callback, Slider.Value)
                    end
                end))

                function Slider:SetValue(val)
                    updateVisual(val)
                    Library:SafeCallback(Slider.Callback, Slider.Value)
                end
                function Slider:OnChanged(cb) Slider.Callback = cb cb(Slider.Value) end

                function Slider:AddKeyPicker(Idx, KInfo)
                    local kp = CreateKeyPicker(Row, KInfo, Idx, nil)
                    table.insert(Slider.Addons, kp)
                    return Slider
                end

                setmetatable(Slider, {__index = function(self, key)
                    if key == 'AddKeyPicker' then return Slider.AddKeyPicker end
                end})

                return Slider
            end

            -- AddDropdown
            function Groupbox:AddDropdown(Info)
                Info = Info or {}
                Info.Values = Info.Values or {}
                Info.Default = Info.Default or (Info.Values[1] or "")
                local Dropdown = {
                    Value = Info.Default,
                    Values = Info.Values,
                    Type = 'Dropdown',
                    Callback = Info.Callback or function() end,
                    MultiValues = {},
                }
                Options[Info.Title] = Dropdown

                local Row = Library:Create('Frame', {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    Parent = Container,
                })
                local Outer = RoundFrame({
                    Size = UDim2.new(1, -8, 0, 24),
                    Position = UDim2.new(0, 4, 0, 2),
                    BackgroundColor3 = Library.SliderTrack,
                    CornerRadius = 6,
                    Parent = Row,
                })
                Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = Outer })
                local Lbl = Library:Create('TextLabel', {
                    Size = UDim2.new(1, -24, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextColor3 = Library.FontColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = tostring(Info.Default),
                    Parent = Outer,
                })
                local Arrow = Library:Create('TextLabel', {
                    Size = UDim2.new(0, 20, 1, 0),
                    Position = UDim2.new(1, -20, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 10,
                    TextColor3 = Library.DimColor,
                    Text = "v",
                    Parent = Outer,
                })

                if Info.Tooltip then Library:AddToolTip(Info.Tooltip, Row) end

                local MenuOuter = Library:Create('Frame', {
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    Size = UDim2.new(1, -8, 0, 0),
                    Position = UDim2.new(0, 4, 0, 28),
                    Visible = false,
                    ZIndex = 20,
                    Parent = Row,
                })
                local MenuInner = RoundFrame({
                    BackgroundColor3 = Library.MainColor,
                    CornerRadius = 6,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 21,
                    Parent = MenuOuter,
                })
                Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, ZIndex = 22, Parent = MenuInner })
                local MenuLayout = Library:Create('UIListLayout', {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 2),
                    ZIndex = 23,
                    Parent = MenuInner,
                })
                Library:Create('UIPadding', {
                    PaddingTop = UDim.new(0, 4),
                    PaddingBottom = UDim.new(0, 4),
                    ZIndex = 23,
                    Parent = MenuInner,
                })

                local SearchBox
                if Info.AllowNull then
                    SearchBox = Library:Create('Frame', {
                        Size = UDim2.new(1, -8, 0, 20),
                        BackgroundColor3 = Library.BackgroundColor,
                        ZIndex = 24,
                        Parent = MenuInner,
                    })
                    Library:Create('UICorner', { CornerRadius = UDim.new(0, 4), Parent = SearchBox })
                    local SB = Library:Create('TextBox', {
                        Size = UDim2.new(1, -8, 1, 0),
                        Position = UDim2.new(0, 4, 0, 0),
                        BackgroundTransparency = 1,
                        Font = Library.Font,
                        TextSize = 12,
                        TextColor3 = Library.FontColor,
                        PlaceholderColor3 = Library.MutedColor,
                        PlaceholderText = "Search...",
                        Text = "",
                        ZIndex = 25,
                        Parent = SearchBox,
                    })
                    SB:GetPropertyChangedSignal('Text'):Connect(function()
                        local query = SB.Text:lower()
                        for _, child in next, MenuInner:GetChildren() do
                            if child:IsA('TextButton') then
                                child.Visible = child.Text:lower():find(query, 1, true) and true or false
                            end
                        end
                    end)
                end

                local optFrames = {}
                local function refreshOpts()
                    for _, f in ipairs(optFrames) do f:Destroy() end
                    optFrames = {}
                    for i, val in ipairs(Dropdown.Values) do
                        local Opt = Library:Create('TextButton', {
                            Size = UDim2.new(1, -8, 0, 22),
                            BackgroundTransparency = 1,
                            Font = Library.Font,
                            TextSize = 12,
                            TextColor3 = val == Dropdown.Value and Library.AccentColor or Library.FontColor,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Text = "  " .. tostring(val),
                            ZIndex = 24,
                            Parent = MenuInner,
                        })
                        Opt.MouseEnter:Connect(function()
                            if val ~= Dropdown.Value then
                                TweenService:Create(Opt, TweenInfo.new(0.1), {TextTransparency = 0.3}):Play()
                            end
                        end)
                        Opt.MouseLeave:Connect(function()
                            TweenService:Create(Opt, TweenInfo.new(0.1), {TextTransparency = 0}):Play()
                        end)
                        Opt.InputBegan:Connect(function(inp)
                            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                                Dropdown.Value = val
                                Lbl.Text = tostring(val)
                                MenuOuter.Visible = false
                                Arrow.Text = "v"
                                Library:SafeCallback(Dropdown.Callback, val)
                                Library:AttemptSave()
                                refreshOpts()
                            end
                        end)
                        table.insert(optFrames, Opt)
                    end
                end
                refreshOpts()

                Outer.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        local show = not MenuOuter.Visible
                        MenuOuter.Visible = show
                        Arrow.Text = show and "^" or "v"
                    end
                end)
                Library:GiveSignal(InputService.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 and MenuOuter.Visible then
                        local p, s = MenuOuter.AbsolutePosition, MenuOuter.AbsoluteSize
                        if Mouse.X < p.X or Mouse.X > p.X + s.X or Mouse.Y < p.Y or Mouse.Y > p.Y + s.Y then
                            MenuOuter.Visible = false
                            Arrow.Text = "v"
                        end
                    end
                end))

                function Dropdown:SetValue(val)
                    Dropdown.Value = val
                    Lbl.Text = tostring(val)
                    refreshOpts()
                    Library:SafeCallback(Dropdown.Callback, val)
                end
                function Dropdown:Refresh(vals, keep)
                    Dropdown.Values = vals
                    if not keep then Dropdown.Value = vals[1] Lbl.Text = tostring(vals[1]) end
                    refreshOpts()
                end
                function Dropdown:OnChanged(cb) Dropdown.Callback = cb cb(Dropdown.Value) end
                function Dropdown:AddTooltip(t) Library:AddToolTip(t, Row) return Dropdown end

                return Dropdown
            end

            -- AddKeyPicker (standalone)
            function Groupbox:AddKeyPicker(Info)
                Info = Info or {}
                Info.Default = Info.Default or 'None'
                local Row = Library:Create('Frame', {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    Parent = Container,
                })
                Library:Create('TextLabel', {
                    Size = UDim2.new(0, 200, 0, 20),
                    Position = UDim2.new(0, 4, 0, 4),
                    BackgroundTransparency = 1,
                    Font = Library.Font,
                    TextSize = 13,
                    TextColor3 = Library.DimColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = Info.Title,
                    Parent = Row,
                })
                if Info.Tooltip then Library:AddToolTip(Info.Tooltip, Row) end
                return CreateKeyPicker(Row, Info, Info.Title, nil)
            end

            -- AddColorPicker (standalone)
            function Groupbox:AddColorPicker(Info)
                Info = Info or {}
                Info.Default = Info.Default or Color3.new(1, 1, 1)
                local Row = Library:Create('Frame', {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    Parent = Container,
                })
                Library:Create('TextLabel', {
                    Size = UDim2.new(0, 200, 0, 20),
                    Position = UDim2.new(0, 4, 0, 4),
                    BackgroundTransparency = 1,
                    Font = Library.Font,
                    TextSize = 13,
                    TextColor3 = Library.DimColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = Info.Title,
                    Parent = Row,
                })
                local Disp = RoundFrame({
                    Size = UDim2.new(0, 28, 0, 18),
                    Position = UDim2.new(1, -36, 0, 5),
                    BackgroundColor3 = Info.Default,
                    CornerRadius = 4,
                    Parent = Row,
                })
                Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = Disp })
                if Info.Tooltip then Library:AddToolTip(Info.Tooltip, Row) end
                return CreateColorPicker(Disp, Info, Info.Title)
            end

            -- AddInput
            function Groupbox:AddInput(Info)
                Info = Info or {}
                local InputObj = {
                    Value = Info.Default or "",
                    Type = 'Input',
                    Callback = Info.Callback or function() end,
                }
                Options[Info.Title] = InputObj
                local Row = Library:Create('Frame', {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    Parent = Container,
                })
                Library:Create('TextLabel', {
                    Size = UDim2.new(0, 120, 0, 20),
                    Position = UDim2.new(0, 4, 0, 4),
                    BackgroundTransparency = 1,
                    Font = Library.Font,
                    TextSize = 13,
                    TextColor3 = Library.DimColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = Info.Title,
                    Parent = Row,
                })
                local Box = RoundFrame({
                    Size = UDim2.new(1, -136, 0, 20),
                    Position = UDim2.new(0, 130, 0, 4),
                    BackgroundColor3 = Library.BackgroundColor,
                    CornerRadius = 4,
                    Parent = Row,
                })
                Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = Box })
                local TB = Library:Create('TextBox', {
                    Size = UDim2.new(1, -8, 1, 0),
                    Position = UDim2.new(0, 4, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Library.Font,
                    TextSize = 12,
                    TextColor3 = Library.FontColor,
                    PlaceholderColor3 = Library.MutedColor,
                    PlaceholderText = Info.Placeholder or "",
                    Text = Info.Default or "",
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                    Parent = Box,
                })
                if Info.Tooltip then Library:AddToolTip(Info.Tooltip, Row) end
                TB.FocusLost:Connect(function()
                    InputObj.Value = TB.Text
                    Library:SafeCallback(InputObj.Callback, InputObj.Value)
                    Library:AttemptSave()
                end)
                function InputObj:SetValue(val) TB.Text = val InputObj.Value = val end
                function InputObj:OnChanged(cb) InputObj.Callback = cb end
                return InputObj
            end

            -- AddSeparator
            function Groupbox:AddSeparator()
                Library:Create('Frame', {
                    Size = UDim2.new(1, -8, 0, 1),
                    Position = UDim2.new(0, 4, 0, 4),
                    BackgroundColor3 = Library.BorderColor,
                    BorderSizePixel = 0,
                    Parent = Container,
                })
            end

            return Groupbox
        end

        return Tab
    end

    return Window
end

return Library
