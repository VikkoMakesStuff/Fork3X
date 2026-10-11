local Settings = {
	--["Extra Features"] = 
}

local Main = script.Parent.Parent

local function GetSettingHandler(props, Component)
	local Core = props.Core
	local Environment = props.Environment
	
	local ThemeInfo = Environment.ThemeInfo
	local Colors = ThemeInfo.Colors
	
	local TypeToComponent = props.TypeToComponent
	
	local Roact = Core.Roact
	local new = Roact.createElement
	
	local Signal = Core.Signal
	
	local SettingComponent = Roact.PureComponent:extend("TextBox")
	
	local NonExhaustive = require(Main.Objects.Settings.NonExhaustive)
	
	local MouseTask

	function SettingComponent:init()
		self.NoHint = false
		
		self.PluginMenu = Core.Plugin:CreatePluginMenu(Core.Services.HttpService:GenerateGUID(false), "Reset to Default")
		
		local ResetSetting = self.PluginMenu:AddNewAction(
			Core.Services.HttpService:GenerateGUID(false),
			"Reset Setting to Default"
		)
		
		ResetSetting.Triggered:Connect(function()
			Core.ResetSetting(self.props.Option.Setting)
		end)
		
		self:setState({
			Value = Core.Options[self.props.Option.Setting] or self.props.Option.DefaultValue
		})
		
		self.SettingsConnection = props.Core.SettingChanged:Connect(function(Name, Value)
			if Name == self.props.Option.Setting then
				self:setState({
					Value = Value
				})
			end
		end)
	end
	
	function SettingComponent:willUnmount()
		if self.SettingsConnection then
			self.SettingsConnection:Disconnect()
			self.SettingsConnection = nil
		end
	end
	
	function SettingComponent:render()
		local Children = {
			UIListLayout = new( "UIListLayout", {
				VerticalAlignment = Enum.VerticalAlignment.Center,
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Name = new( "TextLabel", {
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
				TextColor3 = Colors.TextColor,
				Text = self.props.Option.Name,
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 14,
				[Roact.Event.InputEnded] = function(rbx, InputObject: InputObject)
					if InputObject.UserInputType == Enum.UserInputType.MouseButton2 then
						if Environment.MouseTask then
							task.cancel(Environment.MouseTask)
							Environment.MouseTask = nil

							Environment.RemoveMouseHint()
						end
						
						Environment.HideHints = true
						
						self.PluginMenu:ShowAsync()
						
						Environment.HideHints = false
					end
				end,
				[Roact.Event.MouseMoved] = {Environment.HoverMouseMovement, self.props.Option.Description},
				[Roact.Event.MouseLeave] = Environment.HoverMouseLeave
			}, {
				UIFlexItem = new( "UIFlexItem", {
					FlexMode = Enum.UIFlexMode.Shrink,
				}),
			}),
		}
		
		local Component = TypeToComponent[self.props.Option.Type]

		Children.Option = new( Component, {
			Value = self.state.Value,
			Configuration = self.props.Option,
		} )

		return new( "Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = Colors.Empty,
			LayoutOrder = self.props.LayoutOrder,
			AutomaticSize = Enum.AutomaticSize.Y,
		}, {
			Content = new( "Frame", {
				BackgroundTransparency = 1,
				ZIndex = 2,
				Name = "Content",
				Size = UDim2.new(1, 0, 0, 24),
			}, Children),
			NonExhaustive = self.props.Option.NonExhaustive and new(NonExhaustive(Environment), {
				Configuration = self.props.Option,
				Value = self.state.Value
			}),
			UIPadding = new( "UIPadding", {
				PaddingLeft = UDim.new(0, 20),
				PaddingRight = UDim.new(0, 20),
			}),
		} )
	end

	return SettingComponent
end

return GetSettingHandler