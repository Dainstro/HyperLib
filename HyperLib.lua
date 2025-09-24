-- HyperLib.lua
-- Responsive UI Library with tab system and hover-expanding side panel

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local HyperLib = {}
HyperLib.__index = HyperLib

local GUI_NAME = "HyperLibUI"
local TAB_ASSET_ID = "rbxassetid://98856649840601"

-- Destroy existing
if PlayerGui:FindFirstChild(GUI_NAME) then
	PlayerGui[GUI_NAME]:Destroy()
end

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

function HyperLib.new(title)
	local self = setmetatable({}, HyperLib)

	-- Main frame
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 70) -- Gray w/ stronger blue-purple tint
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	MainFrame.Parent = ScreenGui

	local UICornerMain = Instance.new("UICorner")
	UICornerMain.CornerRadius = UDim.new(0, 12)
	UICornerMain.Parent = MainFrame

	-- Aspect ratio
	local Aspect = Instance.new("UIAspectRatioConstraint")
	Aspect.AspectRatio = 3.5 / 2
	Aspect.Parent = MainFrame

	-- Top bar
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	TopBar.BackgroundTransparency = 0.1
	TopBar.Size = UDim2.new(1, 0, 0.12, 0)
	TopBar.Parent = MainFrame

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.new(1, -20, 1, 0)
	TitleLabel.Position = UDim2.new(0, 10, 0, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.TextColor3 = Color3.fromRGB(230, 230, 245)
	TitleLabel.TextScaled = true
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.Text = title or "HyperLib"
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Parent = TopBar

	-- Side panel (collapsible)
	local normalWidth, expandedWidth = 0.08, 0.2
	local SidePanel = Instance.new("Frame")
	SidePanel.Name = "SidePanel"
	SidePanel.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	SidePanel.BackgroundTransparency = 0.15
	SidePanel.Size = UDim2.new(normalWidth, 0, 0.88, 0)
	SidePanel.Position = UDim2.new(0, 0, 0.12, 0)
	SidePanel.Parent = MainFrame

	local TabLayout = Instance.new("UIListLayout")
	TabLayout.Padding = UDim.new(0, 6)
	TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabLayout.Parent = SidePanel

	-- Content area
	local ContentFrame = Instance.new("Frame")
	ContentFrame.Name = "ContentFrame"
	ContentFrame.BackgroundColor3 = Color3.fromRGB(65, 65, 85)
	ContentFrame.Position = UDim2.new(normalWidth, 0, 0.12, 0)
	ContentFrame.Size = UDim2.new(1 - normalWidth, 0, 0.88, 0)
	ContentFrame.ClipsDescendants = true
	ContentFrame.Parent = MainFrame

	-- Hover expand
	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local isExpanded = false
	SidePanel.MouseEnter:Connect(function()
		if not isExpanded then
			isExpanded = true
			TweenService:Create(SidePanel, tweenInfo, {Size = UDim2.new(expandedWidth, 0, 0.88, 0)}):Play()
			TweenService:Create(ContentFrame, tweenInfo, {
				Position = UDim2.new(expandedWidth, 0, 0.12, 0),
				Size = UDim2.new(1 - expandedWidth, 0, 0.88, 0)
			}):Play()
		end
	end)
	SidePanel.MouseLeave:Connect(function()
		if isExpanded then
			isExpanded = false
			TweenService:Create(SidePanel, tweenInfo, {Size = UDim2.new(normalWidth, 0, 0.88, 0)}):Play()
			TweenService:Create(ContentFrame, tweenInfo, {
				Position = UDim2.new(normalWidth, 0, 0.12, 0),
				Size = UDim2.new(1 - normalWidth, 0, 0.88, 0)
			}):Play()
		end
	end)

	-- Dragging
	local dragging, dragStartPos, startPos
	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStartPos = input.Position
			startPos = MainFrame.Position

			local moveCon, releaseCon
			moveCon = UserInputService.InputChanged:Connect(function(i)
				if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
					local delta = i.Position - dragStartPos
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

	-- Responsive sizing
	local function updateSize()
		local viewport = workspace.CurrentCamera.ViewportSize
		local base = math.min(viewport.X, viewport.Y) * 0.4
		local xSize, ySize = base * (3.5 / 2), base
		MainFrame.Size = UDim2.new(0, xSize, 0, ySize)
		MainFrame.Position = UDim2.new(0.5, -xSize/2, 0.5, -ySize/2)
	end
	updateSize()
	RunService:GetPropertyChangedSignal("ViewportSize"):Connect(updateSize)

	-- Save references
	self.MainFrame = MainFrame
	self.SidePanel = SidePanel
	self.ContentFrame = ContentFrame
	self.Tabs = {}
	return self
end

function HyperLib:AddTab(name)
	local button = Instance.new("TextButton")
	button.Text = name
	button.Size = UDim2.new(1, -10, 0, 32)
	button.Position = UDim2.new(0, 5, 0, 0)
	button.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
	button.TextColor3 = Color3.fromRGB(240, 240, 255)
	button.Font = Enum.Font.Gotham
	button.TextSize = 15
	button.AutoButtonColor = true
	button.Parent = self.SidePanel

	local tabFrame = Instance.new("Frame")
	tabFrame.Name = name .. "Content"
	tabFrame.Size = UDim2.new(1, 0, 1, 0)
	tabFrame.BackgroundTransparency = 1
	tabFrame.Visible = false
	tabFrame.Parent = self.ContentFrame

	-- Default asset
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.new(1, 0, 1, 0)
	img.Image = TAB_ASSET_ID
	img.Parent = tabFrame

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
