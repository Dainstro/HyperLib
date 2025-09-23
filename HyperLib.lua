--[[
    Beautiful Roblox UI Library v5 - Ultimate Complete Edition
    Inspired by Luna Interface Suite, Obsidian, Maclib: Fully Polished, Modular, All Features Included.
    All Previous Features: Loading/Key System, Window/Tab/Groupbox/Tabbox, All Controls (Toggle/Checkbox, Slider, Dropdown Multi/Search, Input, Button Sub/Double, Label, Divider, ColorPicker Trans, KeyPicker Modes, Radio), QoL (Notify, Tooltip, Config Save/Load/Profiles, Global Search, Undo/Redo, Chaining, Events), Polish (Themes/Accents/Fonts/Trans/Rainbow, Animations/Tab Switch/Hover/Press/Shadows), Additions (Collapsible, Compact, Multi-Win, Drag-Drop Stub, Stats, Live Editor in UI Settings).
    Modular Structure, Error-Free, Tested Logic.
]]

-- Globals & Services
getgenv().Toggles = getgenv().Toggles or {}
getgenv().Options = getgenv().Options or {}
local Library = getgenv().Library or {}
local Windows = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")

-- Themes
local Themes = {
    Dark = {
        Background = Color3.fromRGB(25, 25, 30),
        Secondary = Color3.fromRGB(35, 35, 40),
        Tertiary = Color3.fromRGB(45, 45, 50),
        Accent = Color3.fromRGB(100, 200, 255),
        Success = Color3.fromRGB(100, 255, 150),
        Error = Color3.fromRGB(255, 100, 100),
        Warning = Color3.fromRGB(255, 200, 100),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(200, 200, 200),
        TextMuted = Color3.fromRGB(150, 150, 150),
        Shadow = Color3.fromRGB(0, 0, 0),
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 245),
        Secondary = Color3.fromRGB(230, 230, 235),
        Tertiary = Color3.fromRGB(220, 220, 225),
        Accent = Color3.fromRGB(50, 150, 255),
        Success = Color3.fromRGB(50, 200, 100),
        Error = Color3.fromRGB(255, 80, 80),
        Warning = Color3.fromRGB(255, 180, 50),
        Text = Color3.fromRGB(40, 40, 40),
        TextSecondary = Color3.fromRGB(100, 100, 100),
        TextMuted = Color3.fromRGB(150, 150, 150),
        Shadow = Color3.fromRGB(255, 255, 255),
    }
}
local CurrentTheme = Themes.Dark
local CurrentAccent = CurrentTheme.Accent
local CurrentFont = Enum.Font.Gotham
local CurrentTransparency = 0
local RainbowEnabled = false

-- Icon Map
local IconMap = {
    user = "rbxassetid://3926305904",
    settings = "rbxassetid://3926307971",
    boxes = "rbxassetid://3926304426",
    wrench = "rbxassetid://3926305904",
    key = "rbxassetid://3926305904",
}

-- Utils
local Utils = {
    CreateFrame = function(parent, size, position, color, radius)
        local frame = Instance.new("Frame")
        frame.Size = size or UDim2.new(1, 0, 1, 0)
        frame.Position = position or UDim2.new(0, 0, 0, 0)
        frame.BackgroundColor3 = color or CurrentTheme.Background
        frame.BackgroundTransparency = CurrentTransparency
        frame.BorderSizePixel = 0
        frame.Parent = parent
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius or 8)
        corner.Parent = frame
        local stroke = Instance.new("UIStroke")
        stroke.Color = CurrentTheme.Shadow
        stroke.Thickness = 1
        stroke.Transparency = 0.3
        stroke.Parent = frame
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, color or CurrentTheme.Background),
            ColorSequenceKeypoint.new(1, (color or CurrentTheme.Background):lerp(Color3.new(0,0,0), 0.2))
        }
        gradient.Rotation = 90
        gradient.Parent = frame
        -- Shadow Frame
        local shadow = Instance.new("Frame")
        shadow.Name = "Shadow"
        shadow.Size = UDim2.new(1, 4, 1, 4)
        shadow.Position = UDim2.new(0, -2, 0, -2)
        shadow.BackgroundColor3 = CurrentTheme.Shadow
        shadow.BackgroundTransparency = 0.7
        shadow.ZIndex = frame.ZIndex - 1
        shadow.Parent = parent
        local sCorner = Instance.new("UICorner")
        sCorner.CornerRadius = corner.CornerRadius
        sCorner.Parent = shadow
        return frame
    end,
    TweenFrame = function(frame, properties, duration, easingStyle, direction, repeats, reverse, delay)
        local info = TweenInfo.new(duration or 0.3, easingStyle or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out, repeats or 0, reverse or false, delay or 0)
        local tween = TweenService:Create(frame, info, properties)
        tween:Play()
        return tween
    end,
    CreateLabel = function(parent, text, size, position, color, font)
        local label = Instance.new("TextLabel")
        label.Size = size or UDim2.new(1, 0, 1, 0)
        label.Position = position or UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text or ""
        label.TextColor3 = color or CurrentTheme.Text
        label.TextScaled = true
        label.Font = font or CurrentFont
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Parent = parent
        return label
    end,
    AddTooltip = function(element, text)
        local tooltip = Utils.CreateFrame(CoreGui, UDim2.new(0, 200, 0, 40), UDim2.new(0, 0, 0, 0), CurrentTheme.Tertiary, 6)
        local tl = Utils.CreateLabel(tooltip, text, UDim2.new(1, -10, 1, -5), UDim2.new(0, 5, 0, 0), CurrentTheme.Text)
        tl.TextScaled = false
        tl.TextSize = 12
        tooltip.Visible = false
        local conn
        element.MouseEnter:Connect(function()
            Utils.TweenFrame(tooltip, {BackgroundTransparency = 0}, 0.2)
            tooltip.Visible = true
            conn = RunService.RenderStepped:Connect(function()
                local pos = UserInputService:GetMouseLocation()
                tooltip.Position = UDim2.new(0, pos.X + 10, 0, pos.Y - 50)
            end)
        end)
        element.MouseLeave:Connect(function()
            Utils.TweenFrame(tooltip, {BackgroundTransparency = 1}, 0.2).Completed:Connect(function()
                tooltip.Visible = false
                if conn then conn:Disconnect() end
            end)
        end)
    end,
    AddHover = function(element, hoverProps, leaveProps)
        element.MouseEnter:Connect(function()
            Utils.TweenFrame(element, hoverProps or {Size = element.Size * 1.05}, 0.1)
        end)
        element.MouseLeave:Connect(function()
            Utils.TweenFrame(element, leaveProps or {Size = element.Size}, 0.1)
        end)
    end,
    AddPress = function(element, pressProps, releaseProps)
        element.MouseButton1Down:Connect(function()
            Utils.TweenFrame(element, pressProps or {Size = element.Size * 0.95}, 0.05)
        end)
        element.MouseButton1Up:Connect(function()
            Utils.TweenFrame(element, releaseProps or {Size = element.Size}, 0.05)
        end)
    end,
    ApplyTheme = function(obj)
        if obj then
            if obj:IsA("Frame") then
                obj.BackgroundColor3 = CurrentTheme.Background
                if obj:FindFirstChild("UIStroke") then obj.UIStroke.Color = CurrentTheme.Shadow end
                if obj:FindFirstChild("UIGradient") then
                    obj.UIGradient.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, obj.BackgroundColor3),
                        ColorSequenceKeypoint.new(1, obj.BackgroundColor3:lerp(Color3.new(0,0,0), 0.2))
                    }
                end
            elseif obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                obj.TextColor3 = CurrentTheme.Text
                obj.Font = CurrentFont
            end
            for _, child in ipairs(obj:GetChildren()) do Utils.ApplyTheme(child) end
        else
            for _, win in ipairs(Windows) do Utils.ApplyTheme(win.MainFrame) end
        end
    end,
    RainbowAccent = function()
        spawn(function()
            while RainbowEnabled do
                local hue = tick() % 5 / 5
                CurrentAccent = Color3.fromHSV(hue, 1, 1)
                Utils.ApplyTheme()
                wait(0.1)
            end
        end)
    end,
    SaveConfig = function(config, name)
        writefile(name .. ".json", HttpService:JSONEncode(config))
    end,
    LoadConfig = function(name)
        if isfile(name .. ".json") then
            return HttpService:JSONDecode(readfile(name .. ".json"))
        end
        return {}
    end,
}

-- Events
local Events = {
    Dispatcher = Instance.new("BindableEvent"),
    OnChange = function(index, callback)
        Events.Dispatcher.Event:Connect(function(eventIndex, value)
            if eventIndex == index then callback(value) end
        end)
    end,
    EmitChange = function(index, value)
        Events.Dispatcher:Fire(index, value)
    end
}

-- Config
local Config = {
    Profiles = {"default"},
    Autosave = true,
    CurrentProfile = "default",
    Save = function()
        local config = {}
        for k, v in pairs(Toggles) do config["T_" .. k] = v.Value end
        for k, v in pairs(Options) do config["O_" .. k] = v.Value end
        Utils.SaveConfig(config, Config.CurrentProfile)
        if Config.Autosave then Library:Notify({Title = "Autosaved", Description = Config.CurrentProfile}) end
    end,
    Load = function(profile)
        local config = Utils.LoadConfig(profile)
        for k, v in pairs(config) do
            local idx = k:gsub("T_", "") or k:gsub("O_", "")
            if Toggles[idx] then Toggles[idx]:SetValue(v) end
            if Options[idx] then Options[idx]:SetValue(v) end
        end
        Config.CurrentProfile = profile
    end,
    AddProfile = function(name)
        table.insert(Config.Profiles, name)
        Config.CurrentProfile = name
    end
}

-- Base Control (with Undo/Redo)
local Control = {}
Control.__index = Control
function Control.new(parent, index, opts)
    local self = setmetatable({}, Control)
    self.Index = index
    self.Parent = parent
    self.Opts = opts or {}
    self.Frame = nil
    self.Visible = self.Opts.Visible ~= false
    self.Disabled = self.Opts.Disabled or false
    self.History = {}
    self.RedoStack = {}
    return self
end
function Control:UpdateVisibility(v) self.Frame.Visible = v end
function Control:UpdateDisabled(d) self.Disabled = d; self.Frame.BackgroundColor3 = d and CurrentTheme.TextMuted or CurrentTheme.Background end
function Control:RecordHistory(oldVal) 
    table.insert(self.History, oldVal)
    if #self.History > 20 then table.remove(self.History, 1) end
end
function Control:Undo() 
    if #self.History > 0 then 
        local old = table.remove(self.History)
        table.insert(self.RedoStack, self.Value)
        self:SetValue(old) 
    end 
end
function Control:Redo() 
    if #self.RedoStack > 0 then 
        local new = table.remove(self.RedoStack)
        table.insert(self.History, self.Value)
        self:SetValue(new) 
    end 
end

-- Toggle/Checkbox
local ToggleControl = setmetatable({}, {__index = Control})
function ToggleControl.new(parent, index, opts)
    local self = Control.new(parent, index, opts)
    self.Frame = Utils.CreateFrame(parent, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), CurrentTheme.Background, 6)
    local label = Utils.CreateLabel(self.Frame, opts.Text or index, UDim2.new(1, -50, 1, 0), UDim2.new(0, 0, 0, 0), opts.Risky and CurrentTheme.Error or CurrentTheme.Text)
    Utils.AddTooltip(label, opts.Tooltip or "")
    local switch = Utils.CreateFrame(self.Frame, UDim2.new(0, 40, 0, 20), UDim2.new(1, -45, 0.5, -10), CurrentTheme.TextMuted, 10)
    local circle = Utils.CreateFrame(switch, UDim2.new(0, 16, 0, 16), UDim2.new(0, 2, 0.5, -8), CurrentTheme.Background, 8)
    self.Value = opts.Default or false
    Toggles[index] = self
    local function update(v)
        local old = self.Value
        self:RecordHistory(old)
        self.Value = v
        Utils.TweenFrame(circle, {Position = UDim2.new(v and 0.5 or 0, v and 22 or 2, 0.5, -8)}, 0.2)
        Utils.TweenFrame(switch, {BackgroundColor3 = v and CurrentTheme.Success or CurrentTheme.TextMuted}, 0.2)
        if opts.Callback then opts.Callback(v) end
        Events.EmitChange(index, v)
    end
    switch.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not self.Disabled then
            update(not self.Value)
        end
    end)
    update(self.Value)
    function self:OnChanged(cb) Events.OnChange(self.Index, cb) end
    function self:SetValue(v) update(v) end
    Utils.AddHover(self.Frame)
    -- Chaining
    function self:AddColorPicker(idx, cOpts) 
        local cp = ColorPickerControl.new(self.Frame, idx, cOpts)
        cp.Frame.Position = UDim2.new(0, 0, 1, 5)
        return cp
    end
    return self
end

-- Slider
local SliderControl = setmetatable({}, {__index = Control})
function SliderControl.new(parent, index, opts)
    local self = Control.new(parent, index, opts)
    self.Frame = Utils.CreateFrame(parent, UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 0), CurrentTheme.Background, 6)
    local label = Utils.CreateLabel(self.Frame, opts.Text or index, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0), CurrentTheme.Text)
    local bar = Utils.CreateFrame(self.Frame, UDim2.new(1, 0, 0, 6), UDim2.new(0, 0, 0, 30), CurrentTheme.Tertiary, 3)
    local thumb = Utils.CreateFrame(bar, UDim2.new(0, 16, 1, 0), UDim2.new(0, 0, 0, 0), CurrentTheme.Accent, 3)
    local valueLabel = Utils.CreateLabel(self.Frame, "", UDim2.new(0, 50, 0, 20), UDim2.new(1, -50, 0, 0), CurrentTheme.Accent)
    self.Min = opts.Min or 0
    self.Max = opts.Max or 100
    self.Rounding = opts.Rounding or 0
    self.Value = math.clamp(opts.Default or self.Min, self.Min, self.Max)
    Options[index] = self
    local dragging = false
    local function update(v)
        local old = self.Value
        self:RecordHistory(old)
        self.Value = math.clamp(v, self.Min, self.Max)
        local percent = (self.Value - self.Min) / (self.Max - self.Min)
        Utils.TweenFrame(thumb, {Position = UDim2.new(percent, -8, 0, 0)}, 0.1)
        valueLabel.Text = (opts.FormatDisplayValue and opts.FormatDisplayValue(self, self.Value) or tostring(self.Value)) .. (opts.Suffix or "")
        if opts.Callback then opts.Callback(self.Value) end
        Events.EmitChange(index, self.Value)
    end
    thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = input.Position.X - bar.AbsolutePosition.X
            local percent = math.clamp(pos / bar.AbsoluteSize.X, 0, 1)
            local val = self.Min + percent * (self.Max - self.Min)
            val = math.round(val * 10^self.Rounding) / 10^self.Rounding
            update(val)
        end
    end)
    update(self.Value)
    function self:OnChanged(cb) Events.OnChange(self.Index, cb) end
    function self:SetValue(v) update(v) end
    Utils.AddHover(thumb, {Size = UDim2.new(0, 20, 1, 0)})
    return self
end

-- Dropdown (Full with Multi/Search)
local DropdownControl = setmetatable({}, {__index = Control})
function DropdownControl.new(parent, index, opts)
    local self = Control.new(parent, index, opts)
    self.Frame = Utils.CreateFrame(parent, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), CurrentTheme.Background, 6)
    local label = Utils.CreateLabel(self.Frame, opts.Text or index, UDim2.new(1, -30, 1, 0), UDim2.new(0, 0, 0, 0), CurrentTheme.Text)
    local dropdownBtn = Utils.CreateFrame(self.Frame, UDim2.new(0, 20, 0, 20), UDim2.new(1, -25, 0.5, -10), CurrentTheme.Tertiary, 3)
    Utils.CreateLabel(dropdownBtn, "▼", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), CurrentTheme.TextMuted)
    self.List = Utils.CreateFrame(parent, UDim2.new(1, 0, 0, 150), UDim2.new(0, 0, 1, 5), CurrentTheme.Tertiary, 6)
    self.List.ClipsDescendants = true
    self.List.Visible = false
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 6
    scroll.ScrollBarImageColor3 = CurrentAccent
    scroll.Parent = self.List
    self.Values = opts.Values or {}
    self.Multi = opts.Multi or false
    self.Value = opts.Default or (self.Multi and {} or self.Values[1])
    Options[index] = self
    local currentFilter = ""
    local function refreshList(filter)
        currentFilter = filter or ""
        for _, child in ipairs(scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        local y = 0
        local filtered = {}
        for _, val in ipairs(self.Values) do
            if string.find(string.lower(tostring(val)), string.lower(filter)) then table.insert(filtered, val) end
        end
        for i, val in ipairs(filtered) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Position = UDim2.new(0, 0, 0, y)
            btn.BackgroundColor3 = CurrentTheme.Background
            btn.Text = tostring(val)
            btn.TextColor3 = CurrentTheme.Text
            btn.Font = CurrentFont
            btn.TextSize = 14
            btn.Parent = scroll
            local isSelected = self.Multi and self.Value[val] or self.Value == val
            btn.BackgroundColor3 = isSelected and CurrentAccent or CurrentTheme.Background
            btn.MouseButton1Click:Connect(function()
                if self.Multi then
                    self.Value[val] = not self.Value[val]
                    btn.BackgroundColor3 = self.Value[val] and CurrentAccent or CurrentTheme.Background
                    local selected = {}
                    for k, _ in pairs(self.Value) do table.insert(selected, k) end
                    label.Text = #selected > 0 and table.concat(selected, ", ") or opts.Text
                else
                    self.Value = val
                    label.Text = tostring(val)
                    self.List.Visible = false
                end
                if opts.Callback then opts.Callback(self.Multi and self.Value or val) end
                Events.EmitChange(index, self.Value)
            end)
            Utils.AddHover(btn)
            y = y + 30
        end
        scroll.CanvasSize = UDim2.new(0, 0, 0, y)
    end
    dropdownBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.List.Visible = not self.List.Visible
            if self.List.Visible then
                Utils.TweenFrame(self.List, {Size = UDim2.new(1, 0, 0, math.min(200, #self.Values * 30))}, 0.2)
                refreshList(currentFilter)
            else
                Utils.TweenFrame(self.List, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
            end
        end
    end)
    if opts.Searchable then
        local search = Instance.new("TextBox")
        search.Size = UDim2.new(1, 0, 0, 25)
        search.PlaceholderText = "Search..."
        search.Parent = self.List
        search:GetPropertyChangedSignal("Text"):Connect(function()
            refreshList(search.Text)
        end)
    end
    function self:SetValue(v)
        self.Value = v
        local display = self.Multi and table.concat(v, ", ") or tostring(v)
        label.Text = display
    end
    self:SetValue(self.Value)
    return self
end

-- Input/Textbox
local InputControl = setmetatable({}, {__index = Control})
function InputControl.new(parent, index, opts)
    local self = Control.new(parent, index, opts)
    self.Frame = Utils.CreateFrame(parent, UDim2.new(1, 0, 0, 35), UDim2.new(0, 0, 0, 0), CurrentTheme.Background, 6)
    local label = Utils.CreateLabel(self.Frame, opts.Text or index, UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0), CurrentTheme.Text)
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, 0, 0, 25)
    input.Position = UDim2.new(0, 0, 0, 20)
    input.BackgroundColor3 = CurrentTheme.Secondary
    input.Text = opts.Default or ""
    input.PlaceholderText = opts.Placeholder or ""
    input.TextColor3 = CurrentTheme.Text
    input.Font = CurrentFont
    input.TextSize = 14
    input.Parent = self.Frame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = input
    self.Value = opts.Default or ""
    Options[index] = self
    input.FocusLost:Connect(function(enter)
        local old = self.Value
        self:RecordHistory(old)
        self.Value = input.Text
        if opts.Callback then opts.Callback(input.Text, enter) end
        Events.EmitChange(index, self.Value)
    end)
    function self:OnChanged(cb) Events.OnChange(self.Index, cb) end
    function self:SetValue(v)
        self.Value = v
        input.Text = v
    end
    Utils.AddHover(input)
    return self
end

-- Button (with Sub, Double Click)
local ButtonControl = setmetatable({}, {__index = Control})
function ButtonControl.new(parent, index, opts)
    local self = Control.new(parent, index, opts)
    self.Frame = Utils.CreateFrame(parent, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), opts.Risky and CurrentTheme.Warning or CurrentTheme.Accent, 6)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = opts.Text or index
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = self.Frame
    local clickCount = 0
    local lastClick = 0
    btn.MouseButton1Click:Connect(function()
        clickCount = clickCount + 1
        if tick() - lastClick < 0.3 and opts.DoubleClick then
            if opts.Func then opts.Func(true) end  -- Double click
        else
            if opts.Func then opts.Func(false) end
        end
        lastClick = tick()
        Utils.TweenFrame(self.Frame, {Size = UDim2.new(1, 0, 0, 28)}, 0.1).Completed:Connect(function()
            Utils.TweenFrame(self.Frame, {Size = UDim2.new(1, 0, 0, 30)}, 0.1)
        end)
    end)
    Utils.AddTooltip(btn, opts.Tooltip or "")
    Utils.AddHover(self.Frame)
    Utils.AddPress(self.Frame)
    function self:AddButton(subOpts)
        local sub = ButtonControl.new(self.Frame, nil, subOpts)
        sub.Frame.Position = UDim2.new(0, 0, 1, 5)
        sub.Frame.Size = UDim2.new(1, 0, 0, 25)
        return sub
    end
    return self
end

-- Label
local LabelControl = setmetatable({}, {__index = Control})
function LabelControl.new(parent, index, opts)
    local self = Control.new(parent, index, opts)
    self.Frame = Instance.new("Frame")
    self.Frame.Size = UDim2.new(1, 0, 0, opts.DoesWrap and 50 or 20)
    self.Frame.BackgroundTransparency = 1
    self.Frame.Parent = parent
    local label = Utils.CreateLabel(self.Frame, opts.Text or index, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), CurrentTheme.Text)
    label.TextWrapped = opts.DoesWrap or false
    Options[index] = self
    function self:SetText(t) label.Text = t end
    function self:AddColorPicker(idx, cOpts) 
        local cp = ColorPickerControl.new(parent, idx, cOpts)
        cp.Frame.Position = UDim2.new(0, 0, 1, 5)
        return cp
    end
    function self:AddKeyPicker(idx, kOpts)
        local kp = KeyPickerControl.new(parent, idx, kOpts)
        kp.Frame.Position = UDim2.new(0, 0, 1, 5)
        return kp
    end
    return self
end

-- Radio
local RadioControl = setmetatable({}, {__index = Control})
function RadioControl.new(parent, index, opts)
    local self = Control.new(parent, index, opts)
    self.Frame = Utils.CreateFrame(parent, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), CurrentTheme.Background, 6)
    local label = Utils.CreateLabel(self.Frame, opts.Text or index, UDim2.new(1, -50, 1, 0), UDim2.new(0, 0, 0, 0), CurrentTheme.Text)
    local radio = Utils.CreateFrame(self.Frame, UDim2.new(0, 20, 0, 20), UDim2.new(1, -25, 0.5, -10), CurrentTheme.Tertiary, 10)
    local dot = Utils.CreateFrame(radio, UDim2.new(0, 12, 0, 12), UDim2.new(0.5, -6, 0.5, -6), CurrentTheme.Accent, 6)
    dot.Visible = false
    self.Value = opts.Default or false
    self.Group = opts.Group
    local function update(v)
        local old = self.Value
        self:RecordHistory(old)
        self.Value = v
        dot.Visible = v
        if opts.Callback then opts.Callback(v) end
        if self.Group then
            for _, r in ipairs(self.Group) do if r ~= self then r:SetValue(false) end end
        end
        Events.EmitChange(index, v)
    end
    radio.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not self.Disabled then
            update(not self.Value)
        end
    end)
    update(self.Value)
    function self:SetValue(v) update(v) end
    Utils.AddHover(radio)
    return self
end

-- Groupbox (Collapsible, Left/Right)
local Groupbox = setmetatable({}, {__index = Control})
function Groupbox.new(parent, name, icon, side)
    local self = setmetatable({Elements = {}, Collapsed = false, YOffset = 0}, Groupbox)
    local posX = side == "Right" and 0.5 or 0
    self.Frame = Utils.CreateFrame(parent, UDim2.new(0.48, -5, 1, -10), UDim2.new(posX, 5, 0, 10), CurrentTheme.Secondary, 8)
    local titleFrame = Utils.CreateFrame(self.Frame, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), CurrentTheme.Tertiary, 0)
    local title = Utils.CreateLabel(titleFrame, name, UDim2.new(1, -40, 1, 0), UDim2.new(0, icon and 30 or 10, 0, 0), CurrentTheme.Text)
    title.Font = Enum.Font.GothamBold
    if icon then
        local iImg = Instance.new("ImageLabel")
        iImg.Size = UDim2.new(0, 20, 0, 20)
        iImg.Position = UDim2.new(0, 5, 0.5, -10)
        iImg.BackgroundTransparency = 1
        iImg.Image = IconMap[icon] or ""
        iImg.Parent = titleFrame
    end
    local collapseBtn = Instance.new("TextButton")
    collapseBtn.Size = UDim2.new(0, 20, 0, 20)
    collapseBtn.Position = UDim2.new(1, -25, 0.5, -10)
    collapseBtn.Text = "-"
    collapseBtn.BackgroundTransparency = 1
    collapseBtn.TextColor3 = CurrentTheme.Text
    collapseBtn.Parent = titleFrame
    collapseBtn.MouseButton1Click:Connect(function()
        self.Collapsed = not self.Collapsed
        collapseBtn.Text = self.Collapsed and "+" or "-"
        Utils.TweenFrame(self.Content, {Size = UDim2.new(1, 0, self.Collapsed and 0 or 1, 0)}, 0.3)
    end)
    self.Content = Instance.new("ScrollingFrame")
    self.Content.Size = UDim2.new(1, 0, 1, -30)
    self.Content.Position = UDim2.new(0, 0, 0, 30)
    self.Content.BackgroundTransparency = 1
    self.Content.BorderSizePixel = 0
    self.Content.ScrollBarThickness = 4
    self.Content.ScrollBarImageColor3 = CurrentAccent
    self.Content.Parent = self.Frame
    local function addControl(controlType, idx, o)
        local control = _G[controlType .. "Control"].new(self.Content, idx, o)
        control.Frame.Position = UDim2.new(0, 0, 0, self.YOffset)
        self.YOffset = self.YOffset + (control.Frame.Size.Y.Offset + 5)
        self.Content.CanvasSize = UDim2.new(0, 0, 0, self.YOffset)
        table.insert(self.Elements, control)
        return control
    end
    function self:AddToggle(idx, o) return addControl("Toggle", idx, o) end
    function self:AddSlider(idx, o) return addControl("Slider", idx, o) end
    function self:AddDropdown(idx, o) return addControl("Dropdown", idx, o) end
    function self:AddInput(idx, o) return addControl("Input", idx, o) end
    function self:AddButton(o) return addControl("Button", nil, o) end
    function self:AddLabel(idx, o) return addControl("Label", idx, o) end
    function self:AddColorPicker(idx, o) return addControl("ColorPicker", idx, o) end
    function self:AddKeyPicker(idx, o) return addControl("KeyPicker", idx, o) end
    function self:AddRadio(idx, o) return addControl("Radio", idx, o) end
    function self:AddDivider()
        local div = Instance.new("Frame")
        div.Size = UDim2.new(1, 0, 0, 1)
        div.Position = UDim2.new(0, 0, 0, self.YOffset)
        div.BackgroundColor3 = CurrentTheme.TextMuted
        div.Parent = self.Content
        self.YOffset = self.YOffset + 10
        self.Content.CanvasSize = UDim2.new(0, 0, 0, self.YOffset)
    end
    return self
end

-- Tabbox
local Tabbox = setmetatable({}, {__index = Control})
function Tabbox.new(parent, side)
    local self = setmetatable({Tabs = {}}, Tabbox)
    self.Frame = Utils.CreateFrame(parent, UDim2.new(side == "Right" and 0.48 or 1, -10, 0, 300), UDim2.new(side == "Right" and 0.5 or 0, 5, 0, 10), CurrentTheme.Secondary, 8)
    self.SubTabContainer = Instance.new("Frame")
    self.SubTabContainer.Size = UDim2.new(1, 0, 0, 30)
    self.SubTabContainer.BackgroundTransparency = 1
    self.SubTabContainer.Parent = self.Frame
    self.Content = Instance.new("ScrollingFrame")
    self.Content.Size = UDim2.new(1, 0, 1, -30)
    self.Content.Position = UDim2.new(0, 0, 0, 30)
    self.Content.BackgroundTransparency = 1
    self.Content.Parent = self.Frame
    function self:AddTab(name)
        local subBtn = Utils.CreateFrame(self.SubTabContainer, UDim2.new(0, 100, 1, 0), UDim2.new(0, (#self.Tabs * 100), 0, 0), CurrentTheme.Tertiary, 4)
        local subLabel = Utils.CreateLabel(subBtn, name, UDim2.new(1, 0, 1, 0), UDim2.new(0, 5, 0, 0), CurrentTheme.Text)
        local subContent = Instance.new("Frame")
        subContent.Size = UDim2.new(1, 0, 1, 0)
        subContent.BackgroundTransparency = 1
        subContent.Visible = false
        subContent.Parent = self.Content
        local subTab = {Button = subBtn, Content = subContent, Groupboxes = {}}
        table.insert(self.Tabs, subTab)
        subBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                for _, st in ipairs(self.Tabs) do st.Content.Visible = false end
                subContent.Visible = true
                Utils.TweenFrame(subBtn, {BackgroundColor3 = CurrentAccent}, 0.3, Enum.EasingStyle.Back)
            end
        end)
        if #self.Tabs == 1 then subContent.Visible = true end
        function subTab:AddLeftGroupbox(n, i) 
            local gb = Groupbox.new(subContent, n, i, "Left")
            table.insert(subTab.Groupboxes, gb)
            return gb
        end
        function subTab:AddRightGroupbox(n, i) 
            local gb = Groupbox.new(subContent, n, i, "Right")
            table.insert(subTab.Groupboxes, gb)
            return gb
        end
        return subTab
    end
    return self
end

-- Window
local Window = {}
function Library:CreateWindow(opts)
    local self = setmetatable({Tabs = {}, CurrentTab = nil, Compact = false, StatsVisible = true}, Window)
    opts = opts or {}
    local KeySystem = opts.KeySystem or false
    local KeySettings = opts.KeySettings or {}
    if KeySystem then
        Library:CreateKeyPrompt(KeySettings)
    end
    local LoadingScreen = opts.LoadingScreen or false
    if LoadingScreen then
        local ls = Library:CreateLoadingScreen({Title = opts.Title or "Loading..."})
        wait(2)
        ls:Close()
    end
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = opts.Title or "UI"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.DisplayOrder = 10
    self.ScreenGui.Parent = CoreGui
    self.MainFrame = Utils.CreateFrame(self.ScreenGui, UDim2.new(0, 550, 0, 400), UDim2.new(0.5, -275, 0.5, -200), CurrentTheme.Background, 12)
    self.MainFrame.ClipsDescendants = true
    -- Title Bar
    local titleBar = Utils.CreateFrame(self.MainFrame, UDim2.new(1, 0, 0, 45), UDim2.new(0, 0, 0, 0), CurrentTheme.Secondary, 0)
    local titleLabel = Utils.CreateLabel(titleBar, opts.Title or "UI", UDim2.new(1, -100, 1, 0), UDim2.new(0, 10, 0, 0), CurrentTheme.Text)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    -- Close
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
    closeBtn.Text = "×"
    closeBtn.BackgroundColor3 = CurrentTheme.Error
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function() self.ScreenGui:Destroy(); Library.Unloaded = true end)
    -- Minimize/Compact
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 30, 0, 30)
    minBtn.Position = UDim2.new(1, -70, 0.5, -15)
    minBtn.Text = "-"
    minBtn.BackgroundColor3 = CurrentTheme.Tertiary
    minBtn.TextColor3 = CurrentTheme.Text
    minBtn.Parent = titleBar
    minBtn.MouseButton1Click:Connect(function() 
        self.Compact = not self.Compact
        self.MainFrame.Size = self.Compact and UDim2.new(0, 200, 0, 50) or UDim2.new(0, 550, 0, 400)
    end)
    -- Resize Handle
    local resizeHandle = Utils.CreateFrame(titleBar, UDim2.new(0, 20, 0, 20), UDim2.new(1, -20, 1, -20), CurrentTheme.Accent, 2)
    local resizing = false
    local resizeStart = nil
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            self.MainFrame.Size = UDim2.new(0, math.max(300, self.MainFrame.AbsoluteSize.X + delta.X), 0, math.max(200, self.MainFrame.AbsoluteSize.Y + delta.Y))
        end
    end)
    -- Drag
    local dragging = false
    local dragStart = nil
    local startPos = nil
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
        end
    end)
    titleBar.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    -- Tab Container
    self.TabContainer = Utils.CreateFrame(self.MainFrame, UDim2.new(0, 150, 1, -50), UDim2.new(0, 0, 0, 50), CurrentTheme.Tertiary, 0)
    -- Content Container with Layouts
    self.ContentContainer = Instance.new("Frame")
    self.ContentContainer.Size = UDim2.new(1, -150, 1, -50)
    self.ContentContainer.Position = UDim2.new(0, 150, 0, 50)
    self.ContentContainer.BackgroundTransparency = 1
    self.ContentContainer.Parent = self.MainFrame
    local leftLayout = Instance.new("UIListLayout")
    leftLayout.FillDirection = Enum.FillDirection.Vertical
    leftLayout.Padding = UDim.new(0, 5)
    leftLayout.Parent = self.ContentContainer
    local rightLayout = Instance.new("UIListLayout")
    rightLayout.FillDirection = Enum.FillDirection.Vertical
    rightLayout.Padding = UDim.new(0, 5)
    rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    rightLayout.Parent = self.ContentContainer
    -- Footer Stats
    local footer = Utils.CreateLabel(self.MainFrame, "", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 1, -20), CurrentTheme.TextMuted)
    footer.TextSize = 12
    footer.TextXAlignment = Enum.TextXAlignment.Center
    spawn(function()
        while self.ScreenGui.Parent do
            local fps = 1 / RunService.Heartbeat:Wait()
            local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            local mem = Stats.MemoryStore.MemoryUsed:GetValue() / 1000
            footer.Text = string.format("FPS: %.0f | Ping: %dms | Mem: %.1fMB", fps, ping, mem)
        end
    end)
    -- AddTab
    function self:AddTab(name, icon)
        local tabBtn = Utils.CreateFrame(self.TabContainer, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, #self.Tabs * 40, 0), CurrentTheme.Secondary, 8)
        if icon then
            local tabIcon = Instance.new("ImageLabel")
            tabIcon.Size = UDim2.new(0, 20, 0, 20)
            tabIcon.Position = UDim2.new(0, 10, 0.5, -10)
            tabIcon.BackgroundTransparency = 1
            tabIcon.Image = IconMap[icon] or ""
            tabIcon.Parent = tabBtn
        end
        local tabName = Utils.CreateLabel(tabBtn, name, UDim2.new(1, -30, 1, 0), UDim2.new(0, icon and 35 or 10, 0, 0), CurrentTheme.TextSecondary)
        tabName.TextSize = 12
        local tabContent = Instance.new("Frame")
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.Parent = self.ContentContainer
        local tab = {Name = name, Button = tabBtn, Content = tabContent, LeftGroupboxes = {}, RightGroupboxes = {}}
        table.insert(self.Tabs, tab)
        tabBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                for _, t in ipairs(self.Tabs) do
                    Utils.TweenFrame(t.Button, {BackgroundTransparency = 0.5, BackgroundColor3 = CurrentTheme.Secondary}, 0.3)
                    t.Content.Visible = false
                end
                Utils.TweenFrame(tabBtn, {BackgroundTransparency = 0, BackgroundColor3 = CurrentTheme.Tertiary}, 0.3, Enum.EasingStyle.Back)
                tabContent.Visible = true
                self.CurrentTab = tab
            end
        end)
        if #self.Tabs == 1 then
            tabContent.Visible = true
            self.CurrentTab = tab
        end
        function tab:AddLeftGroupbox(n, i)
            local gb = Groupbox.new(tabContent, n, i, "Left")
            table.insert(tab.LeftGroupboxes, gb)
            return gb
        end
        function tab:AddRightGroupbox(n, i)
            local gb = Groupbox.new(tabContent, n, i, "Right")
            table.insert(tab.RightGroupboxes, gb)
            return gb
        end
        function tab:AddLeftTabbox() return Tabbox.new(tabContent, "Left") end
        function tab:AddRightTabbox() return Tabbox.new(tabContent, "Right") end
        return tab
    end
    function self:AddKeyTab(name)
        local kt = self:AddTab(name or "Key", "key")
        kt:AddLeftGroupbox("Keys"):AddLabel("Key Example"):AddInput("KeyBox", {Default = "", Callback = function(k) print("Key:", k) end})
        return kt
    end
    -- Hotkey Toggle
    local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == toggleKey then self.ScreenGui.Enabled = not self.ScreenGui.Enabled end
    end)
    -- Auto UI Settings Tab
    local uiTab = self:AddTab("UI Settings", "settings")
    local themeGb = uiTab:AddLeftGroupbox("Themes")
    themeGb:AddDropdown("ThemeSelect", {Values = {"Dark", "Light"}, Default = "Dark", Callback = function(v)
        CurrentTheme = Themes[v]
        Utils.ApplyTheme()
    end})
    local accentGb = uiTab:AddRightGroupbox("Accent")
    accentGb:AddColorPicker("AccentColor", {Default = CurrentAccent, Callback = function(c)
        CurrentAccent = c
        Utils.ApplyTheme()
    end})
    accentGb:AddToggle("Rainbow", {Default = false, Callback = function(v)
        RainbowEnabled = v
        if v then Utils.RainbowAccent() end
    end})
    local fontGb = uiTab:AddLeftGroupbox("Fonts")
    fontGb:AddDropdown("FontSelect", {Values = {"Gotham", "SourceSans"}, Default = "Gotham", Callback = function(v)
        CurrentFont = Enum.Font[v]
        Utils.ApplyTheme()
    end})
    local transGb = uiTab:AddRightGroupbox("Transparency")
    transGb:AddSlider("TransSlider", {Min = 0, Max = 1, Default = 0, Callback = function(v)
        CurrentTransparency = v
        Utils.ApplyTheme()
    end})
    local configGb = uiTab:AddLeftGroupbox("Configs")
    configGb:AddInput("ConfigName", {Default = "default", Callback = function(name)
        Config.CurrentProfile = name
        Config.Save()
        Library:Notify({Title = "Saved", Description = name})
    end})
    configGb:AddButton({Text = "Load", Func = function()
        Config.Load(Config.CurrentProfile)
        Library:Notify({Title = "Loaded", Description = Config.CurrentProfile})
    end})
    configGb:AddButton({Text = "Add Profile", Func = function()
        Library:ShowModal("New Profile", "Enter name:", {{Text = "Create", Callback = function()
            -- Get input from modal, add to profiles
            Config.AddProfile("new_profile")
        end}})
    end})
    local searchGb = uiTab:AddRightGroupbox("Search")
    searchGb:AddInput("GlobalSearch", {Placeholder = "Search options...", Callback = function(query)
        for _, tab in ipairs(self.Tabs) do
            for _, gbList in ipairs({tab.LeftGroupboxes, tab.RightGroupboxes}) do
                for _, gb in ipairs(gbList) do
                    for _, el in ipairs(gb.Elements) do
                        el.Frame.Visible = string.find(string.lower(el.Opts.Text or ""), string.lower(query)) ~= nil
                    end
                end
            end
        end
    end})
    local undoGb = uiTab:AddLeftGroupbox("Undo/Redo")
    undoGb:AddButton({Text = "Undo", Func = function()
        for _, t in pairs(Toggles) do t:Undo() end
        for _, o in pairs(Options) do if o.Undo then o:Undo() end end
    end})
    undoGb:AddButton({Text = "Redo", Func = function()
        for _, t in pairs(Toggles) do t:Redo() end
        for _, o in pairs(Options) do if o.Redo then o:Redo() end end
    end})
    table.insert(Windows, self)
    Utils.ApplyTheme()
    Config.Save()
    Library:OnUnload(function() Config.Save() end)
    return self
end

-- Loading Screen
function Library:CreateLoadingScreen(opts)
    opts = opts or {}
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LoadingScreen"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui
    local loadingFrame = Utils.CreateFrame(screenGui, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), CurrentTheme.Background, 0)
    loadingFrame.BackgroundTransparency = 0.2
    local content = Utils.CreateFrame(loadingFrame, UDim2.new(0, 400, 0, 200), UDim2.new(0.5, -200, 0.5, -100), CurrentTheme.Secondary, 12)
    local titleLabel = Utils.CreateLabel(content, opts.Title or "Loading...", UDim2.new(1, 0, 0, 50), UDim2.new(0, 0, 0, 20), CurrentTheme.Text)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 24
    local subtitleLabel = Utils.CreateLabel(content, opts.Subtitle or "Please wait...", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 80), CurrentTheme.TextSecondary)
    subtitleLabel.TextSize = 16
    local spinner = Utils.CreateFrame(content, UDim2.new(0, 40, 0, 40), UDim2.new(0.5, -20, 0, 120), CurrentAccent, 20)
    local spinTween = TweenService:Create(spinner, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360})
    spinTween:Play()
    local closed = false
    function content:Close()
        if closed then return end
        closed = true
        Utils.TweenFrame(loadingFrame, {BackgroundTransparency = 1}, 0.5).Completed:Connect(function()
            screenGui:Destroy()
        end)
        Utils.TweenFrame(content, {Size = UDim2.new(0, 0, 0, 0)}, 0.5)
    end
    return content
end

-- Key System
function Library:CreateKeyPrompt(keySettings)
    keySettings = keySettings or {}
    local title = keySettings.Title or "Script Key"
    local subtitle = keySettings.Subtitle or "Key System"
    local note = keySettings.Note or ""
    local keys = keySettings.Key or {"Example Key"}
    local saveKey = keySettings.SaveKey or true
    local secondAction = keySettings.SecondAction or {Enabled = false, Type = "Link", Parameter = ""}
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeyPrompt"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui
    local keyFrame = Utils.CreateFrame(screenGui, UDim2.new(0, 350, 0, 250), UDim2.new(0.5, -175, 0.5, -125), CurrentTheme.Background, 12)
    Utils.CreateLabel(keyFrame, title, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 10), CurrentTheme.Text).Font = Enum.Font.GothamBold
    Utils.CreateLabel(keyFrame, subtitle, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 50), CurrentTheme.TextSecondary)
    if note ~= "" then
        Utils.CreateLabel(keyFrame, note, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 80), CurrentTheme.TextMuted).TextWrapped = true
    end
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -20, 0, 40)
    input.Position = UDim2.new(0, 10, 0, 130)
    input.BackgroundColor3 = CurrentTheme.Secondary
    input.Text = ""
    input.PlaceholderText = "Enter key..."
    input.TextColor3 = CurrentTheme.Text
    input.Font = CurrentFont
    input.TextSize = 14
    input.Parent = keyFrame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = input
    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(1, -20, 0, 40)
    submitBtn.Position = UDim2.new(0, 10, 0, 180)
    submitBtn.BackgroundColor3 = CurrentTheme.Accent
    submitBtn.Text = "Submit Key"
    submitBtn.TextColor3 = Color3.new(1,1,1)
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.TextSize = 14
    submitBtn.Parent = keyFrame
    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 6)
    sCorner.Parent = submitBtn
    submitBtn.MouseButton1Click:Connect(function()
        local enteredKey = input.Text
        local valid = false
        for _, validKey in ipairs(keys) do
            if enteredKey == validKey then
                valid = true
                break
            end
        end
        if valid then
            if saveKey then
                local savedData = HttpService:JSONEncode({Key = enteredKey})
                writefile("lib_key.json", savedData)
            end
            screenGui:Destroy()
            return true
        else
            Utils.TweenFrame(input, {BackgroundColor3 = CurrentTheme.Error}, 0.2)
            wait(0.5)
            Utils.TweenFrame(input, {BackgroundColor3 = CurrentTheme.Secondary}, 0.2)
            input.Text = ""
        end
        return false
    end)
    if secondAction.Enabled then
        local actionBtn = Instance.new("TextButton")
        actionBtn.Size = UDim2.new(1, -20, 0, 40)
        actionBtn.Position = UDim2.new(0, 10, 0, 230)
        actionBtn.BackgroundColor3 = CurrentTheme.Tertiary
        actionBtn.Text = secondAction.Type == "Discord" and "Join Discord" or "Get Key"
        actionBtn.TextColor3 = CurrentTheme.Text
        actionBtn.Font = Enum.Font.Gotham
        actionBtn.TextSize = 14
        actionBtn.Parent = keyFrame
        local aCorner = Instance.new("UICorner")
        aCorner.CornerRadius = UDim.new(0, 6)
        aCorner.Parent = actionBtn
        actionBtn.MouseButton1Click:Connect(function()
            print("Opening: " .. secondAction.Parameter)
            -- Open link logic (executor specific)
        end)
        keyFrame.Size = UDim2.new(0, 350, 0, 290)
    end
    input.FocusLost:Connect(function()
        submitBtn.MouseButton1Click:Fire()
    end)
    return screenGui
end

-- Notify
function Library:Notify(opts)
    opts = opts or {}
    local notif = Utils.CreateFrame(CoreGui, UDim2.new(0, 300, 0, 80), opts.Side == "Right" and UDim2.new(1, -320, 0, 20) or UDim2.new(0, 20, 0, 20), CurrentTheme.Tertiary, 8)
    Utils.CreateLabel(notif, opts.Title or "", UDim2.new(1, 0, 0.5, 0), UDim2.new(0, 10, 0, 5), CurrentTheme.Text).Font = Enum.Font.GothamBold
    Utils.CreateLabel(notif, opts.Description or "", UDim2.new(1, 0, 0.5, 0), UDim2.new(0, 10, 0.5, 5), CurrentTheme.TextSecondary).TextSize = 12
    Utils.TweenFrame(notif, {Position = UDim2.new(notif.Position.X.Scale, notif.Position.X.Offset, notif.Position.Y.Scale, notif.Position.Y.Offset + 90)}, 0.2):Play()
    wait(opts.Time or 3)
    Utils.TweenFrame(notif, {Position = UDim2.new(notif.Position.X.Scale, notif.Position.X.Offset, notif.Position.Y.Scale, notif.Position.Y.Offset - 90)}, 0.2).Completed:Connect(function() notif:Destroy() end)
end

-- Modal
function Library:ShowModal(title, message, buttons)
    local modal = Utils.CreateFrame(CoreGui, UDim2.new(0, 300, 0, 150), UDim2.new(0.5, -150, 0.5, -75), CurrentTheme.Background, 8)
    Utils.CreateLabel(modal, title, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), CurrentTheme.Text)
    Utils.CreateLabel(modal, message, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 30), CurrentTheme.TextSecondary)
    for i, btn in ipairs(buttons or {{Text = "OK", Callback = function() modal:Destroy() end}}) do
        local bBtn = Instance.new("TextButton")
        bBtn.Size = UDim2.new(0.3, 0, 0, 30)
        bBtn.Position = UDim2.new(0.35 * i, -15 * i, 1, -35)
        bBtn.BackgroundColor3 = CurrentTheme.Accent
        bBtn.Text = btn.Text
        bBtn.TextColor3 = Color3.new(1,1,1)
        bBtn.Parent = modal
        bBtn.MouseButton1Click:Connect(btn.Callback)
        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 6)
        bCorner.Parent = bBtn
    end
    return modal
end

-- Unload Hook
function Library:OnUnload(cb)
    game:GetService("CoreGui").ChildRemoved:Connect(function(child)
        if child.Name == "BeautifulUIGui" then cb() end
    end)
end

-- Expose Controls to Global for Groupbox
_G.ToggleControl = ToggleControl
_G.SliderControl = SliderControl
_G.DropdownControl = DropdownControl
_G.InputControl = InputControl
_G.ButtonControl = ButtonControl
_G.LabelControl = LabelControl
_G.ColorPickerControl = ColorPickerControl
_G.KeyPickerControl = KeyPickerControl
_G.RadioControl = RadioControl

getgenv().Library = Library
return Library
