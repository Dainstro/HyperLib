-- HyperLib_fixed.lua
-- Fixed + improved version of your GUI library per your requests

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local HyperLib = {}
HyperLib.__index = HyperLib

local GUI_NAME = "HyperLibUI"
local TAB_ASSET_ID = "rbxassetid://98856649840601" -- corrected asset id

-- Remove old GUI
if PlayerGui:FindFirstChild(GUI_NAME) then
	PlayerGui[GUI_NAME]:Destroy()
end

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- Instead of blurring the entire screen (which BlurEffect does globally),
-- create a semi-transparent backdrop frame behind the GUI to simulate focus
local Backdrop = Instance.new("Frame")
Backdrop.Name = "Backdrop"
Backdrop.Size = UDim2.new(1, 0, 1, 0)
Backdrop.Position = UDim2.new(0, 0, 0, 0)
Backdrop.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Backdrop.BackgroundTransparency = 0.6 -- darker overlay behind GUI (no global blur)
Backdrop.BorderSizePixel = 0
Backdrop.Parent = ScreenGui

-- Styling palette (clean centralized colors)
local Palette = {
	Container = Color3.fromRGB(34, 23, 60), -- deep indigo
	TopBar = Color3.fromRGB(26, 20, 40),
	Sidebar = Color3.fromRGB(28, 16, 45),
	Content = Color3.fromRGB(41, 30, 70),
	Button = Color3.fromRGB(93, 36, 140), -- pretty purple
	ButtonHover = Color3.fromRGB(113, 56, 170),
	Text = Color3.fromRGB(235, 235, 245),
	Accent = Color3.fromRGB(180, 120, 255),
}

function HyperLib.new(title)
	local self = setmetatable({}, HyperLib)

	-- Main container (rounded outer corners only)
	local Container = Instance.new("Frame")
	Container.Name = "Container"
	-- Make the GUI roughly 40% of the screen
	Container.Size = UDim2.new(0.4, 0, 0.4, 0)
	Container.Position = UDim2.new(0.5, -(Container.Size.X.Offset / 2), 0.5, -(Container.Size.Y.Offset / 2))
	Container.AnchorPoint = Vector2.new(0.5, 0.5)
	Container.BackgroundColor3 = Palette.Container
	Container.BorderSizePixel = 0
	Container.ClipsDescendants = true
	Container.Parent = ScreenGui

	-- Outer rounded corners (only outer)
	local OuterCorner = Instance.new("UICorner")
	OuterCorner.CornerRadius = UDim.new(0, 16)
	OuterCorner.Parent = Container

	self.Container = Container

	-- Top bar (no inner rounded corners)
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0.12, 0)
	TopBar.Position = UDim2.new(0, 0, 0, 0)
	TopBar.BackgroundColor3 = Palette.TopBar
	TopBar.BorderSizePixel = 0
	TopBar.Parent = Container

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.new(1, -20, 1, 0)
	TitleLabel.Position = UDim2.new(0, 10, 0, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Text = title or "HyperLib"
	TitleLabel.TextScaled = true
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.TextColor3 = Palette.Text
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Parent = TopBar

	self.TopBar = TopBar

	-- Sidebar (no inner rounded corners)
	local normalWidth, expandedWidth = 0.08, 0.22
	local SideBar = Instance.new("Frame")
	SideBar.Name = "SideBar"
	SideBar.Size = UDim2.new(normalWidth, 0, 0.88, 0)
	SideBar.Position = UDim2.new(0, 0, 0.12, 0)
	SideBar.BackgroundColor3 = Palette.Sidebar
	SideBar.BorderSizePixel = 0
	SideBar.Parent = Container

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Padding = UDim.new(0, 6)
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Parent = SideBar

	self.SideBar = SideBar
	self.Tabs = {}
	self.TabOrder = {} -- stable ordered array for tabs

	-- Content frame (no inner rounded corners as requested)
	local ContentFrame = Instance.new("Frame")
	ContentFrame.Name = "ContentFrame"
	ContentFrame.Position = UDim2.new(normalWidth, 0, 0.12, 0)
	ContentFrame.Size = UDim2.new(1 - normalWidth, 0, 0.88, 0)
	ContentFrame.BackgroundColor3 = Palette.Content
	ContentFrame.BorderSizePixel = 0
	ContentFrame.ClipsDescendants = true
	ContentFrame.Parent = Container

	self.ContentFrame = ContentFrame

	-- Sidebar hover expand/collapse — improved behaviour
	local hoverTweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	SideBar.MouseEnter:Connect(function()
		-- expand sidebar
		TweenService:Create(SideBar, hoverTweenInfo, {Size = UDim2.new(expandedWidth, 0, 0.88, 0)}):Play()
		TweenService:Create(ContentFrame, hoverTweenInfo, {
			Position = UDim2.new(expandedWidth, 0, 0.12, 0),
			Size = UDim2.new(1 - expandedWidth, 0, 0.88, 0)
		}):Play()
		
		-- move buttons to left and show labels
		for i, name in ipairs(self.TabOrder) do
			local tab = self.Tabs[name]
			if tab then
				-- left align buttons
				tab.Button.AnchorPoint = Vector2.new(0, 0)
				tab.Button.Position = UDim2.new(0, 6, 0, 6 + ((i-1) * 46))
				-- show label
				tab.Label.Visible = true
				-- animate hover color
				TweenService:Create(tab.Button, hoverTweenInfo, {BackgroundColor3 = Palette.ButtonHover}):Play()
			end
		end
	end)

	SideBar.MouseLeave:Connect(function()
		-- collapse sidebar
		TweenService:Create(SideBar, hoverTweenInfo, {Size = UDim2.new(normalWidth, 0, 0.88, 0)}):Play()
		TweenService:Create(ContentFrame, hoverTweenInfo, {
			Position = UDim2.new(normalWidth, 0, 0.12, 0),
			Size = UDim2.new(1 - normalWidth, 0, 0.88, 0)
		}):Play()
		
		-- center buttons and hide labels
		for i, name in ipairs(self.TabOrder) do
			local tab = self.Tabs[name]
			if tab then
				-- center buttons inside collapsed bar
				tab.Button.AnchorPoint = Vector2.new(0.5, 0)
				local yOff = 6 + ((i-1) * 46)
				tab.Button.Position = UDim2.new(0.5, 0, 0, yOff)
				-- hide label
				tab.Label.Visible = false
				-- restore normal color
				TweenService:Create(tab.Button, hoverTweenInfo, {BackgroundColor3 = Palette.Button}):Play()
			end
		end
	end)

	-- Dragging
	local dragging, dragStart, startPos
	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = Container.Position
			local moveCon, releaseCon
			moveCon = UserInputService.InputChanged:Connect(function(i)
				if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
					local delta = i.Position - dragStart
					Container.Position = UDim2.new(
						startPos.X.Scale, startPos.X.Offset + delta.X,
						startPos.Y.Scale, startPos.Y.Offset + delta.Y
					)
				end
			end)
			releaseCon = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					moveCon:Disconnect()
					releaseCon:Disconnect()
				end
			end)
		end
	end)

	return self
end

function HyperLib:AddTab(name)
	local tab = {}

	-- Create the button container (we'll center it in collapsed state)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, -8, 0, 40) -- width will be constrained by sidebar
	Button.BackgroundColor3 = Palette.Button
	Button.BackgroundTransparency = 0
	Button.AutoButtonColor = true
	Button.Text = ""
	Button.BorderSizePixel = 0
	Button.Parent = self.SideBar

	-- Rounded corners on the individual button are okay
	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 8)
	UICorner.Parent = Button

	-- Outline / stroke for buttons
	local Stroke = Instance.new("UIStroke")
	Stroke.Thickness = 2
	Stroke.Color = Palette.Accent
	Stroke.Transparency = 0.4
	Stroke.Parent = Button

	-- Icon (centered inside button)
	local Icon = Instance.new("ImageLabel")
	Icon.Size = UDim2.new(0, 28, 0, 28)
	Icon.Position = UDim2.new(0, 8, 0.5, -14)
	Icon.BackgroundTransparency = 1
	Icon.Image = TAB_ASSET_ID
	Icon.Parent = Button

	-- Label placed to the right of the icon — hidden by default
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -44, 1, 0)
	Label.Position = UDim2.new(0, 44, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = name
	Label.TextColor3 = Palette.Text
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 16
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Visible = false
	Label.Parent = Button

	-- Content frame for tab
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, 0, 1, 0)
	Frame.BackgroundTransparency = 1
	Frame.Visible = false
	Frame.Parent = self.ContentFrame

	-- Add some visible content to the tab area (title)
	local TabTitle = Instance.new("TextLabel")
	TabTitle.Size = UDim2.new(1, 0, 0.1, 0)
	TabTitle.Position = UDim2.new(0, 0, 0, 10)
	TabTitle.BackgroundTransparency = 1
	TabTitle.Text = name .. " Tab"
	TabTitle.TextColor3 = Palette.Text
	TabTitle.Font = Enum.Font.GothamBold
	TabTitle.TextSize = 24
	TabTitle.TextXAlignment = Enum.TextXAlignment.Center
	TabTitle.Parent = Frame

	-- Store tab data
	tab.Button = Button
	tab.Label = Label
	tab.Frame = Frame
	self.Tabs[name] = tab
	table.insert(self.TabOrder, name)

	-- Initially center the button inside the collapsed sidebar
	local index = #self.TabOrder
	Button.AnchorPoint = Vector2.new(0.5, 0)
	Button.Position = UDim2.new(0.5, 0, 0, 6 + ((index-1) * 46))

	-- Button click behaviour: switch visible content
	Button.MouseButton1Click:Connect(function()
		for _, nm in ipairs(self.TabOrder) do
			local t = self.Tabs[nm]
			if t then t.Frame.Visible = false end
		end
		Frame.Visible = true
	end)

	-- Make first tab active by default
	if #self.TabOrder == 1 then
		Frame.Visible = true
	end

	return Frame
end

-- Example usage (full-featured) to test everything
local function exampleUsage()
	local lib = HyperLib.new("My HyperLib GUI")

	local homeTab = lib:AddTab("Home")
	local settingsTab = lib:AddTab("Settings")
	local aboutTab = lib:AddTab("About")

	-- Home content
	local homeLabel = Instance.new("TextLabel")
	homeLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
	homeLabel.Position = UDim2.new(0.1, 0, 0.25, 0)
	homeLabel.BackgroundTransparency = 1
	homeLabel.Text = "Welcome to HyperLib!"
	homeLabel.TextColor3 = Palette.Text
	homeLabel.Font = Enum.Font.Gotham
	homeLabel.TextSize = 20
	homeLabel.TextXAlignment = Enum.TextXAlignment.Center
	homeLabel.Parent = homeTab

	-- Settings content
	local settingsLabel = Instance.new("TextLabel")
	settingsLabel.Size = UDim2.new(0.9, 0, 0.2, 0)
	settingsLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
	settingsLabel.BackgroundTransparency = 1
	settingsLabel.Text = "Settings Content Here"
	settingsLabel.TextColor3 = Palette.Text
	settingsLabel.Font = Enum.Font.Gotham
	settingsLabel.TextSize = 18
	settingsLabel.TextXAlignment = Enum.TextXAlignment.Left
	settingsLabel.Parent = settingsTab

	-- About content
	local aboutLabel = Instance.new("TextLabel")
	aboutLabel.Size = UDim2.new(0.9, 0, 0.2, 0)
	aboutLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
	aboutLabel.BackgroundTransparency = 1
	aboutLabel.Text = "About: Improved version with fixed tab alignment, new palette, and simulated backdrop (no global blur)."
	aboutLabel.TextColor3 = Palette.Text
	aboutLabel.Font = Enum.Font.Gotham
	aboutLabel.TextSize = 16
	aboutLabel.TextXAlignment = Enum.TextXAlignment.Left
	aboutLabel.Parent = aboutTab
end

-- Run example
exampleUsage()

return HyperLib
