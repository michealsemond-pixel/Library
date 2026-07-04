local InputService = game:GetService('UserInputService')
local TextService = game:GetService('TextService')
local CoreGui = game:GetService('CoreGui')
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
    FontColor = Color3.fromRGB(220, 220, 230),
    DimColor = Color3.fromRGB(100, 100, 120),
    MutedColor = Color3.fromRGB(60, 60, 75),
    MainColor = Color3.fromRGB(22, 22, 30),
    BackgroundColor = Color3.fromRGB(12, 12, 16),
    SidebarColor = Color3.fromRGB(16, 16, 22),
    AccentColor = Color3.fromRGB(120, 180, 255),
    AccentDark = Color3.fromRGB(80, 130, 200),
    BorderColor = Color3.fromRGB(35, 35, 48),
    SliderTrack = Color3.fromRGB(40, 40, 55),
    CardHover = Color3.fromRGB(30, 30, 40),
    Green = Color3.fromRGB(80, 220, 120),
    Red = Color3.fromRGB(220, 80, 80),
    Black = Color3.new(0, 0, 0),
    White = Color3.fromRGB(240, 240, 245),
    Font = Enum.Font.Gotham,
    ScreenGui = ScreenGui,
    Signals = {},
    OpenedFrames = {},
    NotifyOnError = false,
}

function Library:Create(Class, Properties)
    local Inst = type(Class) == 'string' and Instance.new(Class) or Class
    for Prop, Val in next, Properties do Inst[Prop] = Val end
    return Inst
end

function Library:AddToRegistry(Instance, Properties)
    local Data = { Instance = Instance, Properties = Properties }
    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data
end

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance]
    if Data then
        for i = #Library.Registry, 1, -1 do
            if Library.Registry[i] == Data then table.remove(Library.Registry, i) end
        end
        Library.RegistryMap[Instance] = nil
    end
end

function Library:UpdateColors()
    for _, Obj in next, Library.Registry do
        for Prop, ColorIdx in next, Obj.Properties do
            if type(ColorIdx) == 'string' then
                Obj.Instance[Prop] = Library[ColorIdx]
            end
        end
    end
end

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local Off = Vector2.new(Mouse.X - Instance.AbsolutePosition.X, Mouse.Y - Instance.AbsolutePosition.Y)
            if Off.Y > (Cutoff or 40) then return end
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                Instance.Position = UDim2.new(0, Mouse.X - Off.X, 0, Mouse.Y - Off.Y)
                RenderStepped:Wait()
            end
        end
    end)
end

function Library:SafeCallback(f, ...)
    if not f then return end
    if not Library.NotifyOnError then return f(...) end
    local ok, err = pcall(f, ...)
    if not ok then Library:Notify(tostring(err)) end
end

function Library:AttemptSave()
    if Library.SaveManager then Library.SaveManager:Save() end
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
            Size = UDim2.new(0, 220, 1, 0),
            Position = UDim2.new(1, -230, 0, 0),
            BackgroundTransparency = 1,
            Parent = ScreenGui,
        })
        local nl = Library:Create('UIListLayout', {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Parent = NotifContainer,
        })
        Library:Create('UIPadding', { PaddingBottom = UDim.new(0, 12), Parent = NotifContainer })
    end
    local f = Library:Create('Frame', {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        Parent = NotifContainer,
    })
    Library:Create('UICorner', { CornerRadius = UDim.new(0, 6), Parent = f })
    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = f })
    Library:Create('TextLabel', {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
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
        local tw = TweenService:Create(f, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
        tw:Play()
        tw.Completed:Connect(function() f:Destroy() end)
    end)
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Inst)
    if Library.RegistryMap[Inst] then Library:RemoveFromRegistry(Inst) end
end))

local function RoundFrame(props)
    local f = Library:Create('Frame', props)
    Library:Create('UICorner', { CornerRadius = UDim.new(0, props.CornerRadius or 8), Parent = f })
    return f
end

function Library:CreateWindow(Info)
    Info = Info or {}
    local Window = { Tabs = {} }

    local Main = RoundFrame({
        Size = UDim2.new(0, 880, 0, 560),
        Position = UDim2.new(0.5, -440, 0.5, -280),
        BackgroundColor3 = Library.BackgroundColor,
        BorderSizePixel = 0,
        CornerRadius = 10,
        Parent = ScreenGui,
    })
    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = Main })
    Library:MakeDraggable(Main, 580)

    local CloseBtn = RoundFrame({
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -34, 0, 8),
        BackgroundColor3 = Color3.fromRGB(40, 15, 15),
        BorderSizePixel = 0,
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

    local MinBtn = RoundFrame({
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -62, 0, 8),
        BackgroundColor3 = Color3.fromRGB(25, 25, 40),
        BorderSizePixel = 0,
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

    local Sidebar = RoundFrame({
        Size = UDim2.new(0, 155, 1, 0),
        BackgroundColor3 = Library.SidebarColor,
        BorderSizePixel = 0,
        CornerRadius = 10,
        ClipsDescendants = true,
        Parent = Main,
    })
    Library:AddToRegistry(Sidebar, { BackgroundColor3 = 'SidebarColor' })
    Library:Create('Frame', {
        Size = UDim2.new(0, 12, 1, 0),
        Position = UDim2.new(1, -12, 0, 0),
        BackgroundColor3 = Library.SidebarColor,
        BorderSizePixel = 0,
        Parent = Sidebar,
    })
    Library:Create('Frame', {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Parent = Sidebar,
    })
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
    Library:Create('Frame', {
        Size = UDim2.new(0, 127, 0, 1),
        Position = UDim2.new(0, 14, 0, 42),
        BackgroundColor3 = Library.BorderColor,
        BorderSizePixel = 0,
        Parent = Sidebar,
    })

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
        local Tab = { Groupboxes = {}, TabFrame = nil }

        local TabBtn = RoundFrame({
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = Library.SidebarColor,
            BorderSizePixel = 0,
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
        Tab._colIndex = 0

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
            local Groupbox = {}

            local col = Tab._colIndex % 2 == 0 and LeftCol or RightCol
            Tab._colIndex = Tab._colIndex + 1

            local Card = RoundFrame({
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = Library.MainColor,
                BorderSizePixel = 0,
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

            function Groupbox:AddToggle(Info)
                Info = Info or {}
                assert(Info.Default ~= nil, 'AddToggle: Missing default value')
                local Toggle = {
                    Value = Info.Default,
                    Type = 'Toggle',
                    Callback = Info.Callback or function() end,
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
                    BorderSizePixel = 0,
                    CornerRadius = 10,
                    Parent = Row,
                })
                local Knob = RoundFrame({
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = Info.Default and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 4, 0.5, -7),
                    BackgroundColor3 = Library.White,
                    BorderSizePixel = 0,
                    CornerRadius = 7,
                    Parent = ToggleBg,
                })

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
                    local CP = { Value = CInfo.Default, Type = 'ColorPicker', Callback = CInfo.Callback or function() end }
                    Options[Idx] = CP
                    local Disp = RoundFrame({
                        Size = UDim2.new(0, 28, 0, 14),
                        Position = UDim2.new(0, 0, 0, 3),
                        BackgroundColor3 = CInfo.Default,
                        BorderSizePixel = 0,
                        CornerRadius = 3,
                        Parent = Label,
                    })
                    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = Disp })
                    local PO = Library:Create('Frame', {
                        BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.new(0, 200, 0, 180),
                        Visible = false, ZIndex = 30, Parent = ScreenGui,
                    })
                    local PI = RoundFrame({
                        Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
                        BackgroundColor3 = Library.MainColor, BorderSizePixel = 0, CornerRadius = 8, ZIndex = 31, Parent = PO,
                    })
                    local SVMap = Library:Create('ImageLabel', {
                        Size = UDim2.new(1, -16, 0, 140), Position = UDim2.new(0, 4, 0, 4),
                        BackgroundColor3 = Color3.new(1, 0, 0), BorderSizePixel = 0,
                        Image = 'rbxassetid://4155801252', ZIndex = 32, Parent = PI,
                    })
                    local HueBar = Library:Create('Frame', {
                        Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 4, 0, 150),
                        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 32, Parent = PI,
                    })
                    Library:Create('UIGradient', {
                        Rotation = 90,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                            ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
                            ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
                            ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
                            ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
                            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
                        }), Parent = HueBar,
                    })
                    local cH, cS, cV = Color3.toHSV(CInfo.Default)
                    local SVC = Library:Create('Frame', {
                        Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(cS, 0, 1 - cV, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0, ZIndex = 34, Parent = SVMap,
                    })
                    Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = SVC })
                    local HC = Library:Create('Frame', {
                        Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, cH, 0),
                        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 34, Parent = HueBar,
                    })
                    local function cDisp()
                        CP.Value = Color3.fromHSV(cH, cS, cV)
                        SVMap.BackgroundColor3 = Color3.fromHSV(cH, 1, 1)
                        Disp.BackgroundColor3 = CP.Value
                        SVC.Position = UDim2.new(cS, 0, 1 - cV, 0)
                        HC.Position = UDim2.new(0, 0, cH, 0)
                        Library:SafeCallback(CP.Callback, CP.Value)
                    end
                    SVMap.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                                cS = math.clamp((Mouse.X - SVMap.AbsolutePosition.X) / SVMap.AbsoluteSize.X, 0, 1)
                                cV = 1 - math.clamp((Mouse.Y - SVMap.AbsolutePosition.Y) / SVMap.AbsoluteSize.Y, 0, 1)
                                cDisp()
                                RenderStepped:Wait()
                            end
                            Library:AttemptSave()
                        end
                    end)
                    HueBar.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                                cH = math.clamp((Mouse.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                                cDisp()
                                RenderStepped:Wait()
                            end
                            Library:AttemptSave()
                        end
                    end)
                    Disp.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            PO.Position = UDim2.fromOffset(Disp.AbsolutePosition.X, Disp.AbsolutePosition.Y + 18)
                            PO.Visible = not PO.Visible
                        end
                    end)
                    Library:GiveSignal(InputService.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 and PO.Visible then
                            local p, s = PO.AbsolutePosition, PO.AbsoluteSize
                            if Mouse.X < p.X or Mouse.X > p.X + s.X or Mouse.Y < p.Y or Mouse.Y > p.Y + s.Y then
                                PO.Visible = false
                            end
                        end
                    end))
                    cDisp()
                    function CP:SetValueRGB(c) cH, cS, cV = Color3.toHSV(c) cDisp() end
                    function CP:OnChanged(cb) CP.Callback = cb cb(CP.Value) end
                    return Toggle
                end

                function Toggle:AddKeyPicker(Idx, KInfo)
                    KInfo = KInfo or {}
                    KInfo.Default = KInfo.Default or 'None'
                    local KP = {
                        Value = KInfo.Default, Mode = KInfo.Mode or 'Toggle', Toggled = false,
                        Type = 'KeyPicker', Callback = KInfo.Callback or function() end,
                    }
                    Options[Idx] = KP
                    local KB = RoundFrame({
                        Size = UDim2.new(0, 28, 0, 15),
                        Position = UDim2.new(0, 32, 0, 2),
                        BackgroundColor3 = Library.BackgroundColor,
                        BorderSizePixel = 0, CornerRadius = 4, Parent = Label,
                    })
                    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = KB })
                    local KL = Library:Create('TextLabel', {
                        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold, TextSize = 10,
                        TextColor3 = Library.FontColor, Text = KInfo.Default, Parent = KB,
                    })
                    KB.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            KL.Text = "..."
                            local ev
                            ev = InputService.InputBegan:Connect(function(i2)
                                local k
                                if i2.UserInputType == Enum.UserInputType.Keyboard then k = i2.KeyCode.Name
                                elseif i2.UserInputType == Enum.UserInputType.MouseButton1 then k = 'MB1'
                                elseif i2.UserInputType == Enum.UserInputType.MouseButton2 then k = 'MB2' end
                                if k then KL.Text = k KP.Value = k Library:SafeCallback(KP.Callback, k) Library:AttemptSave() ev:Disconnect() end
                            end)
                        end
                    end)
                    function KP:GetState()
                        if KP.Mode == 'Always' then return true end
                        if KP.Mode == 'Hold' then
                            if KP.Value == 'MB1' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
                            if KP.Value == 'MB2' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
                            return InputService:IsKeyDown(Enum.KeyCode[KP.Value])
                        end
                        return KP.Toggled
                    end
                    function KP:SetValue(d) KL.Text = d[1] KP.Value = d[1] KP.Mode = d[2] or KP.Mode end
                    function KP:OnChanged(cb) KP.Callback = cb end
                    return Toggle
                end

                return Toggle
            end

            function Groupbox:AddSlider(Info)
                Info = Info or {}
                assert(Info.Default ~= nil, 'AddSlider: Missing default value')
                Info.Min = Info.Min or 0
                Info.Max = Info.Max or 100
                Info.Rounding = Info.Rounding or 0
                local Slider = {
                    Value = Info.Default, Min = Info.Min, Max = Info.Max,
                    Type = 'Slider', Callback = Info.Callback or function() end,
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
                    Size = UDim2.new(1, -180, 0, 8),
                    Position = UDim2.new(0, 180, 0, 6),
                    BackgroundTransparency = 1,
                    Parent = Row,
                })
                local Track = RoundFrame({
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.new(0, 0, 0, 1),
                    BackgroundColor3 = Library.SliderTrack,
                    BorderSizePixel = 0,
                    CornerRadius = 3,
                    Parent = TrackOuter,
                })
                local Fill = RoundFrame({
                    Size = UDim2.new(0, 0, 0, 6),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundColor3 = Library.AccentColor,
                    BorderSizePixel = 0,
                    CornerRadius = 3,
                    Parent = Track,
                })
                local Knob = RoundFrame({
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 0, 0, -4),
                    BackgroundColor3 = Library.AccentColor,
                    BorderSizePixel = 0,
                    CornerRadius = 7,
                    ZIndex = 5,
                    Parent = Track,
                })

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
                local function startSlide() sliding = true end
                Knob.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.Touch then startSlide() end
                end)
                Track.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.Touch then
                        local rel = inp.Position.X - Track.AbsolutePosition.X
                        updateVisual(Info.Min + (rel / Track.AbsoluteSize.X) * (Info.Max - Info.Min))
                        Library:SafeCallback(Slider.Callback, Slider.Value)
                        startSlide()
                    end
                end)
                TrackOuter.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.Touch then
                        local rel = inp.Position.X - Track.AbsolutePosition.X
                        updateVisual(Info.Min + (rel / Track.AbsoluteSize.X) * (Info.Max - Info.Min))
                        Library:SafeCallback(Slider.Callback, Slider.Value)
                        startSlide()
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
                    KInfo = KInfo or {}
                    KInfo.Default = KInfo.Default or 'None'
                    local KP = { Value = KInfo.Default, Mode = KInfo.Mode or 'Toggle', Toggled = false, Type = 'KeyPicker', Callback = KInfo.Callback or function() end }
                    Options[Idx] = KP
                    local KB = RoundFrame({
                        Size = UDim2.new(0, 28, 0, 15), Position = UDim2.new(1, -36, 0, 0),
                        BackgroundColor3 = Library.BackgroundColor, BorderSizePixel = 0, CornerRadius = 4, Parent = Row,
                    })
                    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = KB })
                    local KL = Library:Create('TextLabel', {
                        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold, TextSize = 10,
                        TextColor3 = Library.FontColor, Text = KInfo.Default, Parent = KB,
                    })
                    KB.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            KL.Text = "..."
                            local ev
                            ev = InputService.InputBegan:Connect(function(i2)
                                local k
                                if i2.UserInputType == Enum.UserInputType.Keyboard then k = i2.KeyCode.Name
                                elseif i2.UserInputType == Enum.UserInputType.MouseButton1 then k = 'MB1'
                                elseif i2.UserInputType == Enum.UserInputType.MouseButton2 then k = 'MB2' end
                                if k then KL.Text = k KP.Value = k Library:SafeCallback(KP.Callback, k) Library:AttemptSave() ev:Disconnect() end
                            end)
                        end
                    end)
                    function KP:GetState()
                        if KP.Mode == 'Always' then return true end
                        if KP.Mode == 'Hold' then
                            if KP.Value == 'MB1' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
                            if KP.Value == 'MB2' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
                            return InputService:IsKeyDown(Enum.KeyCode[KP.Value])
                        end
                        return KP.Toggled
                    end
                    function KP:SetValue(d) KL.Text = d[1] KP.Value = d[1] KP.Mode = d[2] or KP.Mode end
                    function KP:OnChanged(cb) KP.Callback = cb end
                    return Slider
                end
                return Slider
            end

            function Groupbox:AddButton(Info)
                Info = Info or {}
                local Row = Library:Create('Frame', {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    Parent = Container,
                })
                local Btn = RoundFrame({
                    Size = UDim2.new(1, -8, 0, 26),
                    Position = UDim2.new(0, 4, 0, 2),
                    BackgroundColor3 = Library.SliderTrack,
                    BorderSizePixel = 0,
                    CornerRadius = 6,
                    Parent = Row,
                })
                local BtnLabel = Library:Create('TextLabel', {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    TextColor3 = Library.DimColor,
                    Text = Info.Text or Info.Title or "",
                    Parent = Btn,
                })
                Btn.MouseEnter:Connect(function()
                    TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Library.AccentDark}):Play()
                    TweenService:Create(BtnLabel, TweenInfo.new(0.15), {TextColor3 = Library.White}):Play()
                end)
                Btn.MouseLeave:Connect(function()
                    TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Library.SliderTrack}):Play()
                    TweenService:Create(BtnLabel, TweenInfo.new(0.15), {TextColor3 = Library.DimColor}):Play()
                end)
                Btn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        Library:SafeCallback(Info.Func or Info.Callback)
                    end
                end)
                return { Container = Container }
            end

            function Groupbox:AddLabel(Text, DoesWrap)
                local Label = {}
                local TL = Library:Create('TextLabel', {
                    Size = UDim2.new(1, -8, 0, 18),
                    Position = UDim2.new(0, 4, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextColor3 = Library.DimColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = DoesWrap or false,
                    Text = Text or "",
                    Parent = Container,
                })
                Label.TextLabel = TL
                Label.Container = Container
                function Label:SetText(t) TL.Text = t end
                function Label:AddColorPicker(Idx, CInfo)
                    CInfo = CInfo or {}
                    CInfo.Default = CInfo.Default or Color3.new(1, 1, 1)
                    local CP = { Value = CInfo.Default, Type = 'ColorPicker', Callback = CInfo.Callback or function() end }
                    Options[Idx] = CP
                    local Disp = RoundFrame({
                        Size = UDim2.new(0, 28, 0, 14), Position = UDim2.new(1, -32, 0, 2),
                        BackgroundColor3 = CInfo.Default, BorderSizePixel = 0, CornerRadius = 3, Parent = TL,
                    })
                    Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = Disp })
                    local PO = Library:Create('Frame', {
                        BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.new(0, 200, 0, 180),
                        Visible = false, ZIndex = 30, Parent = ScreenGui,
                    })
                    local PI = RoundFrame({
                        Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
                        BackgroundColor3 = Library.MainColor, BorderSizePixel = 0, CornerRadius = 8, ZIndex = 31, Parent = PO,
                    })
                    local SVMap = Library:Create('ImageLabel', {
                        Size = UDim2.new(1, -16, 0, 140), Position = UDim2.new(0, 4, 0, 4),
                        BackgroundColor3 = Color3.new(1, 0, 0), BorderSizePixel = 0,
                        Image = 'rbxassetid://4155801252', ZIndex = 32, Parent = PI,
                    })
                    local HueBar = Library:Create('Frame', {
                        Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 4, 0, 150),
                        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 32, Parent = PI,
                    })
                    Library:Create('UIGradient', {
                        Rotation = 90,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                            ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
                            ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
                            ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
                            ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
                            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
                        }), Parent = HueBar,
                    })
                    local cH, cS, cV = Color3.toHSV(CInfo.Default)
                    local SVC = Library:Create('Frame', {
                        Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(cS, 0, 1 - cV, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0, ZIndex = 34, Parent = SVMap,
                    })
                    Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = SVC })
                    local HC = Library:Create('Frame', {
                        Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, cH, 0),
                        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 34, Parent = HueBar,
                    })
                    local function cDisp()
                        CP.Value = Color3.fromHSV(cH, cS, cV)
                        SVMap.BackgroundColor3 = Color3.fromHSV(cH, 1, 1)
                        Disp.BackgroundColor3 = CP.Value
                        SVC.Position = UDim2.new(cS, 0, 1 - cV, 0)
                        HC.Position = UDim2.new(0, 0, cH, 0)
                        Library:SafeCallback(CP.Callback, CP.Value)
                    end
                    SVMap.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                                cS = math.clamp((Mouse.X - SVMap.AbsolutePosition.X) / SVMap.AbsoluteSize.X, 0, 1)
                                cV = 1 - math.clamp((Mouse.Y - SVMap.AbsolutePosition.Y) / SVMap.AbsoluteSize.Y, 0, 1)
                                cDisp() RenderStepped:Wait()
                            end
                            Library:AttemptSave()
                        end
                    end)
                    HueBar.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                                cH = math.clamp((Mouse.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                                cDisp() RenderStepped:Wait()
                            end
                            Library:AttemptSave()
                        end
                    end)
                    Disp.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            PO.Position = UDim2.fromOffset(Disp.AbsolutePosition.X, Disp.AbsolutePosition.Y + 18)
                            PO.Visible = not PO.Visible
                        end
                    end)
                    Library:GiveSignal(InputService.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 and PO.Visible then
                            local p, s = PO.AbsolutePosition, PO.AbsoluteSize
                            if Mouse.X < p.X or Mouse.X > p.X + s.X or Mouse.Y < p.Y or Mouse.Y > p.Y + s.Y then PO.Visible = false end
                        end
                    end))
                    cDisp()
                    function CP:SetValueRGB(c) cH, cS, cV = Color3.toHSV(c) cDisp() end
                    function CP:OnChanged(cb) CP.Callback = cb cb(CP.Value) end
                    return Label
                end
                function Label:AddKeyPicker(Idx, KInfo) return Label end
                function Label:AddTooltip(t) return Label end
                return Label
            end

            function Groupbox:AddDropdown(Info)
                Info = Info or {}
                Info.Values = Info.Values or {}
                assert(Info.Default, 'AddDropdown: Missing default value')
                local Dropdown = {
                    Value = Info.Default, Values = Info.Values,
                    Type = 'Dropdown', Callback = Info.Callback or function() end,
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
                    BorderSizePixel = 0,
                    CornerRadius = 6,
                    Parent = Row,
                })
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
                    TextSize = 12,
                    TextColor3 = Library.DimColor,
                    Text = "v",
                    Parent = Outer,
                })
                local MenuOuter = Library:Create('Frame', {
                    BackgroundColor3 = Color3.new(0, 0, 0),
                    Size = UDim2.new(1, -8, 0, 0),
                    Position = UDim2.new(0, 4, 0, 28),
                    Visible = false, ZIndex = 20, Parent = Row,
                })
                local MenuInner = RoundFrame({
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = Library.MainColor,
                    BorderSizePixel = 0,
                    CornerRadius = 6,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 21, Parent = MenuOuter,
                })
                Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, ZIndex = 22, Parent = MenuInner })
                Library:Create('UIListLayout', {
                    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), ZIndex = 23, Parent = MenuInner,
                })
                Library:Create('UIPadding', { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), ZIndex = 23, Parent = MenuInner })

                local optFrames = {}
                local function refreshOpts()
                    for _, f in ipairs(optFrames) do f:Destroy() end
                    optFrames = {}
                    for i, val in ipairs(Dropdown.Values) do
                        local Opt = Library:Create('TextButton', {
                            Size = UDim2.new(1, -8, 0, 22),
                            BackgroundTransparency = 1,
                            Font = Enum.Font.Gotham,
                            TextSize = 13,
                            TextColor3 = val == Dropdown.Value and Library.AccentColor or Library.FontColor,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Text = "  " .. tostring(val),
                            ZIndex = 24, Parent = MenuInner,
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
                return Dropdown
            end

            function Groupbox:AddKeyPicker(Info)
                Info = Info or {}
                Info.Default = Info.Default or 'None'
                local KP = {
                    Value = Info.Default, Mode = Info.Mode or 'Toggle', Toggled = false,
                    Type = 'KeyPicker', Callback = Info.Callback or function() end,
                }
                Options[Info.Title] = KP
                local Row = Library:Create('Frame', {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    Parent = Container,
                })
                Library:Create('TextLabel', {
                    Size = UDim2.new(0, 200, 0, 20),
                    Position = UDim2.new(0, 4, 0, 4),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    TextColor3 = Library.DimColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = Info.Title,
                    Parent = Row,
                })
                local KB = RoundFrame({
                    Size = UDim2.new(0, 60, 0, 20),
                    Position = UDim2.new(1, -68, 0, 4),
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderSizePixel = 0, CornerRadius = 4, Parent = Row,
                })
                Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = KB })
                local KL = Library:Create('TextLabel', {
                    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold, TextSize = 11,
                    TextColor3 = Library.FontColor, Text = Info.Default, Parent = KB,
                })
                KB.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        KL.Text = "..."
                        local ev
                        ev = InputService.InputBegan:Connect(function(i2)
                            local k
                            if i2.UserInputType == Enum.UserInputType.Keyboard then k = i2.KeyCode.Name
                            elseif i2.UserInputType == Enum.UserInputType.MouseButton1 then k = 'MB1'
                            elseif i2.UserInputType == Enum.UserInputType.MouseButton2 then k = 'MB2' end
                            if k then KL.Text = k KP.Value = k Library:SafeCallback(KP.Callback, k) Library:AttemptSave() ev:Disconnect() end
                        end)
                    end
                end)
                function KP:GetState()
                    if KP.Mode == 'Always' then return true end
                    if KP.Mode == 'Hold' then
                        if KP.Value == 'MB1' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
                        if KP.Value == 'MB2' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
                        return InputService:IsKeyDown(Enum.KeyCode[KP.Value])
                    end
                    return KP.Toggled
                end
                function KP:SetValue(d) KL.Text = d[1] KP.Value = d[1] KP.Mode = d[2] or KP.Mode end
                function KP:OnChanged(cb) KP.Callback = cb end
                return KP
            end

            function Groupbox:AddColorPicker(Info)
                Info = Info or {}
                Info.Default = Info.Default or Color3.new(1, 1, 1)
                local CP = { Value = Info.Default, Type = 'ColorPicker', Callback = Info.Callback or function() end }
                Options[Info.Title] = CP
                local Row = Library:Create('Frame', {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    Parent = Container,
                })
                Library:Create('TextLabel', {
                    Size = UDim2.new(0, 200, 0, 20),
                    Position = UDim2.new(0, 4, 0, 4),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
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
                    BorderSizePixel = 0, CornerRadius = 4, Parent = Row,
                })
                Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = Disp })
                local PO = Library:Create('Frame', {
                    BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.new(0, 200, 0, 180),
                    Visible = false, ZIndex = 30, Parent = ScreenGui,
                })
                local PI = RoundFrame({
                    Size = UDim2.new(1, -2, 1, -2), Position = UDim2.new(0, 1, 0, 1),
                    BackgroundColor3 = Library.MainColor, BorderSizePixel = 0, CornerRadius = 8, ZIndex = 31, Parent = PO,
                })
                local SVMap = Library:Create('ImageLabel', {
                    Size = UDim2.new(1, -16, 0, 140), Position = UDim2.new(0, 4, 0, 4),
                    BackgroundColor3 = Color3.new(1, 0, 0), BorderSizePixel = 0,
                    Image = 'rbxassetid://4155801252', ZIndex = 32, Parent = PI,
                })
                local HueBar = Library:Create('Frame', {
                    Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 4, 0, 150),
                    BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 32, Parent = PI,
                })
                Library:Create('UIGradient', {
                    Rotation = 90,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                        ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
                        ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
                        ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
                        ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
                    }), Parent = HueBar,
                })
                local cH, cS, cV = Color3.toHSV(Info.Default)
                local SVC = Library:Create('Frame', {
                    Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(cS, 0, 1 - cV, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0, ZIndex = 34, Parent = SVMap,
                })
                Library:Create('UICorner', { CornerRadius = UDim.new(1, 0), Parent = SVC })
                local HC = Library:Create('Frame', {
                    Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, cH, 0),
                    BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 34, Parent = HueBar,
                })
                local function cDisp()
                    CP.Value = Color3.fromHSV(cH, cS, cV)
                    SVMap.BackgroundColor3 = Color3.fromHSV(cH, 1, 1)
                    Disp.BackgroundColor3 = CP.Value
                    SVC.Position = UDim2.new(cS, 0, 1 - cV, 0)
                    HC.Position = UDim2.new(0, 0, cH, 0)
                    Library:SafeCallback(CP.Callback, CP.Value)
                end
                SVMap.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                            cS = math.clamp((Mouse.X - SVMap.AbsolutePosition.X) / SVMap.AbsoluteSize.X, 0, 1)
                            cV = 1 - math.clamp((Mouse.Y - SVMap.AbsolutePosition.Y) / SVMap.AbsoluteSize.Y, 0, 1)
                            cDisp() RenderStepped:Wait()
                        end
                        Library:AttemptSave()
                    end
                end)
                HueBar.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                            cH = math.clamp((Mouse.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                            cDisp() RenderStepped:Wait()
                        end
                        Library:AttemptSave()
                    end
                end)
                Disp.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        PO.Position = UDim2.fromOffset(Disp.AbsolutePosition.X, Disp.AbsolutePosition.Y + 22)
                        PO.Visible = not PO.Visible
                    end
                end)
                Library:GiveSignal(InputService.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 and PO.Visible then
                        local p, s = PO.AbsolutePosition, PO.AbsoluteSize
                        if Mouse.X < p.X or Mouse.X > p.X + s.X or Mouse.Y < p.Y or Mouse.Y > p.Y + s.Y then PO.Visible = false end
                    end
                end))
                cDisp()
                function CP:SetValueRGB(c) cH, cS, cV = Color3.toHSV(c) cDisp() end
                function CP:OnChanged(cb) CP.Callback = cb cb(CP.Value) end
                return CP
            end

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
                    Font = Enum.Font.Gotham,
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
                    BorderSizePixel = 0, CornerRadius = 4, Parent = Row,
                })
                Library:Create('UIStroke', { Color = Library.BorderColor, Thickness = 1, Parent = Box })
                local TB = Library:Create('TextBox', {
                    Size = UDim2.new(1, -8, 1, 0),
                    Position = UDim2.new(0, 4, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Library.FontColor,
                    PlaceholderColor3 = Library.MutedColor,
                    PlaceholderText = Info.Placeholder or "",
                    Text = Info.Default or "",
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                    Parent = Box,
                })
                TB.FocusLost:Connect(function()
                    InputObj.Value = TB.Text
                    Library:SafeCallback(InputObj.Callback, InputObj.Value)
                    Library:AttemptSave()
                end)
                function InputObj:SetValue(val) TB.Text = val InputObj.Value = val end
                function InputObj:OnChanged(cb) InputObj.Callback = cb end
                return InputObj
            end

            function Groupbox:AddBlank(size)
                Library:Create('Frame', {
                    Size = UDim2.new(1, 0, 0, size or 10),
                    BackgroundTransparency = 1,
                    Parent = Container,
                })
            end

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
