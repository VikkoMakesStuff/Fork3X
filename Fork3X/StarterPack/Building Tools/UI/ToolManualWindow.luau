local Root = script:FindFirstAncestorWhichIsA('Tool')
local Vendor = Root:WaitForChild('Vendor')

-- Libraries
local Libraries = Root.Libraries
local Support = require( Libraries:WaitForChild("SupportLibrary") )

local Roact = require(Vendor:WaitForChild('Roact'))
local new = function(Type, props, ...)
	props["RBXTAG_Native"] = true

	return Roact.createElement(Type, props, ...)
end

-- Create component
local ToolManualWindow = Roact.PureComponent:extend(script.Name)

local function MakeUIObjectsFromTextBits(TextData)
	local Objects = {}
	
	for Index, Data in next, TextData do
		Objects[ tostring(Index) ] = new('TextLabel', {
			LayoutOrder = Index + 2 * (Index - 1),
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, -30, 0, 0),
			RichText = true;
			Text = Data.Text;
			TextWrapped = true;
			TextXAlignment = Data.Alignment or Enum.TextXAlignment.Left
		});

		if TextData[Index + 1] then
			Objects[ "Divider" .. tostring(Index) ] = new("Frame", {
				LayoutOrder = Index + 2 * (Index - 1) + 1,
				RBXTAG_Divider = true,
			})
		end
	end
	
	return Objects
end

function ToolManualWindow:init()
	self.CanvasSize, self.SetCanvasSize = Roact.createBinding(UDim2.new(1, 0, 0, 0))
	self.SizeConstraintRef = Roact.createRef()
end

function ToolManualWindow:render()
	local FinalContent = {
		UIListLayout = new("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			[Roact.Ref] = function(rbx)
				if rbx then
					self.SetCanvasSize( UDim2.new(1, 0, 0, rbx.AbsoluteContentSize.Y + 20) )
				end
			end,
			[Roact.Change.AbsoluteContentSize] = function(rbx)
				self.SetCanvasSize( UDim2.new(1, 0, 0, rbx.AbsoluteContentSize.Y + 20) )
			end,
		})
	}
	
	local IsTextATable = type(self.props.Text) == "table"
	
	if IsTextATable then
		Support.Merge( FinalContent, MakeUIObjectsFromTextBits(self.props.Text) )
	else
		local TextBits = {}
		
		local SplitText = self.props.Text:split([[


{split}

]])
		
		for _, Text in SplitText do
			table.insert(TextBits, {Text = Text})
		end

		Support.Merge( FinalContent, MakeUIObjectsFromTextBits(TextBits) )
		
		--[[
		FinalContent.Text = new('TextLabel', {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0);
			RichText = true;
			Text = self.props.Text;
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true;
		})]]
	end
	
    return new('ScreenGui', {
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		DisplayOrder = -1;
    }, {
        Window = new('Frame', {
        --    AnchorPoint = Vector2.new(0.5, 0.5);
        --    BackgroundColor3 = Color3.new(0, 0, 0);
        --    BackgroundTransparency = 0.5;
        --    BorderSizePixel = 0;
			Position = UDim2.new(0.5, 0, 0.5, -35);
			ClipsDescendants = true;
			RBXTAG_Documentation = true;
            Size = UDim2.new(0.4, 0, 1, -70);
		}, {
            SizeConstraint = new('UISizeConstraint', {
				MaxSize = self.CanvasSize:map(function (CanvasSize)
					if self.SizeConstraintRef:getValue() then
						local rbx = self.SizeConstraintRef:getValue()

						local HasSizeConstraint, CurrentSizeConstraint = pcall(rbx.GetStyled, rbx.Parent, "MaxSize", "::UISizeConstraint")
						
						if HasSizeConstraint then
							local MaxSize = Vector2.new(420, CanvasSize.Y.Offset)

							return Vector2.min(MaxSize, CurrentSizeConstraint)
						end
					end
					
					return Vector2.new(420, CanvasSize.Y.Offset)
				end);
				
				[Roact.Ref] = self.SizeConstraintRef,
			});
			--[[
            Corners = new('UICorner', {
                CornerRadius = UDim.new(0, 3);
            });]]
			ColorBar = new('Frame', {
				BackgroundColor3 = self.props.ThemeColor;
				BorderSizePixel = 0;
				Size = UDim2.new(0, 3, 1, 0);
			}, {
				Corners = new('UICorner', {
					CornerRadius = UDim.new(0, 3);
				});
			});
			--[[
			Signature = new('TextLabel', {
				AnchorPoint = Vector2.new(0.5, 0.5);
				BackgroundTransparency = 1;
				Size = UDim2.new(0, 420, 0, 300);
				Text = '<font weight="800"><u>FORK</u><br/>3X</font>';
				TextStrokeTransparency = 1;
				TextTransparency = 0.9;
				TextScaled = true;
				RichText = true;
				TextColor3 = self.props.ThemeColor;
				Font = Enum.Font.MontserratBlack;
				Position = UDim2.new(0.5, 0, 0.5, 0);
				ZIndex = 0;
			});]]
			Content = new('ScrollingFrame', {
				--    BackgroundTransparency = 1;
				--    BorderSizePixel = 0;
				Size = UDim2.new(1, 0, 1, 0);
				CanvasSize = self.CanvasSize;
				--    ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255);
				--    ScrollBarThickness = 2;
				--    ScrollingDirection = Enum.ScrollingDirection.Y;
			}, FinalContent);
		}, script.Name, self);
    })
end

return ToolManualWindow