local function GetRoactObject(props)
	local Core = props.Core
	local ThemeInfo = props.ThemeInfo
	
	local Colors = ThemeInfo.Colors
	
	local Roact = Core.Roact
	local Support = Core.Support
	local new = Roact.createElement

	local TextBox = Roact.PureComponent:extend("TextBox")

	function TextBox:init()
		self:setState({
			Content = self.props.Value
		})
	end

	function TextBox:render()
		local OptionConfiguration = self.props.Configuration
		
		local IconToDisplay = self.state.ToggleState and ThemeInfo.Icons.CheckOn or ThemeInfo.Icons.CheckOff

		return new( "TextBox", {
			Size = UDim2.new(0, OptionConfiguration.UIConfiguration.XSize or 100, 0, 20),
			TextColor3 = Colors.TextColor,
			Text = not OptionConfiguration.NonExhaustive and self.state.Content or "",
			BackgroundColor3 = Colors.HighlightedButtonColor,
			TextXAlignment = Enum.TextXAlignment.Left,
			PlaceholderColor3 = Colors.ScrollBar,
			FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			PlaceholderText = "...",
			LayoutOrder = 1,
			TextSize = 15,
			[Roact.Event.FocusLost] = function(rbx)
				if rbx then
					local OnActivated = OptionConfiguration.OnActivated
					
					local Input = rbx.Text

					if OnActivated == "Default" then
						props.SaveSetting(OptionConfiguration.Setting, Input)
					else
						props:SetNotificationFromResult( OptionConfiguration:OnActivated(Input) )
					end

					self:setState({
						Content = Input
					})
				end
			end,
		}, {
			UICorner = new( "UICorner", {
				CornerRadius = UDim.new(0, 4),
			}),		
			UIPadding = new( "UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
		})
	end

	return TextBox
end

return GetRoactObject