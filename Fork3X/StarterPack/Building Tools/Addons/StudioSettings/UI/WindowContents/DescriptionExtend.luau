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
		local Color = Environment.ThemeInfo.Colors.Opposite
		local ColorString = string.format('"rgb(%*,%*,%*)"', Color.R * 255, Color.G * 255, Color.B * 255)
		
		return Roact.createFragment({
			Text = new( "TextLabel", {
				RichText = true,
				TextColor3 = Environment.ThemeInfo.Colors.TextColor,
				BorderColor3 = Color3.new(0, 0, 0),
				Text = '<font color=' .. ColorString .. ' size="24"><b>' .. self.props.Title .. "</b></font><br /><br />" .. self.props.Description,
				TextWrapped = true,
				Size = UDim2.new(1, 0, 0, 1),
				BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.Y,
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
				TextSize = 16,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 1,
			}),
		})
	end
	
	return WindowContent
end

return GetRoactObject