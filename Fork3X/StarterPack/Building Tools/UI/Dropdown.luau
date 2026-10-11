local Root = script.Parent.Parent

local Core = require(Root.Core)
local Vendor = Root:WaitForChild('Vendor')
local Libraries = Core.Libraries

local TextService = game:GetService("TextService")


local Roact = require(Vendor:WaitForChild('Roact'))
local Cryo = require(Libraries:WaitForChild('Cryo'))
local Maid = require(Libraries:WaitForChild('Maid'))
local Support = require(Libraries:WaitForChild("SupportLibrary"))
local MaterialsImages = require(Libraries:WaitForChild("MaterialsLibrary"))

local Tools = Root:WaitForChild("Tools")
local new = function(Type, props, ...)
	if props then
		props["RBXTAG_Native"] = true
	end

	return Roact.createElement(Type, props, ...)
end


local Dropdown = Roact.PureComponent:extend(script.Name)

function Dropdown:init()
	self.Maid = Maid.new()
	
	self.Size, self.SetSize = Roact.createBinding(Vector2.new())
	self.FocusedOption, self.SetFocusedOption = Roact.createBinding("")
	self.AbsolutePosition, self.SetAbsolutePosition = Roact.createBinding(Vector2.new())
	
	self.DropdownContainer = Core.AbsolutePositionContainer:FindFirstChild("DropdownContainer")
	
	if not self.DropdownContainer then
		self.DropdownContainer = Core.Make("ImageButton")({
			Name = "DropdownContainer",
			Size = UDim2.fromScale(0, 0),
			RBXTAG_Dropdown = true,
			Parent = Core.AbsolutePositionContainer
		})
	end
	
	self.OptionRef = Roact.createRef()
	self.ButtonRef = Roact.createRef()
	self.OptionsFrameRef = Roact.createRef()
	self.OptionsListRef = Roact.createRef()
	
	self.FocusOrder = {"", 1}
	self.IsEnterPressed = false
	
	self.Maid.ToolChanged = Core.ToolChanged:Connect(function()
		self:setState({
			AreOptionsVisible = false
		})
	end)
	
	self.Maid.OnKeyPressed = game:GetService("UserInputService").InputBegan:Connect(function(Input, GameProcessedEvent)
		if self.state.AreOptionsVisible == false then return end
		
		self:FocusOption(Input, GameProcessedEvent)
	end)
	
	self.Maid.OnKeyReleased = game:GetService("UserInputService").InputEnded:Connect(function(Input, GameProcessedEvent)
		if Input.KeyCode == Enum.KeyCode.Return then

			self.IsEnterPressed = false

		end
	end)
	
	self:setState({
		AreOptionsVisible = false;
	})
end

function Dropdown:FocusOption(Input: InputObject, IsFromTheGame: boolean)
	
	local KeyCode = Input.KeyCode.Name
	
	if self.IsEnterPressed and Input.UserInputState == Enum.UserInputState.Begin and Input.UserInputType == Enum.UserInputType.Keyboard and string.len(KeyCode) == 1 then
		if self.FocusOrder[1] ~= KeyCode then
			self.FocusOrder[1] = KeyCode
			self.FocusOrder[2] = 1
		else
			self.FocusOrder[2] += 1
		end
		
		local Options = self.props.Options
		
		local ValidOptions = {}
		
		for i = 1, #Options do
			local OptionFirstLetter = string.sub(Options[i], 1, 1)
			
			if OptionFirstLetter == self.FocusOrder[1] then
				table.insert(ValidOptions, Options[i])
			end
		end
		
		if self.FocusOrder[2] > #ValidOptions then
			self.FocusOrder[2] = 1
		end
		
		self.SetFocusedOption(ValidOptions[self.FocusOrder[2]])
		
	elseif Input.KeyCode == Enum.KeyCode.Return then
		
		self.IsEnterPressed = true
	
	end
	
end

function Dropdown:didUpdate(previousProps, previousState)
	if Core.IsGamepad() and previousState and self.state.AreOptionsVisible == true and previousState.AreOptionsVisible == false then
		game:GetService("GuiService"):Select( self.OptionsListRef:getValue() )
	end
end

function Dropdown:didMount()
	if self.OptionRef:getValue() and self.props.AutomaticXSize then
		
		local OptionsLabel = self.OptionRef:getValue()
		local Params = Instance.new("GetTextBoundsParams")

		Params.Font = OptionsLabel:GetStyled("FontFace")
		Params.Size = OptionsLabel:GetStyled("TextSize")

		local LongestOption = ""

		for _, Name in self.props.Options do
			if #Name >= #LongestOption then
				LongestOption = Name
			end
		end

		Params.Text = LongestOption
		
		self:setState({
			TextXSize = TextService:GetTextBoundsAsync(Params).X
		})
	end
end

function Dropdown:BuildButtonList()
	local List = {}
	for Index, Option in ipairs(self.props.Options) do
		local PreviewFont = nil
		
		if self.props.OccurrenceOptions and self.props.TextPreview then
			PreviewFont = Support.FindTableOccurrence(self.props.OccurrenceOptions, Option) or Enum.Font.Arimo
		end
		table.insert(List, new('TextButton', {
			RBXTAG_STATE_Focused = self.FocusedOption:map(function(Focus) 
				return Focus == Option and true or false;
			end);
			RBXTAG_STATE_CurrentOption = self.props.CurrentOption == Option and true or false;
			Text = Option;
			ZIndex = 4;
			[Roact.Event.MouseEnter] = function (rbx)
				Core.PlaySound("Hover")
			end,
			[Roact.Event.Activated] = function (rbx)
				Core.PlaySound("Press")
				
				self.props.OnOptionSelected(Option, Index)
				self:setState({
					AreOptionsVisible = false;
				})
			end;
		}, {
			ImagePreview = self.props.ImagePreview and new('ImageLabel', {
				BackgroundTransparency = 0;
				BackgroundColor3 = Color3.fromRGB(120, 120, 120);
				BorderSizePixel = 0;
				Image = tonumber(MaterialsImages[Option]) and "rbxassetid://" .. MaterialsImages[Option] or MaterialsImages[Option] or "rbxasset://Textures/ui/dialog_purpose_help.png";
				AnchorPoint = Vector2.new(1, 0.5);
				Position = UDim2.new(1, 0, 0.5, 0);
				Size = UDim2.new(0, 20, 0, 20);
				ZIndex = 3;
				ScaleType = Enum.ScaleType.Tile;
				TileSize = MaterialsImages[Option] and UDim2.new(2, 0, 2, 0) or UDim2.new(1, 0, 1, 0);
			}) or nil;
			TextPreview = self.props.TextPreview and new('TextLabel', {
				BackgroundTransparency = 1;
				BorderSizePixel = 0;
				Text = "A";
				TextScaled = true;
				AnchorPoint = Vector2.new(1, 0.5);
				Position = UDim2.new(1, 0, 0.5, 0);
				Size = UDim2.new(0, 20, 0, 20);
				TextColor3 = Color3.fromRGB(255, 255, 255);
				ZIndex = 3;
				Font = typeof(PreviewFont) == "EnumItem" and PreviewFont or nil,
				FontFace = typeof(PreviewFont) == "Font" and PreviewFont or nil
			}) or nil;
		}))
	end
	return List
end

function Dropdown:render()
	local Lines = math.clamp( math.ceil(#self.props.Options / self.props.MaxRows), 0, 3)
	local Rows = math.min(#self.props.Options, self.props.MaxRows)
	
	local ScrollBarExtra = self.props.MaxRows * 3 < #self.props.Options and 12 or 0
	
	local AbsoluteSize = self.Size:getValue()
	
	local OptionsSize = UDim2.fromOffset( Lines * AbsoluteSize.X, Rows * AbsoluteSize.Y + ScrollBarExtra )
	
	return new('ImageButton', {
		AnchorPoint = self.props.AnchorPoint or Vector2.new();
		Position = self.props.Position;
		Size = self.state.TextXSize and self.props.Size + UDim2.fromOffset(self.state.TextXSize + 32, 0) or self.props.Size;
		RBXTAG_Dropdown = true;
		[Roact.Change.AbsolutePosition] = function (rbx)
			self.SetAbsolutePosition(rbx.AbsolutePosition)
		end;
		[Roact.Change.AbsoluteSize] = function (rbx)
			self.SetSize(rbx.AbsoluteSize)
		end;
		[Roact.Ref] = function(rbx)
			if rbx then
				self.SetAbsolutePosition(rbx.AbsolutePosition)
				self.SetSize(rbx.AbsoluteSize)
			end
		end,
		[Roact.Event.MouseEnter] = function (rbx)
			Core.PlaySound("Hover")
		end;
		[Roact.Event.Activated] = function (rbx)
			Core.PlaySound("Press")

			self:setState({
				AreOptionsVisible = not self.state.AreOptionsVisible;
			})
		end;
	}, {
		CurrentOption = new('TextLabel', {
			Text = self.props.CurrentOption or '*';
			Position = UDim2.new(0, 6, 0, 0);
			Size = UDim2.new(1, -32, 1, 0);
			[Roact.Ref] = self.OptionRef;
		});
		Arrow = new('ImageLabel', {});
		ContentPortal = new(Roact.Portal, {
			target = self.DropdownContainer
		}, {
			ScrollFrame = new('ScrollingFrame', {
				Visible = self.state.AreOptionsVisible;
				Position = self.AbsolutePosition:map(function(Value)
					local X = 0
					local Y = 0

					local ExtraUDim2 = self.props.OptionsPosition

					if not ExtraUDim2 and self.OptionsFrameRef:getValue() then
						local OptionsFrame = self.OptionsFrameRef:getValue()

						local FormerPosition = OptionsFrame.Position

						OptionsFrame:ResetPropertyToDefault("Position")

						ExtraUDim2 = OptionsFrame:GetStyled("Position") or UDim2.new()

						OptionsFrame.Position = FormerPosition
					elseif not self.OptionsFrameRef:getValue() then
						ExtraUDim2 = UDim2.new()
					end

					local AbsoluteSize = self.Size:getValue()

					X = AbsoluteSize.X * ExtraUDim2.X.Scale + ExtraUDim2.X.Offset
					Y = AbsoluteSize.Y * ExtraUDim2.Y.Scale + ExtraUDim2.Y.Offset

					local FinalValue = Value + Vector2.new(X, Y)
					
					return UDim2.fromOffset(FinalValue.X, FinalValue.Y)
				end);
				Size = OptionsSize;
				ZIndex = 4;
				AutomaticCanvasSize = Enum.AutomaticSize.None;
				CanvasSize = UDim2.fromOffset(
					math.ceil(#self.props.Options / self.props.MaxRows) * AbsoluteSize.X,
					Rows * AbsoluteSize.Y
				);
				ScrollingDirection = Enum.ScrollingDirection.X;
				CanvasPosition = self.FocusedOption:map(function(Option)
					local FocusedOptionInProps = table.find(self.props.Options, Option)
					
					if FocusedOptionInProps then
						return Vector2.new(
							math.ceil(table.find(self.props.Options, Option) / self.props.MaxRows - 1) * self.props.Size.X.Offset,
							0
						)
					else
						return Vector2.new(0, 0)
					end
				end);
				[Roact.Ref] = self.OptionsListRef,
			}, Cryo.Dictionary.join(self:BuildButtonList(), {
				Layout = new('UIGridLayout', {
					CellPadding = UDim2.new();
					CellSize = self.Size:map(function (Size)

						return UDim2.fromOffset(Size.X, Size.Y)
					end);
					FillDirection = Enum.FillDirection.Vertical;
					FillDirectionMaxCells = self.props.MaxRows;
					HorizontalAlignment = Enum.HorizontalAlignment.Left;
					VerticalAlignment = Enum.VerticalAlignment.Top;
					SortOrder = Enum.SortOrder.LayoutOrder;
					StartCorner = Enum.StartCorner.TopLeft;
				});
			}));
			Options = new('Frame', {
				Visible = self.state.AreOptionsVisible;
				Position = self.AbsolutePosition:map(function(Value)
					local X = 0
					local Y = 0

					local ExtraUDim2 = self.props.OptionsPosition

					if not ExtraUDim2 and self.OptionsFrameRef:getValue() then
						local OptionsFrame = self.OptionsFrameRef:getValue()

						local FormerPosition = OptionsFrame.Position

						OptionsFrame:ResetPropertyToDefault("Position")

						ExtraUDim2 = OptionsFrame:GetStyled("Position") or UDim2.new()

						OptionsFrame.Position = FormerPosition
					elseif not self.OptionsFrameRef:getValue() then
						ExtraUDim2 = UDim2.new()
					end

					local AbsoluteSize = self.Size:getValue()

					X = AbsoluteSize.X * ExtraUDim2.X.Scale + ExtraUDim2.X.Offset
					Y = AbsoluteSize.Y * ExtraUDim2.Y.Scale + ExtraUDim2.Y.Offset

					local FinalValue = Value + Vector2.new(X, Y)

					return UDim2.fromOffset(FinalValue.X, FinalValue.Y)
				end);
				[Roact.Ref] = self.OptionsFrameRef,
				Size = OptionsSize;
				ZIndex = 3;
			});
			
		})
	},  script.Name, self)
end

return Dropdown