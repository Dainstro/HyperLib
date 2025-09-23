-- Hyper UI Library - Modern Roblox UI Framework
-- Created by Dainstro for Hyper Hub

local HyperUI = {}
HyperUI.__index = HyperUI

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Colors and themes
HyperUI.Themes = {
    Dark = {
        Background = Color3.fromRGB(25, 25, 35),
        Secondary = Color3.fromRGB(35, 35, 45),
        Accent = Color3.fromRGB(0, 170, 255),
        Text = Color3.fromRGB(240, 240, 240),
        Border = Color3.fromRGB(60, 60, 70)
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 245),
        Secondary = Color3.fromRGB(220, 220, 230),
        Accent = Color3.fromRGB(0, 120, 215),
        Text = Color3.fromRGB(30, 30, 30),
        Border = Color3.fromRGB(200, 200, 210)
    }
}

-- Utility functions
function HyperUI:Create(class, properties)
    local object = Instance.new(class)
    for property, value in pairs(properties) do
        object[property] = value
    end
    return object
end

function HyperUI:Tween(object, properties, duration, easingStyle, easingDirection)
    local tweenInfo = TweenInfo.new(duration or 0.3, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out)
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Main Window
function HyperUI:CreateWindow(options)
    options = options or {}
    local window = setmetatable({}, self)
    
    window.Name = options.Name or "Hyper UI"
    window.Theme = options.Theme or "Dark"
    window.AccentColor = options.AccentColor or self.Themes[window.Theme].Accent
    window.Enabled = false
    
    -- Create main screen GUI
    window.ScreenGui = self:Create("ScreenGui", {
        Name = "HyperUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    
    -- Main container
    window.MainFrame = self:Create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0.5, -250, 0.5, -200),
        BackgroundColor3 = self.Themes[window.Theme].Background,
        BorderColor3 = self.Themes[window.Theme].Border,
        BorderSizePixel = 2,
        ClipsDescendants = true,
        Parent = window.ScreenGui
    })
    
    -- Corner rounding
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = window.MainFrame
    })
    
    -- Drop shadow
    local shadow = self:Create("ImageLabel", {
        Name = "Shadow",
        Size = UDim2.new(1, 10, 1, 10),
        Position = UDim2.new(0, -5, 0, -5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.8,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        ZIndex = 0,
        Parent = window.MainFrame
    })
    
    -- Title bar
    window.TitleBar = self:Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = self.Themes[window.Theme].Secondary,
        BorderSizePixel = 0,
        Parent = window.MainFrame
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = window.TitleBar
    })
    
    -- Title text
    window.TitleLabel = self:Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = window.Name,
        TextColor3 = self.Themes[window.Theme].Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamSemibold,
        Parent = window.TitleBar
    })
    
    -- Close button
    window.CloseButton = self:Create("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0, 5),
        BackgroundColor3 = Color3.fromRGB(220, 70, 70),
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        Parent = window.TitleBar
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = window.CloseButton
    })
    
    -- Tab buttons container
    window.TabContainer = self:Create("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(0, 120, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = self.Themes[window.Theme].Secondary,
        BorderSizePixel = 0,
        Parent = window.MainFrame
    })
    
    -- Content frame
    window.ContentFrame = self:Create("Frame", {
        Name = "ContentFrame",
        Size = UDim2.new(1, -120, 1, -40),
        Position = UDim2.new(0, 120, 0, 40),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = window.MainFrame
    })
    
    -- Initialize
    window.Tabs = {}
    window.CurrentTab = nil
    window.Dragging = false
    window.DragStart = nil
    window.StartPosition = nil
    
    -- Connect events
    window.CloseButton.MouseButton1Click:Connect(function()
        window:Toggle()
    end)
    
    -- Dragging functionality
    window.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            window.Dragging = true
            window.DragStart = input.Position
            window.StartPosition = window.MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    window.Dragging = false
                end
            end)
        end
    end)
    
    window.TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            window.LastInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == window.LastInput and window.Dragging then
            local delta = input.Position - window.DragStart
            window.MainFrame.Position = UDim2.new(
                window.StartPosition.X.Scale,
                window.StartPosition.X.Offset + delta.X,
                window.StartPosition.Y.Scale,
                window.StartPosition.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Keybind to toggle UI
    if options.ToggleKey then
        UserInputService.InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == options.ToggleKey then
                window:Toggle()
            end
        end)
    end
    
    window.ScreenGui.Parent = game.CoreGui
    return window
end

function HyperUI:Toggle()
    self.Enabled = not self.Enabled
    self.MainFrame.Visible = self.Enabled
    
    if self.Enabled then
        self:Tween(self.MainFrame, {Position = UDim2.new(0.5, -250, 0.5, -200)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end
end

-- Tabs
function HyperUI:CreateTab(name)
    local tab = {}
    tab.Name = name
    tab.Visible = false
    
    -- Tab button
    tab.Button = self:Create("TextButton", {
        Name = name .. "TabButton",
        Size = UDim2.new(1, -10, 0, 35),
        Position = UDim2.new(0, 5, 0, 5 + (#self.Tabs * 40)),
        BackgroundColor3 = self.Themes[self.Theme].Secondary,
        BorderColor3 = self.Themes[self.Theme].Border,
        BorderSizePixel = 1,
        Text = name,
        TextColor3 = self.Themes[self.Theme].Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        Parent = self.TabContainer
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = tab.Button
    })
    
    -- Tab content
    tab.Content = self:Create("ScrollingFrame", {
        Name = name .. "Content",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.AccentColor,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
        Parent = self.ContentFrame
    })
    
    self:Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = tab.Content
    })
    
    -- Button click event
    tab.Button.MouseButton1Click:Connect(function()
        self:SwitchTab(tab)
    end)
    
    table.insert(self.Tabs, tab)
    
    if #self.Tabs == 1 then
        self:SwitchTab(tab)
    end
    
    return tab
end

function HyperUI:SwitchTab(tab)
    if self.CurrentTab then
        self.CurrentTab.Visible = false
        self.CurrentTab.Content.Visible = false
        self:Tween(self.CurrentTab.Button, {BackgroundColor3 = self.Themes[self.Theme].Secondary}, 0.2)
    end
    
    self.CurrentTab = tab
    tab.Visible = true
    tab.Content.Visible = true
    self:Tween(tab.Button, {BackgroundColor3 = self.AccentColor}, 0.2)
end

-- Elements
function HyperUI:CreateSection(tab, name)
    local section = {}
    
    section.Container = self:Create("Frame", {
        Name = name .. "Section",
        Size = UDim2.new(1, -20, 0, 40),
        BackgroundColor3 = self.Themes[self.Theme].Secondary,
        BorderSizePixel = 0,
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = section.Container
    })
    
    section.Title = self:Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Themes[self.Theme].Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamSemibold,
        Parent = section.Container
    })
    
    section.Content = self:Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -10, 0, 0),
        Position = UDim2.new(0, 5, 0, 45),
        BackgroundTransparency = 1,
        Parent = section.Container
    })
    
    self:Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = section.Content
    })
    
    function section:Resize(height)
        section.Container.Size = UDim2.new(1, -20, 0, height)
        tab.Content.CanvasSize = UDim2.new(0, 0, 0, tab.Content.UIListLayout.AbsoluteContentSize.Y)
    end
    
    return section
end

function HyperUI:CreateButton(tab, options)
    local button = {}
    options = options or {}
    
    button.Container = self:Create("Frame", {
        Name = options.Name .. "Button",
        Size = UDim2.new(1, -20, 0, 35),
        BackgroundTransparency = 1,
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    
    button.Button = self:Create("TextButton", {
        Name = "Button",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = self.Themes[self.Theme].Secondary,
        BorderColor3 = self.Themes[self.Theme].Border,
        BorderSizePixel = 1,
        Text = options.Name or "Button",
        TextColor3 = self.Themes[self.Theme].Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        Parent = button.Container
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = button.Button
    })
    
    -- Hover effects
    button.Button.MouseEnter:Connect(function()
        self:Tween(button.Button, {BackgroundColor3 = self.AccentColor}, 0.2)
    end)
    
    button.Button.MouseLeave:Connect(function()
        self:Tween(button.Button, {BackgroundColor3 = self.Themes[self.Theme].Secondary}, 0.2)
    end)
    
    -- Click event
    if options.Callback then
        button.Button.MouseButton1Click:Connect(function()
            options.Callback()
            self:Tween(button.Button, {Size = UDim2.new(0.95, 0, 0.9, 0)}, 0.1)
            self:Tween(button.Button, {Size = UDim2.new(1, 0, 1, 0)}, 0.1)
        end)
    end
    
    return button
end

function HyperUI:CreateToggle(tab, options)
    local toggle = {}
    options = options or {}
    toggle.Value = options.Default or false
    
    toggle.Container = self:Create("Frame", {
        Name = options.Name .. "Toggle",
        Size = UDim2.new(1, -20, 0, 30),
        BackgroundTransparency = 1,
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    
    toggle.Label = self:Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(0.7, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = options.Name or "Toggle",
        TextColor3 = self.Themes[self.Theme].Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
        Parent = toggle.Container
    })
    
    toggle.Background = self:Create("Frame", {
        Name = "ToggleBackground",
        Size = UDim2.new(0, 50, 0, 25),
        Position = UDim2.new(1, -55, 0.5, -12.5),
        BackgroundColor3 = self.Themes[self.Theme].Secondary,
        BorderSizePixel = 0,
        Parent = toggle.Container
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = toggle.Background
    })
    
    toggle.Slider = self:Create("Frame", {
        Name = "Slider",
        Size = UDim2.new(0, 21, 0, 21),
        Position = UDim2.new(0, 2, 0.5, -10.5),
        BackgroundColor3 = self.Themes[self.Theme].Text,
        BorderSizePixel = 0,
        Parent = toggle.Background
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = toggle.Slider
    })
    
    -- Set initial state
    toggle:Set(toggle.Value)
    
    -- Click event
    toggle.Background.MouseButton1Click:Connect(function()
        toggle:Set(not toggle.Value)
        if options.Callback then
            options.Callback(toggle.Value)
        end
    end)
    
    function toggle:Set(value)
        toggle.Value = value
        if value then
            self:Tween(toggle.Slider, {Position = UDim2.new(1, -23, 0.5, -10.5)}, 0.2)
            self:Tween(toggle.Background, {BackgroundColor3 = self.AccentColor}, 0.2)
        else
            self:Tween(toggle.Slider, {Position = UDim2.new(0, 2, 0.5, -10.5)}, 0.2)
            self:Tween(toggle.Background, {BackgroundColor3 = self.Themes[self.Theme].Secondary}, 0.2)
        end
    end
    
    return toggle
end

function HyperUI:CreateSlider(tab, options)
    local slider = {}
    options = options or {}
    options.Min = options.Min or 0
    options.Max = options.Max or 100
    options.Default = options.Default or options.Min
    
    slider.Value = options.Default
    slider.Dragging = false
    
    slider.Container = self:Create("Frame", {
        Name = options.Name .. "Slider",
        Size = UDim2.new(1, -20, 0, 60),
        BackgroundTransparency = 1,
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    
    slider.Label = self:Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = options.Name or "Slider",
        TextColor3 = self.Themes[self.Theme].Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
        Parent = slider.Container
    })
    
    slider.ValueLabel = self:Create("TextLabel", {
        Name = "Value",
        Size = UDim2.new(0, 60, 0, 20),
        Position = UDim2.new(1, -60, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(slider.Value),
        TextColor3 = self.Themes[self.Theme].Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = Enum.Font.Gotham,
        Parent = slider.Container
    })
    
    slider.Track = self:Create("Frame", {
        Name = "Track",
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundColor3 = self.Themes[self.Theme].Secondary,
        BorderSizePixel = 0,
        Parent = slider.Container
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 3),
        Parent = slider.Track
    })
    
    slider.Fill = self:Create("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = self.AccentColor,
        BorderSizePixel = 0,
        Parent = slider.Track
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 3),
        Parent = slider.Fill
    })
    
    slider.Handle = self:Create("Frame", {
        Name = "Handle",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, -8, 0.5, -8),
        BackgroundColor3 = self.Themes[self.Theme].Text,
        BorderSizePixel = 0,
        Parent = slider.Track
    })
    
    self:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = slider.Handle
    })
    
    self:Create("UIStroke", {
        Color = self.AccentColor,
        Thickness = 2,
        Parent = slider.Handle
    })
    
    -- Set initial value
    slider:Set(slider.Value)
    
    -- Dragging functionality
    local function updateSlider(input)
        local relativeX = (input.Position.X - slider.Track.AbsolutePosition.X) / slider.Track.AbsoluteSize.X
        relativeX = math.clamp(relativeX, 0, 1)
        local value = options.Min + (relativeX * (options.Max - options.Min))
        
        if options.Round then
            value = math.floor(value / options.Round) * options.Round
        end
        
        slider:Set(value)
        
        if options.Callback then
            options.Callback(value)
        end
    end
    
    slider.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            slider.Dragging = true
            updateSlider(input)
        end
    end)
    
    slider.Track.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and slider.Dragging then
            updateSlider(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            slider.Dragging = false
        end
    end)
    
    function slider:Set(value)
        slider.Value = math.clamp(value, options.Min, options.Max)
        slider.ValueLabel.Text = tostring(slider.Value)
        
        local percentage = (slider.Value - options.Min) / (options.Max - options.Min)
        slider.Fill.Size = UDim2.new(percentage, 0, 1, 0)
        slider.Handle.Position = UDim2.new(percentage, -8, 0.5, -8)
    end
    
    return slider
end

function HyperUI:CreateLabel(tab, text)
    local label = self:Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -20, 0, 25),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Themes[self.Theme].Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
        LayoutOrder = #tab.Content:GetChildren(),
        Parent = tab.Content
    })
    
    return label
end

function HyperUI:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

return HyperUI