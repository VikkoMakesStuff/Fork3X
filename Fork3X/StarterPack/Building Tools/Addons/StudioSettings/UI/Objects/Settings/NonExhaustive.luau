local function GetRoactObject(Environment)
	local Core = Environment.Core
	local ThemeInfo = Environment.ThemeInfo
	
	local Colors = ThemeInfo.Colors
	
	local Roact = Core.Roact
	local Support = Core.Support
	local new = Roact.createElement

	local NonExhaustive = Roact.PureComponent:extend("Group")

	function NonExhaustive:init()
		self.FrameSize, self.SetFrameSize = Roact.createBinding(UDim2.new())
	end

	function NonExhaustive:render()
		local Children = {
			UIListLayout = new( "UIListLayout", {
				Padding = UDim.new(0, 10),
				VerticalAlignment = Enum.VerticalAlignment.Top,
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Wraps = true,
				[Roact.Ref] = function (rbx)
					if rbx then
						self.SetFrameSize( UDim2.new( 1, -10, 0, rbx.AbsoluteContentSize.Y) )
					end
				end;
				[Roact.Change.AbsoluteContentSize] = function (rbx)
					self.SetFrameSize(UDim2.new(1, -10, 0, rbx.AbsoluteContentSize.Y) )
				end;
			}),
			UIPadding = new( "UIPadding", {
				PaddingRight = UDim.new(0, 54),
			}),
		}

		for _, Data in next, self.props.Configuration.EnumerateWith(self.props.Value) do
			local Name = Data.Name
			local Key = Data.Key
			
			Children[Name] = new( "TextLabel", {
				FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				BackgroundColor3 = Colors.HighlightedButtonColor,
				TextColor3 = Colors.Opposite,
				RichText = true,
				Text = Name,
				Size = UDim2.fromOffset(0, 24),
				AutomaticSize = Enum.AutomaticSize.X,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 15,
			}, {
				Arrow = new( "ImageButton", {
					Size = UDim2.new(0, 16, 0, 16),
					Position = UDim2.new(1, 50, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					Image = ThemeInfo.Icons.Close,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					[Roact.Event.Activated] = function(rbx)
						if rbx then
							Environment.SaveSetting(self.props.Configuration.Setting, nil, Key)
						end
					end,
				}),
				UIPadding = new( "UIPadding", {
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 54),
				}),
				UICorner = new( "UICorner", {
					CornerRadius = UDim.new(0, 4),
				}),
			})
		end

		return Roact.createFragment({
			NonExhaustive = new( "ScrollingFrame", {
				ScrollBarImageColor3 = Colors.ScrollBar,
				Active = true,
				ScrollBarThickness = 4,
				BackgroundTransparency = 1,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Size = self.FrameSize:map(function(Value)
					return UDim2.new( 1, -10, 0, math.min(Value.Y.Offset, 58) )
				end),
				Position = UDim2.new(0, 10, 0, 34),
				BorderSizePixel = 0,
				CanvasSize = self.FrameSize,
			}, Children),
			
			ReminderLine = new("Frame", {
				Position = UDim2.new(0, 0, 0, 34),
				Size = UDim2.new(0, 1, 1, -34),
				BorderSizePixel = 0,
				BackgroundColor3 = Colors.DividerColor,
			})
		})
	end

	return NonExhaustive
end

return GetRoactObject