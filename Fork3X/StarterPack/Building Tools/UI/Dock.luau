local Root = script:FindFirstAncestorWhichIsA('Tool')
local Vendor = Root:WaitForChild('Vendor')

-- Services
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

-- Libraries
local Roact = require(Vendor:WaitForChild('Roact'))
local Maid = require(Root:WaitForChild("Libraries"):WaitForChild('Maid'))
local Signal = require(Root:WaitForChild("Libraries"):WaitForChild('Signal'))

-- Roact
local new = Roact.createElement
local ToolList = require(script:WaitForChild('ToolList'))
local SelectionPane = require(script:WaitForChild('SelectionPane'))
local AboutPane = require(script:WaitForChild('AboutPane'))

-- Create component
local Dock = Roact.Component:extend(script.Name)

local ToolListSize = Vector2.new(math.huge, 315)
local SelectionPaneSize = Vector2.new(math.huge, 175)

function Dock:init()
	self.Maid = Maid.new()
	
	self.ToolListMaxSize, self.SetToolListMaxSize = Roact.createBinding(ToolListSize)
	self.SelectionPaneMaxSize, self.SetSelectionPaneMaxSize = Roact.createBinding(SelectionPaneSize)
	
	self.Maid.SelectionPaneSignal = Signal.new()
	self.Maid.ToolListSignal = Signal.new()
	
	self.SelectionPaneRef = Roact.createRef()
	
	self.Maid.SelectionPaneSignal:Connect(function(Size)
		if Size.Y == 0 then
			return
		end
		
		SelectionPaneSize = Size
		
		self.SetSelectionPaneMaxSize(Size)
		
		self:UpdateMaxDockSize()
	end)
	
	self.Maid.ToolListSignal:Connect(function(Size)
		if Size.Y == 0 then
			return
		end
		
		ToolListSize = Size
		
		self.SetToolListMaxSize(Size)
		
		self:UpdateMaxDockSize()
	end)
	
	local function CheckUIType()
		local IsSmallScreen = GuiService.ViewportDisplaySize == Enum.DisplaySize.Small 
			or self.props.Core.IsGamepad() and UserInputService.PreferredInput == Enum.PreferredInput.MicroGamepad

		if UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse or self.props.Core.Options.DoNotChangeSelectionPane then
			IsSmallScreen = false
		end
		
		self:setState({
			IsSmallScreen = IsSmallScreen
		})

		self:UpdateMaxDockSize()
	end

	self.Maid.DisplaySizeChanged = GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(CheckUIType)
	self.Maid.PreferredInputChanged = UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(CheckUIType)
	
	CheckUIType()
	
	self:setState({
		IsSelectionPaneOpen = true,
		MaxSize = Vector2.new(70, 559)
	})
end

function Dock:UpdateMaxDockSize()
	local AboutPanePlusPadding = 33
	
	local ToolListYSize = self.ToolListMaxSize:getValue().Y
	
	if ToolListYSize == 0 then
		ToolListYSize = 315
	end
	
	local MaxDockYSize = AboutPanePlusPadding + ToolListYSize
	
	if not self.state.IsSmallScreen then
		MaxDockYSize += self.SelectionPaneMaxSize:getValue().Y + 1
	end 
	
	self:setState({
		MaxSize = Vector2.new(70, MaxDockYSize)
	})
end

function Dock:willUnmount()
	self.Maid:Destroy()
end

function Dock:render()
	local IsSmallScreen = self.state.IsSmallScreen
	
	return Roact.createFragment({
		Dock = new('Frame', {
			Active = true;
			AnchorPoint = Vector2.new(1, 0.5);
			BackgroundTransparency = 1;
			Position = UDim2.new(1, -14, 0.5, 0);
			Size = UDim2.new(0, 70, 0.95, 0);--self.DockSize;--UDim2.new(0, 70, 0, 524);
			ZIndex = 0;
			RBXTAG_Dock = true;
		}, {
			Layout = new('UIListLayout', {
				Padding = UDim.new(0, 1);
				FillDirection = Enum.FillDirection.Vertical;
				HorizontalAlignment = Enum.HorizontalAlignment.Left;
				VerticalAlignment = Enum.VerticalAlignment.Top;
				SortOrder = Enum.SortOrder.LayoutOrder;
			});
			SizeConstraint = new('UISizeConstraint', {
				MaxSize = self.state.MaxSize,
			});
			AboutPane = new(AboutPane, {
				--		LayoutOrder = 0;
				Core = self.props.Core;
			});
			ToolList = new(ToolList, {
				--		LayoutOrder = 1;
				SizeSignal = self.Maid.ToolListSignal,
				Tools = self.props.Tools;
				Core = self.props.Core;
				MaxYSize = self.state.MaxSize,
				IsSmallScreen = IsSmallScreen,
			});
			SmallScreenSelectionPane = IsSmallScreen and new("Folder", {}, {
				SelectionPane = new("Frame", {
					RBXTAG_MobileSelectionPane = true,
				}, {
					MaxSize = not self.state.IsSelectionPaneOpen and new("UISizeConstraint", {
						MaxSize = Vector2.new(0, math.huge)
					}),
					Content = new( "Frame", {
						Visible = self.state.IsSelectionPaneOpen
					}, {
						Top = new( "ImageButton", {
							[Roact.Event.Activated] = function(rbx)
								if rbx then
									local SelectionPane = self.SelectionPaneRef:getValue()

									SelectionPane.CanvasPosition -= Vector2.new(0, 35)
								end
							end,
						}, {
							Icon = new( "ImageLabel" ),
						}),
						FirstDivider = new( "Frame", {
							LayoutOrder = 1,
							RBXTAG_Divider = true,
							RBXTAG_STATE_Horizontal = true,
						}),
						SelectionPane = new(SelectionPane, {
							SizeSignal = self.Maid.SelectionPaneSignal,
							Core = self.props.Core;
							IsSmallScreen = IsSmallScreen,
							SelectionPaneButtons = self.props.SelectionPaneButtons,
							RoactRef = self.SelectionPaneRef
						});
						SecondDivider = new( "Frame", {
							LayoutOrder = 3,
							RBXTAG_Divider = true,
							RBXTAG_STATE_Horizontal = true,
						}),
						Bottom = new( "ImageButton", {
							LayoutOrder = 4,
							[Roact.Event.Activated] = function(rbx)
								if rbx then
									local SelectionPane = self.SelectionPaneRef:getValue()

									SelectionPane.CanvasPosition += Vector2.new(0, 35)
								end
							end,
						}, {
							Icon = new( "ImageLabel"),
						}),
					}),
					Hide = new( "ImageButton", {
						[Roact.Event.Activated] = function(rbx)
							self:setState({
								IsSelectionPaneOpen = not self.state.IsSelectionPaneOpen
							})
						end,
					}, {
						Icon = new( "ImageLabel", {
							RBXTAG_STATE_Hidden = not self.state.IsSelectionPaneOpen
						}),
					}),
					Divider = new( "Frame", {
						Visible = self.state.IsSelectionPaneOpen
					}, {
						FirstBar = new( "Frame", {
							LayoutOrder = 0,
							RBXTAG_Divider = true,
							RBXTAG_STATE_Vertical = true,
						}),
						SecondBar = new( "Frame", {
							LayoutOrder = 1,
							RBXTAG_Divider = true,
							RBXTAG_STATE_Vertical = true,
						}),
					}),
				}, "SmallSelectionPane", self)
			}) or nil,
			SelectionPane = not IsSmallScreen and new(SelectionPane, {
				--		LayoutOrder = 2;
				SizeSignal = self.Maid.SelectionPaneSignal,
				Core = self.props.Core;
				MaxYSize = self.state.MaxSize,
				IsSmallScreen = IsSmallScreen,
				RoactRef = self.SelectionPaneRef
			});
		}, script.Name, self),
	})
end

return Dock