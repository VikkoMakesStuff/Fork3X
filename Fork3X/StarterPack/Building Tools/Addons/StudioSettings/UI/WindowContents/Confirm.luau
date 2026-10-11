local function GetRoactObject(Component)
	local Environment = Component.Environment
	local Core = Environment.Core
	
	local Roact = Core.Roact
	local Support = Core.Support
	local new = Roact.createElement

	local WindowContent = Roact.PureComponent:extend("WindowContent")

	--[[PROPS:
		Title: string,
		Content: RoactFragment,
	]]
	
	function WindowContent:render()
		return Roact.createFragment({
			UIListLayout = new( "UIListLayout", {
				Padding = UDim.new(0, 20),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Buttons = new( "Frame", {
				BorderColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(1, 0, 0, 24),
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 1,
			}, {
				UIListLayout = new( "UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 8),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				No = new( "TextButton", {
					FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
					TextColor3 = Color3.new(0.125, 0.133, 0.153),
					BorderColor3 = Color3.new(0, 0, 0),
					Text = "No",
					Size = UDim2.new(0, 0, 0, 24),
					BorderSizePixel = 0,
					AutomaticSize = Enum.AutomaticSize.X,
					TextSize = 15,
					BackgroundColor3 = Color3.new(0.894, 0.898, 0.918),
					[Roact.Event.Activated] = function()
						Environment.WindowClosed:Fire(false)
						
						Component:setState({
							WindowContent = Roact.None,
							WindowTitle = Roact.None
						})
					end,
				}, {
					UICorner = new( "UICorner", {
						TopLeftRadius = UDim.new(0, 4),
						TopRightRadius = UDim.new(0, 4),
						BottomRightRadius = UDim.new(0, 4),
						BottomLeftRadius = UDim.new(0, 4),
					}),
					UIPadding = new( "UIPadding", {
						PaddingRight = UDim.new(0, 9),
						PaddingLeft = UDim.new(0, 9),
					}),
				}),
				Yes = new( "TextButton", {
					LayoutOrder = 1,
					FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
					TextColor3 = Color3.new(1, 1, 1),
					BorderColor3 = Color3.new(0, 0, 0),
					Text = "Yes",
					Size = UDim2.new(0, 0, 0, 24),
					BorderSizePixel = 0,
					AutomaticSize = Enum.AutomaticSize.X,
					TextSize = 15,
					BackgroundColor3 = Color3.new(0.2, 0.373, 1),
					[Roact.Event.Activated] = function()
						Environment.WindowClosed:Fire(true)

						Component:setState({
							WindowContent = Roact.None,
							WindowTitle = Roact.None
						})
					end,
				}, {
					UICorner = new( "UICorner", {
						TopLeftRadius = UDim.new(0, 4),
						TopRightRadius = UDim.new(0, 4),
						BottomRightRadius = UDim.new(0, 4),
						BottomLeftRadius = UDim.new(0, 4),
					}),
					UIPadding = new( "UIPadding", {
						PaddingRight = UDim.new(0, 9),
						PaddingLeft = UDim.new(0, 9),
					}),
				}),
			}),
			Text = new( "TextLabel", {
				RichText = true,
				TextColor3 = Color3.new(0.416, 0.435, 0.506),
				BorderColor3 = Color3.new(0, 0, 0),
				Text = self.props.Text,
				TextWrapped = true,
				Size = UDim2.new(1, 0, 0, 1),
				BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.Y,
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				TextSize = 16,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 1,
			}),
		})
	end
	
	return WindowContent
end

return GetRoactObject