local function GetRoactObject(Environment)
	local Core = Environment.Core
	local ThemeInfo = Environment.ThemeInfo
	local Colors = ThemeInfo.Colors
	
	local Roact = Core.Roact
	local Support = Core.Support
	local new = Roact.createElement

	local Group = Roact.PureComponent:extend("Group")
	
	function Group:init()
		self:setState({
			IsOpen = if self.props.OpenCategories then self.props.OpenCategories[self.props.Name] else false
		})
	end
	
	function Group:didUpdate()
		if self.props.OpenCategories then
			self.props.OpenCategories[self.props.Name] = self.state.IsOpen
		end
	end
	
	function Group:render()
		local DefaultChildren = {
			UIListLayout = new( "UIListLayout", {
				Padding = UDim.new(0, 10),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}
		
		return new( "Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 26),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = self.props.LayoutOrder or 0
		}, {
			Data = new( "Frame", {
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
			}, {
				UIListLayout = new( "UIListLayout", {
					Padding = UDim.new(0, 10),
					VerticalAlignment = Enum.VerticalAlignment.Center,
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Arrow = new( "Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 10, 0, 10),
				}, {
					Icon = new( "ImageButton", {
						BackgroundTransparency = 1,
						ImageColor3 = Colors.TextColor,
						LayoutOrder = 1,
						Size = UDim2.new(0, 6, 0, 10),
						Rotation = self.state.IsOpen and 90 or 0,
						Image = "rbxasset://textures/DeveloperFramework/icon_forward.png",
						BorderSizePixel = 0,
						[Roact.Event.Activated] = function(rbx)
							self:setState({
								IsOpen = not self.state.IsOpen
							})
						end,
					}),
				}),
				Name = new( "TextLabel", {
					FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
					TextColor3 = Colors.TextColor,
					Text = self.props.Name,
					Size = UDim2.new(1, 0, 1, 0),
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextSize = 14,
				}, {
					UIFlexItem = new( "UIFlexItem", {
						FlexMode = Enum.UIFlexMode.Shrink,
					}),
				}),
			}),
			Options = new( "Frame", {
				Position = UDim2.new(0, 0, 0, 36),
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.Y,
				Visible = self.state.IsOpen
			}, Support.Merge(DefaultChildren, {}, self.props.Children) ),

			ReminderLine = new("Frame", {
				Position = UDim2.new(0, 0, 0, 36),
				Size = UDim2.new(0, 1, 1, -36),
				BorderSizePixel = 0,
				BackgroundColor3 = Colors.DividerColor,
			})
		})
	end
	
	return Group
end

return GetRoactObject