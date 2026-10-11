local Settings = {
	--["Extra Features"] = 
}

local Main = script.Parent.Parent

local function GetNotificationHandler(props, Component)
	local Core = props.Core
	local Roact = Core.Roact
	local new = Roact.createElement
	
	local NotificationData = Component.state.Notification
	
	local Children = props.Children

	local Object = new( "TextLabel", {
		TextWrapped = true,
		AnchorPoint = Vector2.new(0, 1),
		TextSize = 14,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = NotificationData.Color,
		TextColor3 = Color3.new(1, 1, 1),
		Text = NotificationData.Text,
		Position = UDim2.new(0, 0, 1, 0),
		FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
		Name = "Notification",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		Close = new( "ImageButton", {
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(1, 8, 0, 0),
			Image = "rbxasset://studio_svg_textures/Lua/StartPage/Light/Large/CancelLarge.png",
			BackgroundTransparency = 1,
			[Roact.Event.Activated] = function()
				Component:setState({
					Notification = Roact.None
				})
			end,
		}),
		UIPadding = new( "UIPadding", {
			PaddingBottom = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 32),
		}),
		UICorner = new( "UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
	})

	return Object
end

return GetNotificationHandler