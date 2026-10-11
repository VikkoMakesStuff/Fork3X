local Root = script:FindFirstAncestorWhichIsA('Tool')
local Vendor = Root:WaitForChild('Vendor')
local TextService = game:GetService('TextService')

-- Libraries
local Roact = require(Vendor:WaitForChild('Roact'))
local new = function(Type, props, ...)
	props["RBXTAG_Native"] = true

	return Roact.createElement(Type, props, ...)
end

-- Create component
local Tooltip = Roact.PureComponent:extend(script.Name)

function Tooltip:init()
	local Button = self.props.Button
	self.ToolTip = Roact.createRef()
	
	self.FrameSize, self.SetFrameSize = Roact.createBinding(UDim2.new())
	self.ToolTipPosition, self.SetToolTipPosition = Roact.createBinding( Button:getValue() and Button:getValue().AbsolutePosition or Vector2.new() )
	
	self.props.CanvasPositionSignal:Connect(function()
		if Button:getValue() and self.props.IsVisible then
			self.SetToolTipPosition(Button:getValue().AbsolutePosition)
		end
	end)
	
	self:UpdateTextBounds(self.props.Text)
end

function Tooltip:willUpdate(nextProps)
    if self.props.Text ~= nextProps.Text then
        self:UpdateTextBounds(nextProps.Text)
	end
	
	local ButtonRef = self.props.Button:getValue()
	
	if self.props.IsVisible ~= nextProps.IsVisible and ButtonRef then
		self.SetToolTipPosition(ButtonRef.AbsolutePosition)
	end
end

function Tooltip:UpdateTextBounds(Text)
    self.TextBounds = TextService:GetTextSize(
        Text:gsub('<br />', '\n'):gsub('<.->', ''),
        10,
        Enum.Font.Gotham,
        Vector2.new(math.huge, math.huge)
    )
end

function Tooltip:render()
    return new('Frame', {
    --    AnchorPoint = Vector2.new(0.5, 0);
    --    BackgroundColor3 = Color3.fromRGB(0, 0, 0);
    --    BackgroundTransparency = 0;
    --    BorderSizePixel = 0;
		--    Position = UDim2.new(0.5, 0, 1, -1);
		Position = self.ToolTipPosition:map(function(Value)
			local Offset = UDim2.fromOffset(0, 0)
			
			local ToolTipRef: Frame = self.ToolTip:getValue()
			
			if ToolTipRef then
				ToolTipRef:ResetPropertyToDefault("Position")
				
				local StyledOffset: UDim2 = ToolTipRef:GetStyled("Position")
				
				local X = StyledOffset.X.Offset + StyledOffset.X.Scale * 35
				local Y = StyledOffset.Y.Offset + StyledOffset.Y.Scale * 35
				
				Offset = UDim2.fromOffset(X, Y)
			end
			
			return UDim2.fromOffset(Value.X, Value.Y) + Offset
		end),
        Size = UDim2.fromOffset(self.TextBounds.X + 20, self.TextBounds.Y + 8);
        ZIndex = 6,
		Visible = self.props.IsVisible;
		RBXTAG_ToolTip = true;
		[Roact.Ref] = self.ToolTip,
	}, {
		--[[
        Corners = new('UICorner', {
            CornerRadius = UDim.new(0, 3);
        });]]
        Arrow = new('Frame', {
        --    AnchorPoint = Vector2.new(0.5, 0.5);
        --    BackgroundColor3 = Color3.fromRGB(0, 0, 0);
        --    BackgroundTransparency = 0;
        --    BorderSizePixel = 0;
        --    Position = UDim2.new(0.5, 0, 0, 0);
        --    Size = UDim2.new(0, 6, 0, 6);
            ZIndex = 5;
        });
        Text = new('TextLabel', {
        --    BackgroundTransparency = 1;
        --    Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
        --    Font = Enum.Font.Gotham;
            RichText = true;
			Text = self.props.Text;
        --    TextColor3 = Color3.fromRGB(255, 255, 255);
        --    TextSize = 10;
        --    TextXAlignment = Enum.TextXAlignment.Center;
        --    TextYAlignment = Enum.TextYAlignment.Center;
        });
	},  script.Name, self)
end

return Tooltip