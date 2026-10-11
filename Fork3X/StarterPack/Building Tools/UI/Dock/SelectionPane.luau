local Root = script:FindFirstAncestorWhichIsA('Tool')
local Vendor = Root:WaitForChild('Vendor')
local Libraries = Root:WaitForChild('Libraries')

-- Libraries
local Roact = require(Vendor:WaitForChild('Roact'))
local Maid = require(Libraries:WaitForChild('Maid'))
local ImageLabel = require(script.Parent.Parent:WaitForChild('ImageLabel'))
local Support = require(Libraries.SupportLibrary)
local Signal = require(Libraries.Signal)
local Make = require(Root:WaitForChild("Libraries").Make)

-- Services
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

-- Roact
local new = Roact.createElement
local SelectionButton = require(script.Parent:WaitForChild('SelectionButton'))

-- Create component
local SelectionPane = Roact.PureComponent:extend(script.Name)

function SelectionPane:init()
	self.Maid = Maid.new()
	self.PaneSize, self._SetPaneSize = Roact.createBinding(Vector2.new())
	
	self.CanvasPositionChanged = Signal.new()

	self:UpdateHistoryState()
	self.Maid.TrackHistory = self.props.Core.History.Changed:Connect(function ()
		self:UpdateHistoryState()
	end)

	self:UpdateSelectionState()
	self.Maid.TrackSelection = self.props.Core.Selection.Changed:Connect(function ()
		self:UpdateSelectionState()
	end)

	self:UpdateMultiSelectState()
	self.Maid.TrackMultiSelect = self.props.Core.Selection.MultiselectToggle:Connect(function()
		self:UpdateMultiSelectState()
	end)

	self:UpdateExplorerState()
	self.Maid.TrackExplorer = self.props.Core.ExplorerVisibilityChanged:Connect(function ()
		self:UpdateExplorerState()
	end)

	self:UpdateSaveLoadState()
	self.Maid.TrackSaveLoad = self.props.Core.SaveLoadVisibilityChanged:Connect(function ()
		self:UpdateSaveLoadState()
	end)

	self:UpdateRectangleSelectState()
	self.Maid.TrackRectangleSelect = self.props.Core.Targeting.MobileRectangleSelectChanged:Connect(function ()
		self:UpdateRectangleSelectState()
	end)

	self:UpdateMobileButtonsState()
	self.Maid.TrackButtonsChange = self.props.Core.MobileButtonsChanged:Connect(function ()
		self:UpdateMobileButtonsState()
	end)
	
	if not self.props.Core.Plugin then
		local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

		if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
			self.Maid.ToolNavigation = UserInputService.InputBegan:Connect(function(InputObject, GameProcessed)
				local Mouse: Mouse = self.props.Core.Mouse

				if GameProcessed or not Mouse then
					return
				else
					local GuiObjects = PlayerGui:GetGuiObjectsAtPosition( Mouse.X, Mouse.Y )

					local DoesInterfere = false

					for _, Object in GuiObjects do
						if Object.Active and Object.Visible then
							DoesInterfere = true
						end
					end

					if DoesInterfere then
						return
					end
				end

				if InputObject.KeyCode == Enum.KeyCode.ButtonL3 then
					if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf( self.props.RoactRef:getValue() ) then
						GuiService.SelectedObject = nil
					elseif self.props.RoactRef:getValue():IsDescendantOf(self.props.Core.UI) then
						GuiService:Select( self.props.RoactRef:getValue() )
					end
				end
			end)
		end
	end
end

function SelectionPane:UpdateHistoryState()
	self:setState({
		CanUndo = (self.props.Core.History.Index > 0);
		CanRedo = (self.props.Core.History.Index ~= #self.props.Core.History.Stack);
	})
end

function SelectionPane:UpdateSelectionState()
	self:setState({
		IsSelectionEmpty = (#self.props.Core.Selection.Items == 0);
	})
end

function SelectionPane:UpdateMultiSelectState()
	self:setState({
		MultiSelecting = self.props.Core.Selection.Multiselecting;
	})
end

function SelectionPane:UpdateExplorerState()
	self:setState({
		IsExplorerOpen = self.props.Core.ExplorerVisible;
	})
end

function SelectionPane:UpdateSaveLoadState()
	self:setState({
		IsSaveLoadOpen = self.props.Core.SaveLoadVisible;
	})
end

function SelectionPane:UpdateRectangleSelectState()
	self:setState({
		MobileRectangleSelect = self.props.Core.Targeting.MobileRectangleSelect;
	})
end

function SelectionPane:UpdateMobileButtonsState()
	self:setState({
		MobileButtons = self.props.Core.MobileSelectionButtons;
	})
end

local Update
local PaneSize, Size

function SelectionPane:SetPaneSize(NewSize)
	Size = NewSize
	
	local Surface = NewSize.X * NewSize.Y
	
	local RealXSize = self.props.IsSmallScreen and 35 or 70
	local RealYSize = Surface / RealXSize
	
	if not Update or coroutine.status(Update) == "dead" then
		Update = task.defer(function()
			if self.props.SizeSignal then
				self.props.SizeSignal:Fire(Size)
			end
			
			self._SetPaneSize( PaneSize )
		end)
	end
	
	PaneSize = Vector2.new(RealXSize, RealYSize)
end

function SelectionPane:willUnmount()
	self.Maid:Destroy()
end

function SelectionPane:render()

	local Children = {
		--[[
        Corners = new('UICorner', {
			CornerRadius = UDim.new(0, 4);
		});]]
		Layout = new('UIListLayout', {
			Padding = UDim.new(0, 0);
			FillDirection = Enum.FillDirection.Horizontal;
			Wraps = true,
			HorizontalAlignment = self.props.IsSmallScreen and Enum.HorizontalAlignment.Center or Enum.HorizontalAlignment.Left;
			VerticalAlignment = Enum.VerticalAlignment.Top;
			SortOrder = Enum.SortOrder.LayoutOrder;
			[Roact.Ref] = function (rbx)
				if rbx then
					self:SetPaneSize(rbx.AbsoluteContentSize)
				end
			end;
			[Roact.Change.AbsoluteContentSize] = function (rbx)
				if not Size or rbx.AbsoluteContentSize ~= Size.Y then
					self:SetPaneSize(rbx.AbsoluteContentSize)
				end
			end;
		});
		SizeConstraint = new('UISizeConstraint', {
			MaxSize = self.PaneSize,
		});
		UndoButton = new(SelectionButton, {
			LayoutOrder = 1;
			IconAssetId = 'rbxassetid://141741408';
			IsActive = self.state.CanUndo;
			OnActivated = self.props.Core.History.Undo;
			TooltipText = '<b>UNDO</b><br />' .. self.props.Core.GetStringFromHotkey({"Shift", "Z"});
			CanvasPositionSignal = self.CanvasPositionChanged,
			TooltipParent = self.props.Core.AbsolutePositionContainer,
		});
		RedoButton = new(SelectionButton, {
			LayoutOrder = 2;
			IconAssetId = 'rbxassetid://141741327';
			IsActive = self.state.CanRedo;
			OnActivated = self.props.Core.History.Redo;
			TooltipText = '<b>REDO</b><br />' .. self.props.Core.GetStringFromHotkey({"Shift", "Y"});
			CanvasPositionSignal = self.CanvasPositionChanged,
			TooltipParent = self.props.Core.AbsolutePositionContainer,
		});
		DeleteButton = new(SelectionButton, {
			LayoutOrder = 3;
			IconAssetId = 'rbxassetid://141896298';
			IsActive = not self.state.IsSelectionEmpty;
			OnActivated = self.props.Core.DeleteSelection;
			TooltipText = '<b>DELETE</b><br />' .. self.props.Core.GetStringFromHotkey({"Shift", "X"});
			CanvasPositionSignal = self.CanvasPositionChanged,
			TooltipParent = self.props.Core.AbsolutePositionContainer,
		});
		ExportButton = self.props.Core.Options.CanUseExport and new(SelectionButton, {
			LayoutOrder = 4;
			IconAssetId = 'rbxassetid://141741337';
			IsActive = not self.state.IsSelectionEmpty;
			OnActivated = self.props.Core.ExportSelection;
			TooltipText = '<b>EXPORT</b><br />' .. self.props.Core.GetStringFromHotkey({"Shift", "P"});
			CanvasPositionSignal = self.CanvasPositionChanged,
			TooltipParent = self.props.Core.AbsolutePositionContainer,
		});
		CloneButton = new(SelectionButton, {
			LayoutOrder = 5;
			IconAssetId = 'rbxassetid://142073926';
			IsActive = not self.state.IsSelectionEmpty;
			OnActivated = self.props.Core.CloneSelection;
			TooltipText = '<b>CLONE</b><br />' .. self.props.Core.GetStringFromHotkey({"Shift", "C"});
			CanvasPositionSignal = self.CanvasPositionChanged,
			TooltipParent = self.props.Core.AbsolutePositionContainer,
		});
		ExplorerButton = self.props.Core.Options.CanUseExplorer and new(SelectionButton, {
			LayoutOrder = 6;
			IconAssetId = 'rbxassetid://2326621485';
			IsActive = self.state.IsExplorerOpen;
			OnActivated = self.props.Core.ToggleExplorer;
			TooltipText = '<b>EXPLORER</b><br />' .. self.props.Core.GetStringFromHotkey({"Shift", "H"});
			CanvasPositionSignal = self.CanvasPositionChanged,
			TooltipParent = self.props.Core.AbsolutePositionContainer,
		}) or nil;
		GroupButton = new(SelectionButton, {
			LayoutOrder = 7;
			IconAssetId = "rbxassetid://1166534350";
			IsActive = not self.state.IsSelectionEmpty;
			OnActivated = self.props.Core.ArrangePartHotkey;
			TooltipText = '<b>GROUP/UNGROUP</b><br />' .. self.props.Core.GetStringFromHotkey({"Shift", "M"});
			Size = UDim2.new(0.55, 0, 0.55, 0);
			AnchorPoint = Vector2.new(0.5, 0.5);
			Position = UDim2.new(0.5, 0, 0.5, 0);
			CanvasPositionSignal = self.CanvasPositionChanged,
			TooltipParent = self.props.Core.AbsolutePositionContainer,
		});
		MultiSelectButton = new(SelectionButton, {
			LayoutOrder = 8;
			IconAssetId = 'rbxassetid://12072054746';
			IsActive = self.state.MultiSelecting;
			OnActivated = function()
				self.props.Core.Selection.Multiselecting = not self.props.Core.Selection.Multiselecting
				self.props.Core.Selection.MultiselectToggle:Fire()
			end;
			TooltipText = '<b>MULTISELECT</b><br />Hold Shift or Ctrl';
			Size = UDim2.new(0.7, 0, 0.7, 0);
			AnchorPoint = Vector2.new(0.5, 0.5);
			Position = UDim2.new(0.5, 0, 0.5, 0);
			CanvasPositionSignal = self.CanvasPositionChanged,
			TooltipParent = self.props.Core.AbsolutePositionContainer,
		});
		DataButton = self.props.Core.Options.CanUseSaveLoad and new(SelectionButton, {
			LayoutOrder = 9;
			IconAssetId = "rbxassetid://12392896984";
			IsActive = self.state.IsSaveLoadOpen;
			OnActivated = self.props.Core.ToggleSaveLoad;
			TooltipText = '<b>SAVE/LOAD</b><br />' .. self.props.Core.GetStringFromHotkey({"Shift", "L"});
			Size = UDim2.new(0.7, 0, 0.7, 0);
			AnchorPoint = Vector2.new(0.5, 0.5);
			Position = UDim2.new(0.5, 0, 0.5, 0);
			CanvasPositionSignal = self.CanvasPositionChanged,
			TooltipParent = self.props.Core.AbsolutePositionContainer,
		}) or nil;
		RectangleSelectButton = game:GetService("UserInputService").TouchEnabled and new(SelectionButton, {
			LayoutOrder = 10;
			IconAssetId = self.state.MobileRectangleSelect == 2 and "rbxassetid://99463159552749" or "rbxassetid://140571460844683";
			IsActive = self.state.MobileRectangleSelect ~= 0 and true or false;
			OnActivated = self.props.Core.Targeting.ToggleMobileRectangleSelect;
			TooltipText = '<b>RECTANGLE SELECT</b><br />FOR MOBILE';
			Size = UDim2.new(0.6, 0, 0.6, 0);
			AnchorPoint = Vector2.new(0.5, 0.5);
			Position = UDim2.new(0.5, 0, 0.5, 0);
			CanvasPositionSignal = self.CanvasPositionChanged,
			TooltipParent = self.props.Core.AbsolutePositionContainer,
		}) or nil;
		PrismSelectButton = new(SelectionButton, {
			LayoutOrder = 11;
			IconAssetId = "rbxassetid://74102407871192";
			IsActive = not self.state.IsSelectionEmpty;
			OnActivated = self.props.Core.Targeting.PrismSelect;
			TooltipText = '<b>BOX/PRISM SELECT</b><br />' .. self.props.Core.GetStringFromHotkey({"Shift", "K"});
			Size = UDim2.new(0.65, 0, 0.65, 0);
			AnchorPoint = Vector2.new(0.5, 0.5);
			Position = UDim2.new(0.5, 0, 0.5, 0);
			CanvasPositionSignal = self.CanvasPositionChanged,
			TooltipParent = self.props.Core.AbsolutePositionContainer,
		}) or nil;
	}
	
	local function MakeSelectionButtonFromData(Data, LayoutOrder, Name)
		return new(SelectionButton, {
			LayoutOrder = LayoutOrder;
			IconAssetId = Data.Icon;
			IsActive = if Data.IsActive then Data.IsActive() else true;
			OnActivated = Data.Activated;
			TooltipText = Data.TooltipText or '<b>' .. string.upper(Name) .. '</b>';
			Size = Data.Size;
			AnchorPoint = Data.AnchorPoint;
			Position = Data.Position;
			Rotation = Data.Rotation;
			CanvasPositionSignal = self.CanvasPositionChanged,
			TooltipParent = self.props.Core.AbsolutePositionContainer,
		});
	end

	for Index, Data in self.props.Core.CustomSelectionButtons do
		local LayoutOrder = 11 + Index
		
		Children["CustomButton" .. Index] = MakeSelectionButtonFromData(Data, LayoutOrder)
	end
	
	local MobileButtons = self.state.MobileButtons
	
	if MobileButtons ~= nil and UserInputService.PreferredInput == Enum.PreferredInput.Touch then
		Children.FirstDivider = new( "Frame", {
			LayoutOrder = 0,
			RBXTAG_Divider = true,
			RBXTAG_STATE_Horizontal = true,
		})
		
		local Order = Support.Keys(MobileButtons)

		table.sort(Order)
		
		local AmountOfMobileButtons = #Order

		for Index, Name in Order do
			local Data = MobileButtons[Name]
			
			local LayoutOrder = -(AmountOfMobileButtons - Index + 1)
			
			Children[Name] = MakeSelectionButtonFromData(Data, LayoutOrder, Name)
		end
	end

	return new('ScrollingFrame', {
		--        BackgroundTransparency = 0.6;
		--		BackgroundColor3 = Color3.new(0, 0, 0);
		--        BorderSizePixel = 0;
		Size = self.PaneSize:map(function(Value)
			return self.props.IsSmallScreen 
				and UDim2.new(0, 35, 1, -70)
				or UDim2.new(1, 0, Value.Y / (self.props.MaxYSize.Y - 32), 0)
		end);
		--		LayoutOrder = self.props.LayoutOrder;
		--AutomaticCanvasSize = self.props.IsSmallScreen and Enum.AutomaticSize.X or Enum.AutomaticSize.Y;
		CanvasSize = self.props.IsSmallScreen and UDim2.new(0, 35, 0, self.PaneSize:getValue().Y) or UDim2.new(1, 0, 0, self.PaneSize:getValue().Y);
		--	ScrollBarThickness = 1;
		ScrollingDirection = Enum.ScrollingDirection.Y;
		--	ScrollBarImageColor3 = Color3.new();
		RBXTAG_SelectionPane = true;
		RBXTAG_STATE_SmallScreenDesign = self.props.IsSmallScreen,
		[Roact.Ref] = self.props.RoactRef,
		[Roact.Change.CanvasPosition] = function()
			self.CanvasPositionChanged:Fire()
		end,
	}, Children,  script.Name, self)
end

return SelectionPane