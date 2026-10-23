local Root = script:FindFirstAncestorWhichIsA('Tool')
local Vendor = Root:WaitForChild('Vendor')
local Libraries = Root:WaitForChild('Libraries')

-- Libraries
local Roact = require(Vendor:WaitForChild('Roact'))
local Maid = require(Libraries:WaitForChild('Maid'))

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

-- Roact
local new = function(Type, props, ...)
	props["RBXTAG_Native"] = true

	return Roact.createElement(Type, props, ...)
end
local ToolButton = require(script.Parent:WaitForChild('ToolButton'))

-- Create component
local ToolList = Roact.PureComponent:extend(script.Name)

local LastMove = time()

function ToolList:init()
	self.Maid = Maid.new()
	self.CanvasSize, self._SetCanvasSize = Roact.createBinding(Vector2.new(math.huge, 315))

	self.ToolNameToIndex = {}

	for ToolIndex, ToolInfo in self.props.Tools do
		self.ToolNameToIndex[ToolInfo.Tool.Name] = ToolIndex
	end

	if not self.props.Core.Plugin then
		local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

		if UserInputService.GamepadEnabled then
			self.Maid.ToolNavigation = self.props.Core.Support.AddUserInputListener("Began", {"DPadLeft", "DPadRight"}, true, function(InputObject)
	
				if GuiService.SelectedObject or time() - LastMove <= 0.02 then
					return
				end

				LastMove = time()

				local CurrentTool = self.props.Core.CurrentTool

				if CurrentTool then
					local ToolName = CurrentTool.Name
					local Index = self.ToolNameToIndex[ToolName]

					if Index then
						local Increment = InputObject.KeyCode == Enum.KeyCode.DPadLeft and -1 or 1

						local NewIndex = Index + Increment

						if self.props.Tools[NewIndex] and self.props.Tools[NewIndex].Tool then
							self.props.Core.EquipTool(self.props.Tools[NewIndex].Tool)
						end
					end
				end
			end)
		end
	end

	-- Track current tool
	--self:setState({
	--	CurrentTool = self.props.Core.CurrentTool;
	--	})

	--[[
	self.Maid.CurrentTool = self.props.Core.ToolChanged:Connect(function (Tool)
		self:setState({
			CurrentTool = Tool;
		})
	end)]]
end

function ToolList:willUnmount()
	self.Maid:Destroy()
end

local Update
local CanvasSize, Size = Vector2.new(), Vector2.new()

function ToolList:SetCanvasSize(NewSize)
	
	local MaxYSize = NewSize.Y

	if MaxYSize == 0 then
		MaxYSize = 315
	end
	
	Size = Vector2.new(NewSize.X, MaxYSize)
	CanvasSize = Vector2.new(math.huge, MaxYSize)
	
	if not Update or coroutine.status(Update) ~= "suspended" then
		Update = task.defer(function()
			if self.props.SizeSignal then
				self.props.SizeSignal:Fire(Size)
			end

			self._SetCanvasSize( CanvasSize )
		end)
	end
end

function ToolList:didUpdate()
	for ToolIndex, ToolInfo in next, self.props.Tools do
		self.ToolNameToIndex[ToolInfo.Tool.Name] = ToolIndex
	end
end

function ToolList:render()
	local ListChildren = {
		Layout = new('UIGridLayout', {
			CellPadding = UDim2.new(0, 0, 0, 0);
			CellSize = UDim2.new(0, 35, 0, 35);
			FillDirection = Enum.FillDirection.Horizontal;
			FillDirectionMaxCells = 2;
			HorizontalAlignment = Enum.HorizontalAlignment.Left;
			VerticalAlignment = Enum.VerticalAlignment.Top;
			SortOrder = Enum.SortOrder.LayoutOrder;
			StartCorner = Enum.StartCorner.TopLeft;
			[Roact.Ref] = function (rbx)
				if rbx then
					self:SetCanvasSize(rbx.AbsoluteContentSize)
				end
			end;
			[Roact.Change.AbsoluteContentSize] = function (rbx)
				if not Size or rbx.AbsoluteContentSize ~= Size.Y then
					self:SetCanvasSize(rbx.AbsoluteContentSize)
				end
			end;
		});
	}
	
	-- Build buttons for each tool
	for ToolIndex, ToolInfo in ipairs(self.props.Tools) do
		ListChildren[tostring(ToolIndex)] = new(ToolButton, {
			--		CurrentTool = self.state.CurrentTool;
			IconAssetId = ToolInfo.IconAssetId;
			HotkeyLabel = ToolInfo.HotkeyLabel;
			LayoutOrder = ToolIndex;
			Tool = ToolInfo.Tool;
			Position = ToolInfo.Position;
			Size = ToolInfo.Size;
			AnchorPoint = ToolInfo.AnchorPoint;
			Core = self.props.Core;
		})
	end

	--	local Children = 

	--[[
	if self.props.Core.RoactComponents and self.props.Core.RoactComponents[script.Name] then
		for _, Function in self.props.Core.RoactComponents[script.Name] do
			table.insert(Children, Function(self))
		end
	end]]

	return new('Frame', {
		--	BackgroundTransparency = 1;
		--	BackgroundColor3 = Color3.fromRGB(0, 0, 0);
		--	BorderSizePixel = 0;
		--		LayoutOrder = self.props.LayoutOrder;
		Size = self.CanvasSize:map(function(Value)	
			return self.props.IsSmallScreen 
				and UDim2.new(1, 0, 1, -32)
				or UDim2.new(1, 0, Value.Y / (self.props.MaxYSize.Y - 32), -16)
		end);
		RBXTAG_ToolList = true;
	}, { 
		List = new('ScrollingFrame', {
			--		BackgroundTransparency = 1;
			--		BorderSizePixel = 0;
			Size = UDim2.new(1, 0, 1, 0);
			CanvasSize = UDim2.new();
			--	ScrollBarThickness = 1;
			ScrollingDirection = Enum.ScrollingDirection.Y;
			--	ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0);
			AutomaticCanvasSize = Enum.AutomaticSize.Y;
			[Roact.Children] = ListChildren;
		});
		SizeConstraint = new('UISizeConstraint', {
			MaxSize = self.CanvasSize
		});
		--[[
		Background = new('Frame', {
			BackgroundTransparency = 0.6;
			BackgroundColor3 = Color3.fromRGB(0, 0, 0);
			BorderSizePixel = 0;
			--	LayoutOrder = self.props.LayoutOrder;
			Size = self.CanvasSize:map(function (CanvasSize)
				return UDim2.new(1, 0, 1, 3)
			end);
			Position = UDim2.new(0, 0, 0, -3);
		}, {
			Corners = new('UICorner', {
				CornerRadius = UDim.new(0, 4);
			});
		})]]
	}, script.Name, self)
end

return ToolList