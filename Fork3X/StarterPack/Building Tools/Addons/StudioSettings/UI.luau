local TextService = game:GetService("TextService")

local function IsPointInsideGuiObject(GuiObject: GuiBase2d, Point: Vector2)
	local Position = GuiObject.AbsolutePosition
	local Size = GuiObject.AbsoluteSize

	local XStart = GuiObject.AbsolutePosition.X
	local XEnd = XStart + Size.X

	local YStart = GuiObject.AbsolutePosition.Y
	local YEnd = XStart + Size.Y

	local AfterXStart = Point.X >= XStart
	local BeforeXEnd = Point.X <= XEnd

	local AfterYStart = Point.Y >= YStart
	local BeforeYEnd = Point.Y <= YEnd

	if AfterXStart and AfterYStart 
		and BeforeXEnd and BeforeYEnd then

		return true
	end

	return false
end

local function CreatePluginWindow(props)
	local Core = props.Core
	
	local Roact = Core.Roact
	local new = Roact.createElement

	local MainInterface = Roact.PureComponent:extend(script.Name)

	local NotificationComponent = require(script.Components.Notification)
	local MouseHintComponent = require(script.Components.MouseHint)
	
	local CategoriesModules = script.Categories:GetChildren()

	local CurrentTheme = settings().Studio.Theme.Name
	local ThemeInfo = table.clone( require( script.ThemesInfo[CurrentTheme] ) )
	local Colors = ThemeInfo.Colors

	function MainInterface:init()
		self:setState({
			CurrentCategory = "Settings"
		})
		
		self.CategoriesCanvasPositions = {}
		
		self.CanvasPosition, self.SetCanvasPosition = Roact.createBinding( Vector2.new() )
		self.MainScrollingFrame = Roact.createRef()

		self.Environment = {
			Core = Core,
			
			ThemeInfo = ThemeInfo,
			
			MouseTask = nil,
			
			HideHints = false,

			SetMouseHint = function(Text)
				local MousePosition = Core.WidgetWindow:GetRelativeMousePosition()
				local WindowSize = Core.WidgetWindow.AbsoluteSize - Vector2.new(20, 20)

				local NoticeMaxSize = math.min(WindowSize.X, 250)

				local SizeParams = Instance.new("GetTextBoundsParams")
				SizeParams.Size = 14
				SizeParams.Text = Text
				SizeParams.Width = NoticeMaxSize
				SizeParams.Font = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
				SizeParams.RichText = true

				local TextBoxSize = TextService:GetTextBoundsAsync(SizeParams) + Vector2.new(16, 16)

				local TextExtremity = Vector2.min( MousePosition + TextBoxSize, Core.WidgetWindow.AbsoluteSize - Vector2.new(20, 20) )

				local Position = UDim2.fromOffset(TextExtremity.X, TextExtremity.Y)
				local Size = UDim2.fromOffset(TextBoxSize.X, TextBoxSize.Y)

				local Data = {
					Position = Position,
					Size = Size,
					Text = Text
				}

				self:setState({
					MouseHint = Data
				})
			end,

			RemoveMouseHint = function()
				self:setState({
					MouseHint = Roact.None
				})
			end,

			HoverMouseMovement = function(rbx, Text)
				if self.Environment.HideHints then
					return
				end

				if self.Environment.MouseTask then
					task.cancel(self.Environment.MouseTask)
					self.Environment.MouseTask = nil

					self.Environment.RemoveMouseHint()
				end

				local MousePosition = Core.WidgetWindow:GetRelativeMousePosition()

				task.wait()

				local CurrentMousePosition = Core.WidgetWindow:GetRelativeMousePosition()

				if MousePosition == CurrentMousePosition then
					self.Environment.MouseTask = task.delay(0.4, function()
						self.Environment.SetMouseHint(Text)
					end)
				end
			end,

			HoverMouseLeave = function(rbx)
				if self.Environment.MouseTask then
					task.cancel(self.Environment.MouseTask)
					self.Environment.MouseTask = nil

					self.Environment.RemoveMouseHint()
				end
			end,
			
			SaveSetting = function(Name, Value, Key)
				local CurrentValue = Core.GetSetting(Name)
				
				if type(CurrentValue) == "table" and Key then
					CurrentValue[Key] = Value
					
					Core.SetSetting(Name, CurrentValue)
				else
					Core.SetSetting(Name, Value)
				end
			end,
			
			SetNotification = function(Data)
				self:setState({
					Notification = Data
				})
			end,
			
			SetNotificationFromResult = function(self, Success, Text)
				if Success == nil or Text == nil then
					return
				end
				
				local NotificationColor = Success and Colors.Success or Colors.Fail

				local Data = {
					Color = NotificationColor,
					Text = Text
				}

				self.SetNotification(Data)
			end,
			
			CreateWindow = function(Name, Title, Settings)
				local WindowContents = script.WindowContents
				
				local WindowContent = WindowContents:FindFirstChild(Name)
				
				if WindowContent then
					local Data = require(WindowContent)(self)
					
					local RoactComponent = new(Data, Settings)
					
					self:setState({
						WindowContent = RoactComponent,
						WindowTitle = Title
					})
				end
			end,
			
			WindowClosed = Core.Signal.new(),
			
			UserAddons = {},
			DisabledAddons = {},
			IsRestartRequired = false,
			Themes = {}
		}
		
		self.WindowComponent = require(script.Objects.Window)(self)
		
		for _, Addon in Core.EveryAddon do
			if not Addon.Module:IsDescendantOf(Core.AddonsFolder) then
				table.insert(self.Environment.UserAddons, Addon)
			end
			
			if not Addon.Enabled then
				table.insert(self.Environment.DisabledAddons, Addon)
			end
		end
		
		self.ThemeConnection = settings().Studio.ThemeChanged:Connect(function()
			local NewTheme = settings().Studio.Theme.Name
			
			CurrentTheme = NewTheme
			ThemeInfo = Core.Support.Mirror( ThemeInfo, require( script.ThemesInfo[CurrentTheme] ), true )
			Colors = ThemeInfo.Colors
			
			for _, Data in self.CategoriesData do
				Data(true)
			end
			
			self:setState({
				a = "a"
			})
		end)
		
		self.CategoriesData = {}

		for _, Module in CategoriesModules do
			self.CategoriesData[Module.Name] = require(Module)(self.Environment, self)
		end
	end
	
	function MainInterface:willUnmount()
		if self.ThemeConnection then
			self.ThemeConnection:Disconnect()
			self.ThemeConnection = nil
		end
	end
	
	function MainInterface:willUpdate(nextProps, nextState)
		local ScrollingFrame = self.MainScrollingFrame:getValue()
		
		if ScrollingFrame then
			if self.state.CurrentCategory == nextState.CurrentCategory then
				self.SetCanvasPosition(ScrollingFrame.CanvasPosition)
			else
				self.CategoriesCanvasPositions[self.state.CurrentCategory] = ScrollingFrame.CanvasPosition
				
				if self.CategoriesCanvasPositions[nextState.CurrentCategory] then
					self.SetCanvasPosition( self.CategoriesCanvasPositions[nextState.CurrentCategory] )
				else
					self.SetCanvasPosition( Vector2.new() )
				end
			end
		end
	end

	function MainInterface:render()
		local function GetButtonConfiguration(Category, LayoutOrder)
			return new( "TextButton", {
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				TextColor3 = if Category == self.state.CurrentCategory then Colors.HighlightedTextColor else Colors.TextColor,
				Text = Category,
				BackgroundColor3 = if Category == self.state.CurrentCategory then Colors.HighlightedButtonColor else Colors.Empty,
				Size = UDim2.new(0, 0, 0, 24),
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.X,
				TextSize = 15,
				AutoButtonColor = false,
				LayoutOrder = LayoutOrder,
				[Roact.Change.GuiState] = function(rbx)
					if rbx then
						local StateToProperties = {
							[Enum.GuiState.Hover] = {
								BackgroundColor3 = if Category == self.state.CurrentCategory then
									Colors.HoverHightlightedButtonColor 
									else Colors.HoverColor,
								TextColor3 = if Category == self.state.CurrentCategory then
									Colors.HighlightedTextColor 
									else Colors.TextColor
							},
							[Enum.GuiState.Press] = {
								BackgroundColor3 = Colors.PressColor,
								TextColor3 = Colors.HighlightedTextColor
							},
							[Enum.GuiState.Idle] = {
								BackgroundColor3 = if Category == self.state.CurrentCategory then
									Colors.HighlightedButtonColor 
									else Colors.Empty,
								TextColor3 = if Category == self.state.CurrentCategory then
									Colors.HighlightedTextColor else
									Colors.TextColor
							},
						}

						if StateToProperties[rbx.GuiState] then
							for Property, Value in StateToProperties[rbx.GuiState] do
								rbx[Property] = Value
							end
						end

					end
				end,
				[Roact.Event.Activated] = function()
					self:setState({
						CurrentCategory = Category
					})
				end,
			}, {
				UICorner = new( "UICorner", {
					CornerRadius = UDim.new(0, 4),
				}),
				UIPadding = new( "UIPadding", {
					PaddingLeft = UDim.new(0, 20),
					PaddingRight = UDim.new(0, 20),
				}),
			})
		end

		local CategoryContent = self.CategoriesData[self.state.CurrentCategory]
		
		return Roact.createFragment({
			PluginContent = new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {
				Topbar = new( "Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 36),
					BorderSizePixel = 0,
				}, {
					Divider = new( "Frame", {
						AnchorPoint = Vector2.new(0, 1),
						Size = UDim2.new(1, 0, 0, 1),
						Position = UDim2.new(0, 0, 1, 0),
						BorderSizePixel = 0,
						BackgroundColor3 = Colors.DividerColor,
					}),
					Objects = new( "Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
						BorderSizePixel = 0,
					}, {
						UIListLayout = new( "UIListLayout", {
							VerticalAlignment = Enum.VerticalAlignment.Center,
							FillDirection = Enum.FillDirection.Horizontal,
							HorizontalAlignment = Enum.HorizontalAlignment.Right,
							Padding = UDim.new(0, 10),
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),
						Buttons = new( "ScrollingFrame", {
							ScrollBarImageColor3 = Colors.DividerColor,
							Active = true,
							AutomaticCanvasSize = Enum.AutomaticSize.X,
							ScrollBarThickness = 2,
							Size = UDim2.new(1, 0, 1, 0),
							BorderSizePixel = 0,
							BackgroundTransparency = 1,
							ScrollingDirection = Enum.ScrollingDirection.X,
							BackgroundColor3 = Colors.Empty,
							CanvasSize = UDim2.new(0, 0, 0, 0),
							LayoutOrder = 0
						}, {
							UIListLayout = new( "UIListLayout", {
								Padding = UDim.new(0, 7),
								SortOrder = Enum.SortOrder.LayoutOrder,
								FillDirection = Enum.FillDirection.Horizontal,
								VerticalAlignment = Enum.VerticalAlignment.Center
							}),
							UIPadding = new( "UIPadding", {
								PaddingLeft = UDim.new(0, 1),
								PaddingRight = UDim.new(0, 1),
							}),
							UIFlexItem = new( "UIFlexItem", {
								FlexMode = Enum.UIFlexMode.Shrink,
							}),
							Settings = GetButtonConfiguration("Settings", 0),
							Themes = GetButtonConfiguration("Themes", 1),
							Addons = GetButtonConfiguration("Addons & Bridges", 2),
							About = GetButtonConfiguration("About Fork3X", 3),
						}),
						Signature = new( "TextButton", {
							Size = UDim2.new(0, 36, 0, 28);
							Text = [[<font weight="800"><u>FORK</u><br/>3X</font>]];
							TextSize = 12,
							TextStrokeTransparency = 1;
							RichText = true;
							TextYAlignment = Enum.TextYAlignment.Bottom;
							TextColor3 = Colors.Opposite;
							Font = Enum.Font.Montserrat;
							BackgroundTransparency = 1,
							ZIndex = 3;
							LayoutOrder = 1
						}),
					}),
				}),
				Content = new( "ScrollingFrame", {
					ScrollBarImageColor3 = Colors.ScrollBar,
					CanvasPosition = self.CanvasPosition,
					Active = true,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 6,
					Size = UDim2.new(1, 0, 1, -45),
					VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
					BackgroundTransparency = 1,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					Position = UDim2.new(0, 0, 1, 0),
					AnchorPoint = Vector2.new(0, 1),
					BorderSizePixel = 0,
					CanvasSize = UDim2.new(0, 0, 0, 0),
				}, {
					MainFrame = new( "Frame", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1
					}, {
						UIPadding = new( "UIPadding", {
							PaddingRight = UDim.new(0, 16),
						}),
						CategoryWindow = CategoryContent and CategoryContent(),
					} )
					--CategoryWindow = new( CategoryContent ),
				}),
				Notification = self.state.Notification and NotificationComponent(self.Environment, self) or nil,
				MouseHint = self.state.MouseHint and MouseHintComponent(self.Environment, self) or nil,
				UIPadding = new( "UIPadding", {
					PaddingBottom = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 10),
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
				}),
			}),
			Window = self.state.WindowContent and new(self.WindowComponent, {
				Title = self.state.WindowTitle,
				Content = self.state.WindowContent,
			}),
		})
	end

	return MainInterface
end

return CreatePluginWindow