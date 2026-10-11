local Root = script:FindFirstAncestorWhichIsA('Tool')
local Vendor = Root:WaitForChild('Vendor')
local UI = Root:WaitForChild('UI')
local Libraries = Root:WaitForChild('Libraries')
local UserInputService = game:GetService('UserInputService')
local GuiService = game:GetService('GuiService')

-- Libraries
local Roact = require(Vendor:WaitForChild('Roact'))
local Maid = require(Libraries:WaitForChild('Maid'))

-- Roact
local new = function(Type, props, ...)
	props["RBXTAG_Native"] = true

	return Roact.createElement(Type, props, ...)
end
local ToolManualWindow = require(UI:WaitForChild('ToolManualWindow'))

-- Create component
local AboutPane = Roact.PureComponent:extend(script.Name)

function AboutPane:init()
	self.DockSize, self.SetDockSize = Roact.createBinding(UDim2.new())
	self.Maid = Maid.new()
	
	self:UpdateColor()
	self.Maid.TrackHistory = self.props.Core.ToolChanged:Connect(function (Tool)
		self:UpdateColor(Tool)
	end)
end

function AboutPane:UpdateColor(Tool)
	if Tool and Tool.Color then
		self:setState({
			Color = Tool.Color.Color;
		})
	end
end


function AboutPane:willUnmount()
	self.Maid:Destroy()
end

function AboutPane:render()
	local ManualText = script:FindFirstChild(UserInputService.PreferredInput.Name) 
		and require( script[UserInputService.PreferredInput.Name] ) 
		or require(script.KeyboardAndMouse)
	
	local ManualContent = {
		{
			Text = ([[<font face="Gotham" weight="800" size="70"><u>FORK</u>
3X</font>

<font face="Gotham" weight="700" transparency="0.3" size="20"><i>(v{version})</i></font>

<font size="16">Made with ❤️ by Vikko151 (Original by <font face="Gotham" weight="700">F3X</font>)  🛠</font>

To learn more about each tool, click on its ❔ icon at the top right corner.<font size="12"><br /></font>]]):gsub("{version}", self.props.Core.Tool.Version.Value),
			
			Alignment = Enum.TextXAlignment.Center,
		}
	}
	
	for _, Text in string.split(ManualText, [[


{split}

]]) do
		table.insert(ManualContent, {Text = Text})
	end
	
	return new('Frame', {
		BackgroundTransparency = 1;
--		BackgroundColor3 = Color3.fromRGB(0, 0, 0);
--		LayoutOrder = self.props.LayoutOrder;
		Size = UDim2.new(1, 0, 0, 32);
--		ClipsDescendants = true;
--		ZIndex = 2;
		RBXTAG_TopBar = true;
	}, {
		Button = new('ImageButton', {
			Image = '';
--			BackgroundTransparency = 0;
--			BackgroundColor3 = self.state.Color;
--			LayoutOrder = self.props.LayoutOrder;
--			Size = UDim2.new(1, 0, 1, 8);
			[Roact.Event.Activated] = function (rbx)
				self:setState({
					IsManualOpen = not self.state.IsManualOpen;
				})
			end;
			[Roact.Event.MouseButton1Down] = function (rbx)
				local Dock = rbx.Parent.Parent
				local InitialAbsolutePosition = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
				local InitialPosition = Dock.Position

				self.Maid.DockDragging = UserInputService.InputChanged:Connect(function (Input)
					if (Input.UserInputType.Name == 'MouseMovement') or (Input.UserInputType.Name == 'Touch') then

						-- Suppress activation response if dragging detected
						if (Vector2.new(Input.Position.X, Input.Position.Y) - InitialAbsolutePosition).Magnitude > 3 then
							rbx.Active = false
						end

						-- Reposition dock
						Dock.Position = UDim2.new(
							InitialPosition.X.Scale,
							InitialPosition.X.Offset + (Input.Position.X - InitialAbsolutePosition.X),
							InitialPosition.Y.Scale,
							InitialPosition.Y.Offset + (Input.Position.Y - InitialAbsolutePosition.Y)
						)
					end
				end)

				self.Maid.DockDraggingEnd = UserInputService.InputEnded:Connect(function (Input)
					if (Input.UserInputType.Name == 'MouseButton1') or (Input.UserInputType.Name == 'Touch') then
						self.Maid.DockDragging = nil
						self.Maid.DockDraggingEnd = nil
						rbx.Active = true
					end
				end)
			end;
			ZIndex = 2;
		}, {
			--[[
			Corners = new('UICorner', {
				CornerRadius = UDim.new(0, 4);
			});
			ListLayout = new('UIListLayout', {
				FillDirection = Enum.FillDirection.Horizontal;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Wraps = true;
				HorizontalAlignment = Enum.HorizontalAlignment.Center;
				VerticalAlignment = Enum.VerticalAlignment.Center;
				HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly
			});
			Padding = new('UIPadding', {
				PaddingRight = UDim.new(0, 2);
			});
			Bound = new('Frame', {
				BackgroundTransparency = 1;
				Size = UDim2.new(1, 0, 0, 8);
				ZIndex = 2;
				LayoutOrder = 3;
			});]]
			Signature = new('TextLabel', {
	--			AnchorPoint = Vector2.new(0, 0.5);
	--			BackgroundTransparency = 1;
				Size = UDim2.new(0.55, 0, 0.87, -8);
				Text = [[<font weight="800"><u>FORK</u><br/>3X</font>]];
				TextStrokeTransparency = 1;
				TextScaled = true;
				RichText = true; 
				TextYAlignment = Enum.TextYAlignment.Bottom;
				TextColor3 = Color3.new(1, 1, 1);
				Font = Enum.Font.Montserrat;
			--	Position = UDim2.new(0.05, 0, 0.5, -4);
				ZIndex = 3;
			--	LayoutOrder = 1;
			}, {
				--[[
				AspectRatio = new('UIAspectRatioConstraint', {
					AspectRatio = 1.2;
				});
				FlexItem = new('UIFlexItem', {
					FlexMode = Enum.UIFlexMode.Fill;
					ItemLineAlignment = Enum.ItemLineAlignment.Center;
				});]]
			});
			HelpIcon = new('ImageLabel', {
			--	AnchorPoint = Vector2.new(1, 0.5);
			--	BackgroundTransparency = 1;
			--	Position = UDim2.new(1, 0, 0.5, -4);
			--	Size = UDim2.new(0.45, 0, 0.7, -8);
			--	Image = 'rbxassetid://12120704330',--'rbxassetid://141911973';
				ZIndex = 3;
			--	LayoutOrder = 2;
			}, {
				--[[
				AspectRatio = new('UIAspectRatioConstraint', {
					AspectRatio = 1;
					DominantAxis = Enum.DominantAxis.Height;
				});
				FlexItem = new('UIFlexItem', {
					FlexMode = Enum.UIFlexMode.Fill;
					ItemLineAlignment = Enum.ItemLineAlignment.Center;
				});]]
			});
			ManualWindowPortal = new(Roact.Portal, {
				target = self.props.Core.UI;
			}, {
				ManualWindow = (self.state.IsManualOpen or nil) and new(ToolManualWindow, {
					Text = ManualContent;
					ThemeColor = Color3.fromRGB(255, 176, 0);
					Components = self.props.Core.RoactComponents;
				});
			});
		})
	}, script.Name, self)
end

return AboutPane