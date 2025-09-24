-- HyperLib.lua
-- Clean + efficient Roblox UI library with expanding sidebar + tab system

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

-- Clear any old copies
if PlayerGui:FindFirstChild(GUI_NAME) then
	PlayerGui[GUI_NAME]:Destroy()
end

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Constructor
function HyperLib.new(title)
	local self = setmetatable({}, HyperLib)

	-- Main frame
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 70) -- gray w/ dark blue-purple tint
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	MainFrame.Parent = ScreenGui

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 14)
	UICorner.Parent = MainFrame

	-- Top bar
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	TopBar.Size = UDim2.new(1, 0, 0.12, 0)
	TopBar.Parent = MainFrame

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.new(1, -20, 1, 0)
	TitleLabel.Position = UDim2.new(0, 10, 0, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.TextColor3 = Color3.fromRGB(230, 230, 245)
	TitleLabel.TextScaled = true
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Text = title or "HyperLib"
	TitleLabel.Parent = TopBar

	-- Sidebar
	local normalWidth, expandedWidth = 0.1, 0.22
	local SideBar = Instance.new("Frame")
	SideBar.Name = "SideBar"
	SideBar.BackgroundColor3 = Color3.fromRGB(65, 65, 90)
	SideBar.Size = UDim2.new(normalWidth, 0, 0.88, 0)
	SideBar.Position = UDim2.new(0, 0, 0.12, 0)
	SideBar.Parent = MainFrame

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Padding = UDim.new(0, 4)
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Parent = SideBar

	-- Content area
	local ContentFrame = Instance.new("Frame")
	ContentFrame.Name = "ContentFrame"
	ContentFrame.BackgroundColor3 = Color3.fromRGB(75, 75, 100)
	ContentFrame.Position = UDim2.new(normalWidth, 0, 0.12, 0)
	ContentFrame.Size = UDim2.new(1 - normalWidth, 0, 0.88, 0)
	ContentFrame.ClipsDescendants = true
	ContentFrame.Parent = MainFrame

	-- Hover expand
	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	SideBar.MouseEnter:Connect(function()
		TweenService:Create(SideBar, tweenInfo, {Size = UDim2.new(expandedWidth, 0, 0.88, 0)}):Play()
		TweenService:Create(ContentFrame, tweenInfo, {
			Position = UDim2.new(expandedWidth, 0, 0.12, 0),
			Size = UDim2.new(1 - expandedWidth, 0, 0.88, 0)
		}):Play()
	end)
	SideBar.MouseLeave:Connect(function()
		TweenService:Create(SideBar, tweenInfo, {Size = UDim2.new(normalWidth, 0, 0.88, 0)}):Play()
		TweenService:Create(ContentFrame, tweenInfo, {
			Position = UDim2.new(normalWidth, 0, 0.12, 0),
			Size = UDim2.new(1 - normalWidth, 0, 0.88, 0)
		}):Play()
	end)

	-- Dragging
	local dragging, dragStart, startPos
	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
			local moveCon, releaseCon
			moveCon = UserInputService.InputChanged:Connect(function(i)
				if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
					local delta = i.Position - dragStart
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

	-- Save refs
	self.MainFrame = MainFrame
	self.SideBar = SideBar
	self.ContentFrame = ContentFrame
	self.Tabs = {}
	return self
end

function HyperLib:AddTab(name)
	-- Sidebar button
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, -8, 0, 36)
	Button.Position = UDim2.new(0, 4, 0, 0)
	Button.BackgroundColor3 = Color3.fromRGB(85, 85, 115)
	Button.TextColor3 = Color3.fromRGB(240, 240, 255)
	Button.Font = Enum.Font.Gotham
	Button.TextSize = 16
	Button.Text = name
	Button.AutoButtonColor = true
	Button.Parent = self.SideBar

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 8)
	UICorner.Parent = Button

	-- Content frame
	local TabFrame = Instance.new("Frame")
	TabFrame.Name = name .. "Content"
	TabFrame.Size = UDim2.new(1, 0, 1, 0)
	TabFrame.BackgroundTransparency = 1
	TabFrame.Visible = false
	TabFrame.Parent = self.ContentFrame

	-- Default asset image
	local Img = Instance.new("ImageLabel")
	Img.BackgroundTransparency = 1
	Img.Size = UDim2.new(1, 0, 1, 0)
	Img.Image = TAB_ASSET_ID
	Img.Parent = TabFrame

	-- Button behavior
	Button.MouseButton1Click:Connect(function()
		for _, f in ipairs(self.ContentFrame:GetChildren()) do
			if f:IsA("Frame") then f.Visible = false end
		end
		TabFrame.Visible = true
	end)

	-- Store ref
	self.Tabs[name] = TabFrame
	return TabFrame
end

return HyperLib
