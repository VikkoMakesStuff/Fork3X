local function GetRoactObject(props)
	local Core = props.Core
	local ThemeInfo = props.ThemeInfo
	
	local Roact = Core.Roact
	local Support = Core.Support
	local new = Roact.createElement

	local Check = Roact.PureComponent:extend("TextBox")

	function Check:init()
		self:setState({
			Content = self.props.Value
		})
	end

	function Check:render()
		local IconToDisplay = self.state.ToggleState and ThemeInfo.Icons.CheckOn or ThemeInfo.Icons.CheckOff

		return new( "ImageButton", {
			Size = UDim2.new(0, 100, 0, 20),
			TextColor3 = Color3.new(0.443, 0.463, 0.529),
			Text = self.state.Content or "",
			BackgroundColor3 = Color3.new(0.898, 0.898, 0.902),
			TextXAlignment = Enum.TextXAlignment.Left,
			PlaceholderColor3 = Color3.new(0.776, 0.776, 0.776),
			FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			PlaceholderText = "...",
			TextSize = 15,
			[Roact.Event.FocusLost] = function(rbx)
				if rbx then
					local OptionConfiguration = self.props.Configuration

					local OnActivated = OptionConfiguration.OnActivated

					local Input = rbx.Text

					if OnActivated == "Default" then
						props.SaveSetting(OptionConfiguration.Setting, Input)
					else
						OptionConfiguration:OnActivated(Input)
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

	return Check
end

return GetRoactObject