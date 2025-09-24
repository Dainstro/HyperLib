-- HyperLib.lua
-- Lightweight, responsive GUI library with tab system

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local HyperLib = {}
HyperLib.__index = HyperLib

local GUI_NAME = "HyperLibUI"

-- Destroy existing
if PlayerGui:FindFirstChild(GUI_NAME) then
	PlayerGui[GUI_NAME]:Destroy()
end

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- Library constructor
function HyperLib.new(title)
	local self = setmetatable({}, HyperLib)

	-- Main Frame
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70) -- Gray with faint blue-purple tint
	MainFrame.BackgroundTransparency = 0
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	MainFrame.Parent = ScreenGui

	-- External corners fixed
	local UICornerMain = Instance.new("UICorner")
	UICornerMain.CornerRadius = UDim.new(0, 10)
	UICornerMain.Parent = MainFrame

	-- Aspect ratio
	local AspectRatio = Instance.new("UIAspectRatioConstraint")
	AspectRatio.AspectRatio = 3.5 / 2
	AspectRatio.Parent = MainFrame

	-- TopBar
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	TopBar.BackgroundTransparency = 0.2
	TopBar.Size = UDim2.new(1, 0, 0.12, 0)
	TopBar.Parent = MainFrame

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.new(1, -20, 1, 0)
	TitleLabel.Position = UDim2.new(0, 10, 0, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
	TitleLabel.TextScaled = true
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.Text = title or "HyperLib"
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Parent = TopBar

	-- SidePanel
	local SidePanel = Instance.new("Frame")
	SidePanel.Name = "SidePanel"
	SidePanel.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	SidePanel.BackgroundTransparency = 0.2
	SidePanel.Size = UDim2.new(0.18, 0, 0.88, 0)
	SidePanel.Position = UDim2.new(0, 0, 0.12, 0)
	SidePanel.Parent = MainFrame

	-- TabHolder (buttons go here)
	local TabHolder = Instance.new("UIListLayout")
	TabHolder.FillDirection = Enum.FillDirection.Vertical
	TabHolder.SortOrder = Enum.SortOrder.LayoutOrder
	TabHolder.Padding = UDim.new(0, 5)
	TabHolder.Parent = SidePanel

	-- Content area
	local ContentFrame = Instance.new("Frame")
	ContentFrame.Name = "ContentFrame"
	ContentFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
	ContentFrame.BackgroundTransparency = 0.05
	ContentFrame.Position = UDim2.new(0.18, 0, 0.12, 0)
	ContentFrame.Size = UDim2.new(0.82, 0, 0.88, 0)
	ContentFrame.ClipsDescendants = true
	ContentFrame.Parent = MainFrame

	-- Internal state
	self.MainFrame = MainFrame
	self.TopBar = TopBar
	self.SidePanel = SidePanel
	self.ContentFrame = ContentFrame
	self.Tabs = {}

	-- Dragging logic
	local dragging, dragStartPos, startPos
	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStartPos = input.Position
			startPos = MainFrame.Position

			local moveCon, releaseCon
			moveCon = UserInputService.InputChanged:Connect(function(inputChanged)
				if dragging and inputChanged.UserInputType == Enum.UserInputType.MouseMovement then
					local delta = inputChanged.Position - dragStartPos
					MainFrame.Position = UDim2.new(
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

	-- Resizing
	local function updateSize()
		local viewport = workspace.CurrentCamera.ViewportSize
		local base = math.min(viewport.X, viewport.Y) * 0.45
		local xSize = base * (3.5 / 2)
		local ySize = base
		MainFrame.Size = UDim2.new(0, xSize, 0, ySize)
		MainFrame.Position = UDim2.new(0.5, -xSize/2, 0.5, -ySize/2)
	end
	updateSize()
	RunService:GetPropertyChangedSignal("ViewportSize"):Connect(updateSize)

	return self
end

-- AddTab
function HyperLib:AddTab(name)
	local button = Instance.new("TextButton")
	button.Text = name
	button.Size = UDim2.new(1, -10, 0, 30)
	button.Position = UDim2.new(0, 5, 0, 0)
	button.BackgroundColor3 = Color3.fromRGB(75, 75, 90)
	button.TextColor3 = Color3.fromRGB(230, 230, 240)
	button.Font = Enum.Font.Gotham
	button.TextSize = 16
	button.Parent = self.SidePanel

	local tabFrame = Instance.new("Frame")
	tabFrame.Name = name .. "Content"
	tabFrame.Size = UDim2.new(1, 0, 1, 0)
	tabFrame.BackgroundTransparency = 1
	tabFrame.Visible = false
	tabFrame.Parent = self.ContentFrame

	self.Tabs[name] = tabFrame

	button.MouseButton1Click:Connect(function()
		for _, f in pairs(self.ContentFrame:GetChildren()) do
			if f:IsA("Frame") then f.Visible = false end
		end
		tabFrame.Visible = true
	end)

	return tabFrame
end

return HyperLib
