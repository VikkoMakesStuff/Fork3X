local function GetRoactObject(props)
	local Core = props.Core
	local ThemeInfo = props.ThemeInfo

	local Roact = Core.Roact
	local Support = Core.Support
	local new = Roact.createElement

	local Check = Roact.PureComponent:extend("Check")
	
	function Check:init()
		self:setState({
			ToggleState = self.props.Value
		})
	end
	
	function Check:render()
		local IconToDisplay = self.state.ToggleState and ThemeInfo.Icons.CheckOn or ThemeInfo.Icons.CheckOff
		
		return new( "ImageButton", {
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(0, 16, 0, 16),
			AnchorPoint = Vector2.new(0, 0.5),
			AutoButtonColor = false,
			LayoutOrder = 1,
			Image = IconToDisplay,
			BackgroundTransparency = 1,
			[Roact.Change.GuiState] = function(rbx)
				if rbx then
					local IconToDisplay = self.state.ToggleState and ThemeInfo.Icons.CheckOn or ThemeInfo.Icons.CheckOff
					
					local StateToIcon = {
						[Enum.GuiState.Hover] = not self.state.ToggleState and ThemeInfo.Icons.CheckHover or IconToDisplay,
						[Enum.GuiState.Press] = not self.state.ToggleState and ThemeInfo.Icons.CheckHover or IconToDisplay,
						[Enum.GuiState.Idle] = IconToDisplay,
					}

					if StateToIcon[rbx.GuiState] then
						rbx.Image = StateToIcon[rbx.GuiState]
					end

				end
			end,
			[Roact.Event.Activated] = function(rbx)
				local OptionConfiguration = self.props.Configuration
				
				local OnActivated = OptionConfiguration.OnActivated
				
				if OnActivated == "Default" then
					props.SaveSetting(OptionConfiguration.Setting, not self.state.ToggleState)
				else
					OptionConfiguration:OnActivated(not self.state.ToggleState)
				end
				
				self:setState({
					ToggleState = not self.state.ToggleState
				})
			end,
		})
	end
	
	return Check
end

return GetRoactObject