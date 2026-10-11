local function GetRoactObject(Component)
	local Environment = Component.Environment
	local Core = Environment.Core
	local ThemeInfo = Environment.ThemeInfo
	
	local Colors = ThemeInfo.Colors
	
	local Roact = Core.Roact
	local Support = Core.Support
	local new = Roact.createElement

	local Window = Roact.PureComponent:extend("Window")
	
	function Window:init()
		self.ContentSize, self.SetContentSize = Roact.createBinding( Vector2.new() )
		
		self:setState({
			IsOpen = false
		})
	end
	
	--[[PROPS:
		Title: string,
		Content: RoactFragment,
	]]
	
	function Window:render()
		return new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.8,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(0, 0, 0),
			Active = true,
		}, {
			Container = new( "Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(0.7, 0, 0.7, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Colors.Empty,
			}, {
				UICorner = new( "UICorner", {
					TopLeftRadius = UDim.new(0, 12),
					TopRightRadius = UDim.new(0, 12),
					BottomRightRadius = UDim.new(0, 12),
					BottomLeftRadius = UDim.new(0, 12),
				}),
				UIPadding = new( "UIPadding", {
					PaddingTop = UDim.new(0, 8),
					PaddingBottom = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
					PaddingLeft = UDim.new(0, 8),
				}),
				UISizeConstraint = new( "UISizeConstraint", {
					MaxSize = self.ContentSize:map(function(Value)
						return Vector2.new(math.huge, Value.Y + 62)
					end),
				}),
				Content = new( "ScrollingFrame", {
					ScrollBarImageColor3 = Colors.ScrollBar,
					Active = true,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 6,
					Position = UDim2.new(0, 0, 0, 42),
					VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
					Size = UDim2.new(1, 0, 1, -42),
					ScrollingDirection = Enum.ScrollingDirection.Y,
					BackgroundColor3 = Colors.Empty,
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					CanvasSize = UDim2.new(0, 0, 0, 0),
					[Roact.Ref] = function(rbx)
						if rbx then
							self.SetContentSize( rbx.AbsoluteCanvasSize )
						end
					end,
					[Roact.Change.AbsoluteCanvasSize] = function(rbx)
						self.SetContentSize( rbx.AbsoluteCanvasSize )
					end,
				}, {
					Content = self.props.Content,
				}),
				Topbar = new( "Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 22),
				}, {
					Divider = new( "Frame", {
						AnchorPoint = Vector2.new(0, 1),
						Position = UDim2.new(0, 0, 1, 10),
						Size = UDim2.new(1, 0, 0, 1),
						BorderSizePixel = 0,
						BackgroundColor3 = Colors.DividerColor,
					}),
					ImageButton = new( "ImageButton", {
						AnchorPoint = Vector2.new(1, 0.5),
						Image = ThemeInfo.Icons.Cross,
						BackgroundTransparency = 1,
						Position = UDim2.new(1, 0, 0.5, 0),
						Size = UDim2.new(0, 16, 0, 16),
						[Roact.Event.Activated] = function()
							Environment.WindowClosed:Fire()
							
							Component:setState({
								WindowContent = Roact.None,
								WindowTitle = Roact.None
							})
						end,
					}),
					Text = new( "TextLabel", {
						FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
						TextColor3 = Colors.TextColor,
						Text = self.props.Title,
						Position = UDim2.new(0, 0, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
						Size = UDim2.new(1, -26, 0, 12),
						TextXAlignment = Enum.TextXAlignment.Left,
						BorderSizePixel = 0,
						TextTruncate = Enum.TextTruncate.AtEnd,
						BackgroundTransparency = 1,
						TextSize = 14,
						BackgroundColor3 = Color3.new(1, 1, 1),
					}),
				}),
			}),
		})
	end
	
	return Window
end

return GetRoactObject