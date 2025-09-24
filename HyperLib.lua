-- HyperLib_v2.lua
-- Feature-complete GUI library per your spec:
-- - Opaque default GUI (BluishGray theme)
-- - Theme support with easy custom themes
-- - Global blur toggle (fades in/out while GUI open) to simulate "blur behind GUI"
-- - Tabs with configurable icons passed when creating a tab
-- - Tabs/buttons perfectly centered and symmetrical when collapsed; left aligned when expanded
-- - Built-in controls: CreateButton, CreateToggle, CreateSlider, CreateDropdown
-- - Hotkey to toggle GUI, draggable with screen-edge snapping, notification dot API
-- - Stable ordering and straightforward API: Hyper:CreateWindow(opts) -> window object

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Hyper = {}
Hyper.__index = Hyper

-- Default palette collection
local THEMES = {
	BluishGray = {
		Container = Color3.fromRGB(55, 66, 80),
		TopBar = Color3.fromRGB(42, 52, 65),
		Sidebar = Color3.fromRGB(34, 44, 58),
		Content = Color3.fromRGB(44, 52, 64),
		Button = Color3.fromRGB(72, 90, 112),
		ButtonHover = Color3.fromRGB(92, 110, 132),
		Text = Color3.fromRGB(240, 245, 250),
		Accent = Color3.fromRGB(120, 150, 190),
	},
	DarkPurple = {
		Container = Color3.fromRGB(34, 23, 60),
		TopBar = Color3.fromRGB(26, 20, 40),
		Sidebar = Color3.fromRGB(28, 16, 45),
		Content = Color3.fromRGB(41, 30, 70),
		Button = Color3.fromRGB(93, 36, 140),
		ButtonHover = Color3.fromRGB(113, 56, 170),
		Text = Color3.fromRGB(235, 235, 245),
		Accent = Color3.fromRGB(180, 120, 255),
	},
	Solar = {
		Container = Color3.fromRGB(250, 245, 235),
		TopBar = Color3.fromRGB(240, 230, 210),
		Sidebar = Color3.fromRGB(225, 215, 195),
		Content = Color3.fromRGB(245, 240, 225),
		Button = Color3.fromRGB(200, 165, 90),
		ButtonHover = Color3.fromRGB(220, 185, 110),
		Text = Color3.fromRGB(20, 20, 20),
		Accent = Color3.fromRGB(240, 200, 95),
	}
}

-- Utility functions
local function new(class, props)
	local obj = Instance.new(class)
	if props then
		for k,v in pairs(props) do
			if k == "Parent" then
				obj.Parent = v
			else
				pcall(function() obj[k] = v end)
			end
		end
	end
	return obj
end

local function clamp(v, a, b)
	if v < a then return a end
	if v > b then return b end
	return v
end

-- Manage a global blur effect on Lighting (fade in/out)
local GLOBAL_BLUR_NAME = "_HyperLib_GlobalBlur"
local function setGlobalBlur(enabled, size, time)
	time = time or 0.25
	size = size or 8
	local blur = Lighting:FindFirstChild(GLOBAL_BLUR_NAME)
	if enabled then
		if not blur then
			blur = Instance.new("BlurEffect")
			blur.Name = GLOBAL_BLUR_NAME
			blur.Size = 0
			blur.Parent = Lighting
		end
		TweenService:Create(blur, TweenInfo.new(time), {Size = size}):Play()
	else
		if blur then
			TweenService:Create(blur, TweenInfo.new(time), {Size = 0}):Play()
			-- schedule destroy after fade
			delay(time + 0.05, function()
				local b = Lighting:FindFirstChild(GLOBAL_BLUR_NAME)
				if b and b.Size <= 0.01 then b:Destroy() end
			end)
		end
	end
end

-- API: CreateWindow(opts)
-- opts:
--   Title (string)
--   Theme (string or table)
--   UseGlobalBlur (bool)
--   Hotkey (Enum.KeyCode or nil)
--   StartVisible (bool)
function Hyper:CreateWindow(opts)
	opts = opts or {}
	local Theme = opts.Theme or "BluishGray"
	local palette = type(Theme) == "string" and THEMES[Theme] or Theme
	if not palette then palette = THEMES.BluishGray end

	local UseGlobalBlur = (opts.UseGlobalBlur == nil) and true or opts.UseGlobalBlur
	local Hotkey = opts.Hotkey
	local TitleText = opts.Title or "HyperLib"
	local StartVisible = opts.StartVisible ~= false

	-- Remove any previous GUI with same name
	local existing = PlayerGui:FindFirstChild("HyperLib_v2")
	if existing then existing:Destroy() end

	-- Root ScreenGui
	local ScreenGui = new("ScreenGui", {Name = "HyperLib_v2", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = PlayerGui})

	-- Backdrop (opaque) - directly behind GUI to provide "overlay" look
	local Backdrop = new("Frame", {
		Name = "Backdrop",
		Parent = ScreenGui,
		Size = UDim2.new(1,0,1,0),
		Position = UDim2.new(0,0,0,0),
		BackgroundColor3 = Color3.fromRGB(10,10,10),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0
	})

	-- Main container (approx 40% screen) - opaque
	local Container = new("Frame", {
		Name = "Container",
		Parent = ScreenGui,
		Size = UDim2.new(0.4, 0, 0.4, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = palette.Container,
		BorderSizePixel = 0
	})
	new("UICorner", {Parent = Container, CornerRadius = UDim.new(0, 12)})

	-- Top bar (no inner curved corners)
	local TopBar = new("Frame", {Parent = Container, Name = "TopBar", Size = UDim2.new(1,0,0.12,0), Position = UDim2.new(0,0,0,0), BackgroundColor3 = palette.TopBar, BorderSizePixel = 0})
	local Title = new("TextLabel", {Parent = TopBar, Name = "Title", Size = UDim2.new(1,-20,1,0), Position = UDim2.new(0,10,0,0), BackgroundTransparency = 1, Text = TitleText, TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, Font = Enum.Font.GothamBold, TextColor3 = palette.Text})

	-- Sidebar + content
	local normalWidth, expandedWidth = 0.08, 0.22
	local SideBar = new("Frame", {Parent = Container, Name = "SideBar", Size = UDim2.new(normalWidth,0,0.88,0), Position = UDim2.new(0,0,0.12,0), BackgroundColor3 = palette.Sidebar, BorderSizePixel = 0})
	local ContentFrame = new("Frame", {Parent = Container, Name = "ContentFrame", Size = UDim2.new(1-normalWidth,0,0.88,0), Position = UDim2.new(normalWidth,0,0.12,0), BackgroundColor3 = palette.Content, BorderSizePixel = 0})

	-- No inner corners on TopBar/SideBar/Content (only outer on container)

	-- Layout helpers
	local UIList = new("UIListLayout", {Parent = SideBar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})

	local window = {
		ScreenGui = ScreenGui,
		Container = Container,
		TopBar = TopBar,
		SideBar = SideBar,
		ContentFrame = ContentFrame,
		Tabs = {},
		TabOrder = {},
		Palette = palette,
		UseGlobalBlur = UseGlobalBlur,
		Visible = StartVisible
	}
	setmetatable(window, {__index = Hyper})

	-- Blur management when open/close
	local function applyBlur(active)
		if window.UseGlobalBlur then
			setGlobalBlur(active, 10, 0.28)
			-- fade the backdrop slightly depending on blur
			TweenService:Create(Backdrop, TweenInfo.new(0.28), {BackgroundTransparency = active and 0.5 or 0.85}):Play()
		else
			-- just fade backdrop bigger/smaller
			TweenService:Create(Backdrop, TweenInfo.new(0.18), {BackgroundTransparency = active and 0.5 or 0.85}):Play()
		end
	end

	-- Show/hide API
	function window:SetVisible(v)
		v = not not v
		window.Visible = v
		window.ScreenGui.Enabled = v
		applyBlur(v)
	end

	window.ScreenGui.Enabled = StartVisible
	applyBlur(StartVisible)

	-- Draggable with snapping
	local dragging, dragStart, startPos
	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = Container.Position
			local moveConn
			moveConn = UserInputService.InputChanged:Connect(function(i)
				if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
					local delta = i.Position - dragStart
					Container.Position = UDim2.new(
						startPos.X.Scale, startPos.X.Offset + delta.X,
						startPos.Y.Scale, startPos.Y.Offset + delta.Y
					)
				end
			end)
			local releaseConn
			releaseConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					moveConn:Disconnect(); releaseConn:Disconnect()
					-- snap to edges (simple)
					local screenW, screenH = workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y
					local absX = Container.AbsolutePosition.X
					local absY = Container.AbsolutePosition.Y
					if absX < 40 then
						Container.Position = UDim2.new(0, 8, Container.Position.Y.Scale, Container.Position.Y.Offset)
					elseif absX + Container.AbsoluteSize.X > screenW - 40 then
						Container.Position = UDim2.new(1, -Container.AbsoluteSize.X - 8, Container.Position.Y.Scale, Container.Position.Y.Offset)
					end
					if absY < 40 then
						Container.Position = UDim2.new(Container.Position.X.Scale, Container.Position.X.Offset, 0, 8)
					elseif absY + Container.AbsoluteSize.Y > screenH - 40 then
						Container.Position = UDim2.new(Container.Position.X.Scale, Container.Position.X.Offset, 1, -Container.AbsoluteSize.Y - 8)
					end
				end
			end)
		end
	end)

	-- Sidebar hover behaviour
	local hoverTween = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	SideBar.MouseEnter:Connect(function()
		TweenService:Create(SideBar, hoverTween, {Size = UDim2.new(expandedWidth,0,0.88,0)}):Play()
		TweenService:Create(ContentFrame, hoverTween, {Position = UDim2.new(expandedWidth,0,0.12,0), Size = UDim2.new(1-expandedWidth,0,0.88,0)}):Play()
		-- left align buttons and show labels
		for i, nm in ipairs(window.TabOrder) do
			local t = window.Tabs[nm]
			if t then
				TweenService:Create(t.Button, hoverTween, {Position = UDim2.new(0, 8, 0, 8 + ((i-1) * 52))}):Play()
				t.Label.Visible = true
			end
		end
	end)

	SideBar.MouseLeave:Connect(function()
		TweenService:Create(SideBar, hoverTween, {Size = UDim2.new(normalWidth,0,0.88,0)}):Play()
		TweenService:Create(ContentFrame, hoverTween, {Position = UDim2.new(normalWidth,0,0.12,0), Size = UDim2.new(1-normalWidth,0,0.88,0)}):Play()
		-- center buttons and hide labels
		for i, nm in ipairs(window.TabOrder) do
			local t = window.Tabs[nm]
			if t then
				local yOff = 8 + ((i-1) * 52)
				TweenService:Create(t.Button, hoverTween, {Position = UDim2.new(0.5, 0, 0, yOff)}):Play()
				t.Label.Visible = false
			end
		end
	end)

	-- API: CreateTab({Name, Icon}) -> returns tab object with helper functions
	function window:CreateTab(tabOpts)
		tabOpts = tabOpts or {}
		local name = tabOpts.Name or ("Tab" .. tostring(#window.TabOrder + 1))
		local icon = tabOpts.Icon or ""

		-- Button
		local Button = new("TextButton", {Parent = SideBar, Name = "TabButton_"..name, Size = UDim2.new(1,-12,0,44), BackgroundColor3 = window.Palette.Button, BorderSizePixel = 0, Text = ""})
		new("UICorner", {Parent = Button, CornerRadius = UDim.new(0, 8)})
		new("UIStroke", {Parent = Button, Color = window.Palette.Accent, Thickness = 2, Transparency = 0.6})

		-- Icon image
		local Icon = new("ImageLabel", {Parent = Button, Name = "Icon", Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(0,8,0.5,-14), BackgroundTransparency = 1, Image = icon})

		local Label = new("TextLabel", {Parent = Button, Name = "Label", Size = UDim2.new(1, -48, 1, 0), Position = UDim2.new(0,44,0,0), BackgroundTransparency = 1, Text = name, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 16, TextColor3 = window.Palette.Text, Visible = false})

		-- Content area for the tab
		local Frame = new("Frame", {Parent = ContentFrame, Name = "Content_"..name, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false})

		-- Notification dot API
		local Dot = new("Frame", {Parent = Button, Name = "Dot", Size = UDim2.new(0,10,0,10), Position = UDim2.new(1,-18,0,8), BackgroundColor3 = Color3.fromRGB(255,80,80), BorderSizePixel = 0, Visible = false})
		new("UICorner", {Parent = Dot, CornerRadius = UDim.new(1,0)})

		-- store
		local tab = {Name = name, Button = Button, Icon = Icon, Label = Label, Frame = Frame, Dot = Dot}
		window.Tabs[name] = tab
		table.insert(window.TabOrder, name)

		-- Center alignment when collapsed
		local index = #window.TabOrder
		Button.AnchorPoint = Vector2.new(0.5, 0)
		Button.Position = UDim2.new(0.5, 0, 0, 8 + ((index-1) * 52))

		-- Clicking switches to tab
		Button.MouseButton1Click:Connect(function()
			for _, nm in ipairs(window.TabOrder) do
				local t = window.Tabs[nm]
				if t then t.Frame.Visible = false end
			end
			Frame.Visible = true
		end)

		-- Auto-activate first tab
		if #window.TabOrder == 1 then Frame.Visible = true end

		-- Tab helper methods for adding controls
		function tab:CreateButton(text, callback)
			local btn = new("TextButton", {Parent = Frame, Size = UDim2.new(0.35,0,0,36), Position = UDim2.new(0.05,0,0.05 + (#Frame:GetChildren() * 0), BackgroundTransparency = 0, Text = text, BackgroundColor3 = window.Palette.Button, BorderSizePixel = 0})
			new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})
			btn.Font = Enum.Font.Gotham
			btn.TextColor3 = window.Palette.Text
			btn.TextSize = 16
			btn.AutoButtonColor = true
			btn.MouseButton1Click:Connect(function() pcall(callback) end)
			return btn
		end

		function tab:CreateToggle(text, default, callback)
			local holder = new("Frame", {Parent = Frame, Size = UDim2.new(0.6,0,0,36), Position = UDim2.new(0.05,0,0.05 + (#Frame:GetChildren() * 0)), BackgroundTransparency = 1})
			local label = new("TextLabel", {Parent = holder, Size = UDim2.new(0.7,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextColor3 = window.Palette.Text, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left})
			local toggle = new("TextButton", {Parent = holder, Size = UDim2.new(0,48,0,26), Position = UDim2.new(0.75,0,0.15,0), BackgroundColor3 = (default and window.Palette.ButtonHover or window.Palette.Button), BorderSizePixel = 0, Text = default and "On" or "Off"})
			new("UICorner", {Parent = toggle, CornerRadius = UDim.new(0,8)})
			local state = default and true or false
			toggle.MouseButton1Click:Connect(function()
				state = not state
				toggle.BackgroundColor3 = state and window.Palette.ButtonHover or window.Palette.Button
				toggle.Text = state and "On" or "Off"
				pcall(callback, state)
			end)
			return toggle
		end

		function tab:CreateSlider(text, min, max, default, callback)
			min = min or 0; max = max or 1; default = default or min
			local holder = new("Frame", {Parent = Frame, Size = UDim2.new(0.9,0,0,48), Position = UDim2.new(0.05,0,0.05 + (#Frame:GetChildren() * 0)), BackgroundTransparency = 1})
			local label = new("TextLabel", {Parent = holder, Size = UDim2.new(0.3,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextColor3 = window.Palette.Text, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left})
			local track = new("Frame", {Parent = holder, Size = UDim2.new(0.6,0,0.2,0), Position = UDim2.new(0.35,0,0.4,0), BackgroundColor3 = window.Palette.Button, BorderSizePixel = 0})
			new("UICorner", {Parent = track, CornerRadius = UDim.new(0,6)})
			local fill = new("Frame", {Parent = track, Size = UDim2.new( (default-min)/(max-min), 0, 1, 0), Position = UDim2.new(0,0,0,0), BackgroundColor3 = window.Palette.ButtonHover, BorderSizePixel = 0})
			new("UICorner", {Parent = fill, CornerRadius = UDim.new(0,6)})
			local dragging = false
			track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
			track.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
			UserInputService.InputChanged:Connect(function(i)
				if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
					local mouse = UserInputService:GetMouseLocation()
					local rel = clamp((mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
					fill.Size = UDim2.new(rel,0,1,0)
					local value = min + (rel * (max-min))
					pcall(callback, value)
				end
			end)
			return {Track = track, Fill = fill}
		end

		function tab:CreateDropdown(text, items, callback)
			local holder = new("Frame", {Parent = Frame, Size = UDim2.new(0.6,0,0,36), Position = UDim2.new(0.05,0,0.05 + (#Frame:GetChildren() * 0)), BackgroundTransparency = 1})
			local label = new("TextLabel", {Parent = holder, Size = UDim2.new(0.45,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextColor3 = window.Palette.Text, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left})
			local btn = new("TextButton", {Parent = holder, Size = UDim2.new(0.5,0,1,0), Position = UDim2.new(0.45,0,0,0), BackgroundColor3 = window.Palette.Button, BorderSizePixel = 0, Text = "Select"})
			new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})
			local list = new("Frame", {Parent = holder, Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,1,4), BackgroundColor3 = window.Palette.Content, BorderSizePixel = 0, ClipsDescendants = true, Visible = false})
			local layout = new("UIListLayout", {Parent = list, SortOrder = Enum.SortOrder.LayoutOrder})
			for i, it in ipairs(items or {}) do
				local itb = new("TextButton", {Parent = list, Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1, Text = it, TextColor3 = window.Palette.Text, Font = Enum.Font.Gotham, TextSize = 14})
				itb.MouseButton1Click:Connect(function()
					btn.Text = it
					list.Visible = false
					pcall(callback, it)
				end)
			end
			btn.MouseButton1Click:Connect(function()
				list.Visible = not list.Visible
			end)
			return btn
		end

		function tab:SetIcon(newIcon)
			Icon.Image = newIcon
		end

		function tab:Notify(state)
			Dot.Visible = not not state
		end

		return tab
	end

	-- Hotkey toggle
	if Hotkey then
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.KeyCode == Hotkey then
				window:SetVisible(not window.Visible)
			end
		end)
	end

	-- API methods on window
	function window:SetTheme(t)
		local palette = type(t) == "string" and THEMES[t] or t
		if not palette then return end
		window.Palette = palette
		-- apply colours quickly
		Container.BackgroundColor3 = palette.Container
		TopBar.BackgroundColor3 = palette.TopBar
		SideBar.BackgroundColor3 = palette.Sidebar
		ContentFrame.BackgroundColor3 = palette.Content
		Title.TextColor3 = palette.Text
		-- update buttons, labels etc
		for _, nm in ipairs(window.TabOrder) do
			local t = window.Tabs[nm]
			if t then
				t.Button.BackgroundColor3 = palette.Button
				t.Label.TextColor3 = palette.Text
				t.Button.UIStroke.Color = palette.Accent
			end
		end
	end

	function window:Destroy()
		setGlobalBlur(false)
		ScreenGui:Destroy()
	end

	-- Return the window object
	return window
end

-- Example: if the module is loaded and you want a quick test, we provide an example that runs only if a special flag is set
-- (commented out by default)
--[[
local example = Hyper:CreateWindow({Title = "My Demo", Theme = "BluishGray", UseGlobalBlur = true, Hotkey = Enum.KeyCode.RightShift, StartVisible = true})
local home = example:CreateTab({Name = "Home", Icon = "rbxassetid://98856649840601"})
local settings = example:CreateTab({Name = "Settings", Icon = "rbxassetid://98856649840601"})
local about = example:CreateTab({Name = "About", Icon = "rbxassetid://98856649840601"})
home:CreateButton("Click me", function() print("clicked") end)
settings:CreateToggle("Enable feature", false, function(v) print("toggle", v) end)
settings:CreateSlider("Volume", 0, 100, 50, function(v) print("vol", v) end)
local dd = about:CreateDropdown("Choice", {"One","Two","Three"}, function(v) print("picked", v) end)
about:Notify(true)
--]]

return Hyper
