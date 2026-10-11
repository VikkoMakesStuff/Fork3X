local TextService = game:GetService("TextService")

local function GetRoactObject(props)
	local Core = props.Core
	local ThemeInfo = props.ThemeInfo

	local Colors = ThemeInfo.Colors

	local Roact = Core.Roact
	local Support = Core.Support
	local new = Roact.createElement

	local Dropdown = Roact.PureComponent:extend("TextBox")

	local function ButtonGuiState(rbx)
		if rbx then
			local StateToProperties = {
				[Enum.GuiState.Hover] = Colors.HoverHightlightedButtonColor,
				[Enum.GuiState.Press] = Colors.PressColor,
				[Enum.GuiState.Idle] = Colors.HighlightedButtonColor,
			}

			if StateToProperties[rbx.GuiState] then
				rbx.BackgroundColor3 = StateToProperties[rbx.GuiState]
			end

		end
	end

	function Dropdown:init()
		self.PositionState, self.SetPositionState = Roact.createBinding(false)
		self.DropdownScale, self.SetDropdownScale = Roact.createBinding(0)

		self.DropdownRef = Roact.createRef()

		self.WidgetConnection = Core.WidgetWindow.Changed:Connect(function(Name)
			if Name == "AbsoluteSize" then
				self:CheckBoundaries()
			end
		end)

		self:setState({
			AreOptionsVisible = false;
		})
	end

	function Dropdown:CheckBoundaries()
		local rbx = self.DropdownRef:getValue()

		if rbx then
			local Options = self.props.Configuration.UIConfiguration.Options
			local AmountOfOptions = Core.Support.CountKeys(Options)

			local OptionsToDisplay = math.min(AmountOfOptions, 5)

			local MaxYPosition = rbx.AbsolutePosition.Y + 28 + math.min(AmountOfOptions, 2) * 24

			local DisplayAtTop = MaxYPosition >= Core.WidgetWindow.AbsoluteSize.Y
			local MaxSize = DisplayAtTop and (rbx.AbsolutePosition.Y - 62) / 24 or (Core.WidgetWindow.AbsoluteSize.Y - rbx.AbsolutePosition.Y - 38) / 24

			self.SetPositionState( DisplayAtTop )
			self.SetDropdownScale( math.min(OptionsToDisplay, MaxSize) )
		end
	end

	function Dropdown:GetButtonsAndSize()
		local List = {
			UIGridLayout = new( "UIGridLayout", {
				CellPadding = UDim2.fromScale(0, 0),
				CellSize = UDim2.new(1, 0, 0, 24),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			UICorner = new( "UICorner", {
				CornerRadius = UDim.new(0, 4),
			}),
		}

		local BiggestXSize = 0

		local Params = Instance.new("GetTextBoundsParams")
		Params.Font = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
		Params.Size = 15
		Params.Width = math.huge
		Params.RichText = false

		local Options = self.props.Configuration.UIConfiguration.Options
		local Buttons = {}

		for Name in Options do
			table.insert(Buttons, Name)
		end

		table.sort(Buttons)

		for Index, Option in next, Buttons do

			Params.Text = Option

			local XSize = TextService:GetTextBoundsAsync(Params).X

			if XSize >= BiggestXSize then
				BiggestXSize = XSize
			end

			List[ tostring(Index) ] = new('TextButton', {
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				TextColor3 = ThemeInfo.Colors.HighlightedTextColor,
				Text = Option;
				BackgroundColor3 = ThemeInfo.Colors.HighlightedButtonColor,
				BackgroundTransparency = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 15,
				ZIndex = 4;
				LayoutOrder = Index,
				AutoButtonColor = false,
				[Roact.Change.GuiState] = ButtonGuiState,
				[Roact.Event.Activated] = function(rbx)
					local OptionConfiguration = self.props.Configuration

					local OnActivated = OptionConfiguration.OnActivated

					if OnActivated == "Default" then
						props.SaveSetting(OptionConfiguration.Setting, Options[Option])
					else
						OptionConfiguration:OnActivated(Option)
					end

					self:setState({
						AreOptionsVisible = false;
					})
				end,
			}, {
				UICorner = new( "UICorner", {
					CornerRadius = UDim.new(0, 4),
				}),
				UIPadding = new( "UIPadding", {
					PaddingLeft = UDim.new(0, 10),
				}),
			})
		end

		return List, BiggestXSize
	end

	function Dropdown:didUpdate()
		local Dropdown = self.DropdownRef:getValue()

		if Dropdown then
			Dropdown.Parent.Parent.ZIndex = self.state.AreOptionsVisible == true and 10 or 1
		end

		self:CheckBoundaries()
	end

	function Dropdown:willUnmount()
		if self.WidgetConnection then
			self.WidgetConnection:Disconnect()
			self.WidgetConnection = nil
		end
	end

	function Dropdown:render()
		local DropdownContent, MaxXSize = self:GetButtonsAndSize()

		local Options = self.props.Configuration.UIConfiguration.Options
		local AmountOfOptions = Core.Support.CountKeys(Options)

		local MaxYPosition = 28 + math.min(AmountOfOptions, 5) * 24

		return new( "TextButton", {
			FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
			TextColor3 = ThemeInfo.Colors.HighlightedTextColor,
			Size = UDim2.new(0, MaxXSize + 62, 0, 24),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = ThemeInfo.Colors.HighlightedButtonColor,
			TextSize = 15,
			LayoutOrder = 1,
			ZIndex = self.state.AreOptionsVisible and 10 or 1,
			Text = Core.Support.FindTableOccurrence(Options, self.props.Value),
			AutoButtonColor = false,
			[Roact.Ref] = self.DropdownRef,
			[Roact.Change.GuiState] = ButtonGuiState,
			[Roact.Change.AbsolutePosition] = function (rbx)
				self:CheckBoundaries()
			end,
			[Roact.Event.Activated] = function (rbx)
				self:setState({
					AreOptionsVisible = not self.state.AreOptionsVisible;
				})
			end;
		}, {
			UICorner = new( "UICorner", {
				CornerRadius = UDim.new(0, 4),
			}),
			UIPadding = new( "UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 54),
			}),
			UIStorke = self.state.AreOptionsVisible and new( "UIStroke", {
				Color = Color3.fromRGB(51, 95, 255),
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			} ),
			Content = new( "ScrollingFrame", {
				ScrollBarImageColor3 = ThemeInfo.Colors.ScrollBar,
				Active = true,
				ScrollBarThickness = 6,
				AnchorPoint = self.PositionState:map(function(Value)
					return Value and Vector2.new(0, 1) or Vector2.new(0, 0)
				end),
				Position = self.PositionState:map(function(Value)
					return Value and UDim2.new(0, -8, 0, -4) or UDim2.new(0, -8, 1, 4)
				end),
				Visible = self.state.AreOptionsVisible,
				VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
				Size = self.DropdownScale:map(function(Value)
					return UDim2.new(1, 62, Value, 0)
				end),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				BorderSizePixel = 0,
				BackgroundColor3 = ThemeInfo.Colors.HighlightedButtonColor,
				CanvasSize = UDim2.new(1, 0, AmountOfOptions, 0),
			}, DropdownContent),
			Arrow = new( "ImageButton", {
				BorderColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(0, 16, 0, 16),
				Position = UDim2.new(1, 50, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				Image = self.state.AreOptionsVisible and ThemeInfo.Icons.ArrowUp or ThemeInfo.Icons.ArrowDown,
				BackgroundTransparency = 1,
				BackgroundColor3 = ThemeInfo.Colors.Empty,
			}),
		})
	end

	return Dropdown
end

return GetRoactObject