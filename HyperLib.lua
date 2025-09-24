-- HyperLib.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local HyperLib = {}
HyperLib.__index = HyperLib

local GUI_NAME = "HyperLibUI"
local TAB_ASSET_ID = "rbxassetid://9885664984" -- Fixed asset ID

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

-- Add global blur effect behind the UI
local blur = Instance.new("BlurEffect")
blur.Size = 20
blur.Parent = Lighting

function HyperLib.new(title)
	local self = setmetatable({}, HyperLib)

	-- Main container with proper rounded corners
	local Container = Instance.new("Frame")
	Container.Name = "Container"
	Container.Size = UDim2.new(0, 600, 0, 400)
	Container.Position = UDim2.new(0.5, -300, 0.5, -200)
	Container.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
	Container.BackgroundTransparency = 0.05 -- Reduced transparency for better visibility
	Container.BorderSizePixel = 0
	Container.ClipsDescendants = true
	Container.Parent = ScreenGui

	-- Rounded corners
	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 16)
	UICorner.Parent = Container

	self.Container = Container

	-- Top bar (draggable)
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0.12, 0)
	TopBar.Position = UDim2.new(0, 0, 0, 0)
	TopBar.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	TopBar.BackgroundTransparency = 0.1 -- Reduced transparency
	TopBar.BorderSizePixel = 0
	TopBar.Parent = Container

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.new(1, -20, 1, 0)
	TitleLabel.Position = UDim2.new(0, 10, 0, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Text = title or "HyperLib"
	TitleLabel.TextScaled = true
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.TextColor3 = Color3.fromRGB(230, 230, 245)
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Parent = TopBar

	self.TopBar = TopBar

	-- Sidebar
	local normalWidth, expandedWidth = 0.08, 0.22
	local SideBar = Instance.new("Frame")
	SideBar.Name = "SideBar"
	SideBar.Size = UDim2.new(normalWidth, 0, 0.88, 0)
	SideBar.Position = UDim2.new(0, 0, 0.12, 0)
	SideBar.BackgroundColor3 = Color3.fromRGB(65, 65, 90)
	SideBar.BackgroundTransparency = 0.1 -- Reduced transparency
	SideBar.BorderSizePixel = 0
	SideBar.Parent = Container

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Padding = UDim.new(0, 6)
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Parent = SideBar

	self.SideBar = SideBar
	self.Tabs = {}

	-- Content frame
	local ContentFrame = Instance.new("Frame")
	ContentFrame.Name = "ContentFrame"
	ContentFrame.Position = UDim2.new(normalWidth, 0, 0.12, 0)
	ContentFrame.Size = UDim2.new(1 - normalWidth, 0, 0.88, 0)
	ContentFrame.BackgroundColor3 = Color3.fromRGB(75, 75, 100)
	ContentFrame.BackgroundTransparency = 0.1 -- Reduced transparency
	ContentFrame.BorderSizePixel = 0
	ContentFrame.ClipsDescendants = true
	ContentFrame.Parent = Container
	
	-- Add rounded corners to content frame
	local ContentCorner = Instance.new("UICorner")
	ContentCorner.CornerRadius = UDim.new(0, 8)
	ContentCorner.Parent = ContentFrame

	self.ContentFrame = ContentFrame

	-- Sidebar hover expand/collapse
	local hoverTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	SideBar.MouseEnter:Connect(function()
		TweenService:Create(SideBar, hoverTween, {Size = UDim2.new(expandedWidth, 0, 0.88, 0)}):Play()
		TweenService:Create(ContentFrame, hoverTween, {
			Position = UDim2.new(expandedWidth, 0, 0.12, 0),
			Size = UDim2.new(1 - expandedWidth, 0, 0.88, 0)
		}):Play()
		for _, tab in pairs(self.Tabs) do
			tab.Label.Visible = true
		end
	end)
	SideBar.MouseLeave:Connect(function()
		TweenService:Create(SideBar, hoverTween, {Size = UDim2.new(normalWidth, 0, 0.88, 0)}):Play()
		TweenService:Create(ContentFrame, hoverTween, {
			Position = UDim2.new(normalWidth, 0, 0.12, 0),
			Size = UDim2.new(1 - normalWidth, 0, 0.88, 0)
		}):Play()
		for _, tab in pairs(self.Tabs) do
			tab.Label.Visible = false
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

	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, -8, 0, 40)
	Button.Position = UDim2.new(0, 4, 0, 4 + (#self.Tabs * 46))
	Button.BackgroundColor3 = Color3.fromRGB(85, 85, 115)
	Button.BackgroundTransparency = 0.1
	Button.AutoButtonColor = true
	Button.Text = ""
	Button.Parent = self.SideBar

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 8)
	UICorner.Parent = Button

	-- Icon
	local Icon = Instance.new("ImageLabel")
	Icon.Size = UDim2.new(0, 28, 0, 28)
	Icon.Position = UDim2.new(0, 6, 0.5, -14)
	Icon.BackgroundTransparency = 1
	Icon.Image = TAB_ASSET_ID
	Icon.Parent = Button

	-- Label
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -40, 1, 0)
	Label.Position = UDim2.new(0, 40, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = name
	Label.TextColor3 = Color3.fromRGB(240, 240, 255)
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 16
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Visible = false
	Label.Parent = Button

	tab.Button = Button
	tab.Label = Label

	-- Content
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, 0, 1, 0)
	Frame.BackgroundTransparency = 1
	Frame.Visible = false
	Frame.Parent = self.ContentFrame

	-- Add some visible content to the tab
	local TabTitle = Instance.new("TextLabel")
	TabTitle.Size = UDim2.new(1, 0, 0.1, 0)
	TabTitle.Position = UDim2.new(0, 0, 0, 10)
	TabTitle.BackgroundTransparency = 1
	TabTitle.Text = name .. " Tab"
	TabTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	TabTitle.Font = Enum.Font.GothamBold
	TabTitle.TextSize = 24
	TabTitle.TextXAlignment = Enum.TextXAlignment.Center
	TabTitle.Parent = Frame

	tab.Frame = Frame
	self.Tabs[name] = tab

	-- Button click behavior
	Button.MouseButton1Click:Connect(function()
		for _, t in pairs(self.Tabs) do
			t.Frame.Visible = false
		end
		Frame.Visible = true
	end)

	-- Make first tab active by default
	if #self.Tabs == 1 then
		Frame.Visible = true
	end

	return Frame
end

-- Example usage that actually works:
local function exampleUsage()
	local lib = HyperLib.new("My HyperLib GUI")
	
	-- Add tabs with proper content
	local homeTab = lib:AddTab("Home")
	local settingsTab = lib:AddTab("Settings")
	local aboutTab = lib:AddTab("About")
	
	-- Add some content to home tab
	local homeLabel = Instance.new("TextLabel")
	homeLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
	homeLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
	homeLabel.BackgroundTransparency = 1
	homeLabel.Text = "Welcome to HyperLib!"
	homeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	homeLabel.Font = Enum.Font.Gotham
	homeLabel.TextSize = 20
	homeLabel.TextXAlignment = Enum.TextXAlignment.Center
	homeLabel.Parent = homeTab
	
	-- Add content to settings tab
	local settingsLabel = Instance.new("TextLabel")
	settingsLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
	settingsLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
	settingsLabel.BackgroundTransparency = 1
	settingsLabel.Text = "Settings Content Here"
	settingsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	settingsLabel.Font = Enum.Font.Gotham
	settingsLabel.TextSize = 20
	settingsLabel.TextXAlignment = Enum.TextXAlignment.Center
	settingsLabel.Parent = settingsTab
end

-- Run the example
exampleUsage()

return HyperLib
