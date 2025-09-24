-- HyperLib.lua
-- Ground-up responsive UI library

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local HyperLib = {}
HyperLib.__index = HyperLib

local GUI_NAME = "HyperLibUI"
local TAB_ASSET_ID = "rbxassetid://98856649840601"

-- Remove old GUI if exists
if PlayerGui:FindFirstChild(GUI_NAME) then
	PlayerGui[GUI_NAME]:Destroy()
end

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- Constructor
function HyperLib.new(title)
	local self = setmetatable({}, HyperLib)

	-- Container for true rounded corners
	local Container = Instance.new("Frame")
	Container.Name = "Container"
	Container.Size = UDim2.new(0, 600, 0, 400)
	Container.Position = UDim2.new(0.5, -300, 0.5, -200)
	Container.BackgroundColor3 = Color3.fromRGB(55, 55, 70) -- Gray + dark blue/purple tint
	Container.BorderSizePixel = 0
	Container.ClipsDescendants = true
	Container.Parent = ScreenGui

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 16)
	UICorner.Parent = Container

	self.Container = Container

	-- Top bar
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0.12, 0)
	TopBar.Position = UDim2.new(0, 0, 0, 0)
	TopBar.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
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
	SideBar.Parent = Container

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Padding = UDim.new(0, 6)
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Parent = SideBar

	self.SideBar = SideBar
	self.Tabs = {}

	-- Content area
	local ContentFrame = Instance.new("Frame")
	ContentFrame.Name = "ContentFrame"
	ContentFrame.Position = UDim2.new(normalWidth, 0, 0.12, 0)
	ContentFrame.Size = UDim2.new(1 - normalWidth, 0, 0.88, 0)
	ContentFrame.BackgroundColor3 = Color3.fromRGB(75, 75, 100)
	ContentFrame.ClipsDescendants = true
	ContentFrame.Parent = Container
	self.ContentFrame = ContentFrame

	-- Sidebar hover expand/collapse
	local hoverTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	SideBar.MouseEnter:Connect(function()
		TweenService:Create(SideBar, hoverTween, {Size = UDim2.new(expandedWidth, 0, 0.88, 0)}):Play()
		TweenService:Create(ContentFrame, hoverTween, {
			Position = UDim2.new(expandedWidth, 0, 0.12, 0),
			Size = UDim2.new(1 - expandedWidth, 0, 0.88, 0)
		}):Play()
		-- Show tab labels
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
		-- Hide tab labels
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

	self.Container = Container
	return self
end

function HyperLib:AddTab(name)
	local tab = {}
	tab.Button = Instance.new("TextButton")
	tab.Button.Size = UDim2.new(1, -8, 0, 40)
	tab.Button.BackgroundColor3 = Color3.fromRGB(85, 85, 115)
	tab.Button.AutoButtonColor = true
	tab.Button.Parent = self.SideBar

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 8)
	UICorner.Parent = tab.Button

	-- Icon
	local Icon = Instance.new("ImageLabel")
	Icon.Size = UDim2.new(0, 28, 0, 28)
	Icon.Position = UDim2.new(0, 6, 0.5, -14)
	Icon.BackgroundTransparency = 1
	Icon.Image = TAB_ASSET_ID
	Icon.Parent = tab.Button

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
	Label.Parent = tab.Button
	tab.Label = Label

	-- Content frame
	local TabFrame = Instance.new("Frame")
	TabFrame.Size = UDim2.new(1, 0, 1, 0)
	TabFrame.BackgroundTransparency = 1
	TabFrame.Visible = false
	TabFrame.Parent = self.ContentFrame

	local Img = Instance.new("ImageLabel")
	Img.Size = UDim2.new(1, 0, 1, 0)
	Img.BackgroundTransparency = 1
	Img.Image = TAB_ASSET_ID
	Img.Parent = TabFrame

	tab.Frame = TabFrame
	self.Tabs[name] = tab

	-- Button click
	tab.Button.MouseButton1Click:Connect(function()
		for _, t in pairs(self.Tabs) do
			t.Frame.Visible = false
		end
		tab.Frame.Visible = true
	end)

	return tab.Frame
end

return HyperLib
