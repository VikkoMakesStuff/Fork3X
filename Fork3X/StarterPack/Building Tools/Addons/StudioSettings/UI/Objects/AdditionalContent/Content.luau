local TextService = game:GetService("TextService")

local function GetRoactObject(props)
	local Core = props.Core
	local ThemeInfo = props.ThemeInfo
	
	local Colors = ThemeInfo.Colors

	local Roact = Core.Roact
	local Support = Core.Support
	local new = Roact.createElement

	local ContentComponent = Roact.PureComponent:extend("Content")
	
	function ContentComponent:ExpandPreview()
		local Preview = self.props.Preview
		
		if typeof(Preview) == "Instance" then
			self.IsPreviewRoact = false
			
			self.Preview = Preview:Clone()
		else
			self.IsPreviewRoact = true
			
			self.Preview = Preview
		end
	end
	
	function ContentComponent:init()
		self.ContentRef = Roact.createRef()
		
		self:ExpandPreview()
	end
	
	function ContentComponent:didMount()
		if not self.IsPreviewRoact and self.ContentRef:getValue() then
			self.Preview.Parent = self.ContentRef:getValue()
		end
	end
	
	function ContentComponent:didUpdate(previousProps)
		if self.props.Preview ~= previousProps.Preview then
			if self.Preview and typeof(self.Preview) == "Instance" then
				self.Preview:Destroy()
			end
			
			self:ExpandPreview()
		end

		if not self.IsPreviewRoact and self.ContentRef:getValue() then
			self.Preview.Parent = self.ContentRef:getValue()
		end
	end

	function ContentComponent:render()

		return new( "Frame", {
			LayoutOrder = self.props.LayoutOrder,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, self.props.ObjectYSize),
		}, {
			UIPadding = new( "UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
			TopDivider = new( "Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				BorderSizePixel = 0,
				BackgroundColor3 = Colors.DividerColor,
			}),
			Content = new( "Frame", {
				BackgroundTransparency = 1,
				BorderColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(1, 0, 1, 0),
				[Roact.Ref] = self.ContentRef,
			}, {
				UIListLayout = new( "UIListLayout", {
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Horizontal,
				}),
				Text = new( "Frame", {
					LayoutOrder = 1,
					BackgroundTransparency = 1,
					BorderColor3 = Color3.new(0, 0, 0),
					Size = UDim2.new(1, 0, 1, 0),
					BorderSizePixel = 0,
				}, {
					UIFlexItem = new( "UIFlexItem", {
						FlexMode = Enum.UIFlexMode.Shrink,
					}),
					Description = new( "TextLabel", {
						RichText = true,
						Size = UDim2.new(1, 0, 1, -52),
						TextColor3 = Colors.TextColor,
						Text = self.props.Description,
						Position = UDim2.new(0, 0, 0, 42),
						FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
						TextWrapped = true,
						BackgroundTransparency = 1,
						TextTruncate = Enum.TextTruncate.SplitWord,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextSize = 14,
					}),
					Title = new( "TextLabel", {
						FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
						TextColor3 = Colors.Opposite,
						Text = self.props.Title,
						Size = UDim2.new(1, 0, 0, 32),
						TextWrapped = true,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						Position = UDim2.new(0, 0, 0, 10),
						TextSize = 24,
					}),
				}),
				Examples = self.IsPreviewRoact and self.Preview or nil,
				Buttons = new( "Frame", {
					LayoutOrder = 2,
					BorderColor3 = Color3.new(0, 0, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 16, 1, -20),
				}, {
					UIListLayout = new( "UIListLayout", {
						VerticalAlignment = Enum.VerticalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Right,
						Padding = UDim.new(0, 5),
					}),
					Buttons = self.props.Buttons
				}),
			}),
			BottomDivider = new( "Frame", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 0, 1, 0),
				Size = UDim2.new(1, 0, 0, 1),
				BorderSizePixel = 0,
				BackgroundColor3 = Colors.DividerColor,
			}),
		})
	end

	return ContentComponent
end

return GetRoactObject