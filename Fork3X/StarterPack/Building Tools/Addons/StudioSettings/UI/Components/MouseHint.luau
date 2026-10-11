local Settings = {
	--["Extra Features"] = 
}

local Main = script.Parent.Parent

local function GetWindow(props, Component)
	local Core = props.Core
	local Roact = Core.Roact
	local new = Roact.createElement
	
	local ThemeInfo = props.ThemeInfo
	local Colors = ThemeInfo.Colors
	
	local HintData = Component.state.MouseHint

	local Object = new( "TextLabel", {
		FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		AnchorPoint = Vector2.new(1, 1),
		TextSize = 14,
		Size = HintData.Size,
		RichText = true,
		TextColor3 = Colors.Empty,
		Text = HintData.Text,
		BackgroundColor3 = Colors.MouseHintBackground,
		Position = HintData.Position,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Interactable = false,
		Active = false
	}, {
		UIPadding = new( "UIPadding", {
			PaddingBottom = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
		UICorner = new( "UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
		UIStroke = new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Colors.Opposite,
		})
	})

	return Object
end

return GetWindow