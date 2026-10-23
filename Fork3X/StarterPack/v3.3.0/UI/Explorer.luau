local Root = script.Parent.Parent
local Libraries = Root:WaitForChild 'Libraries'
local Vendor = Root:WaitForChild 'Vendor'
local UI = Root:WaitForChild 'UI'
local RunService = game:GetService 'RunService'
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Options

-- Libraries
local Support = require(Libraries:WaitForChild 'SupportLibrary')
local Roact = require(Vendor:WaitForChild 'Roact')
local Maid = require(Libraries:WaitForChild 'Maid')
local Signal = require(Libraries:WaitForChild 'Signal')

-- Roact
local new = Roact.createElement
local Frame = require(UI:WaitForChild 'Frame')
local ImageLabel = require(UI:WaitForChild 'ImageLabel')
local ImageButton = require(UI:WaitForChild 'ImageButton')
local TextLabel = require(UI:WaitForChild 'TextLabel')
local ItemList = require(script:WaitForChild 'ItemList')

-- Create component
local Explorer = Roact.Component:extend 'Explorer'

local IsTreeUpdating = false
local TreeUpdated = Signal.new()

function Explorer:init(props)
	self:setState {
		Items = {},
		ItemOrder = {},
		RowHeight = 18,
		SearchText = nil
	}

	self.MaxSize, self.SetMaxSize = Roact.createBinding(Vector2.new())

	-- Update batching data
	self.UpdateQueues = {}
	self.QueueTimers = {}
	self.NewItemsQueue = {}
	self.RemovingItemsQueue = {}

	self.ItemsQueueTask = nil

	-- Item tracking data
	self.LastId = 0
	self.IdMap = {}
	self.PendingParent = {}
	self.LastChanges = {}

	-- Order management
	self.ItemOrder = {}

	-- Define item expanding function
	self.ToggleExpand = function (ItemId)
		return self:setState(function (State)
			local Item = State.Items[ItemId]
			Item.Expanded = not Item.Expanded
			return { Items = State.Items }
		end)
	end
end

--[[
function Explorer:didUpdate(previousProps, previousState)

    -- Trigger a scope change if prop changes
    if previousProps.Scope ~= self.props.Scope then
        self:UpdateScope(self.props.Scope)
    end

end]]

function Explorer:UpdateScope(Scope)
	local Core = self.props.BTCore
	local Selection = Core.Selection

	-- Clear previous cleanup maid
	if self.ScopeMaid then
		self.ScopeMaid:Destroy()
	end

	-- Create maid for cleanup
	self.ScopeMaid = Maid.new()

	-- Ensure new scope is defined
	if not Scope then
		return
	end

	-- Build initial tree
	IsTreeUpdating = true

	self.ItemsQueueTask = task.defer(function()
		self:UpdateTree()

		-- Scroll to first selected item
		if #Selection.Items > 0 then
			local FocusedItem = Selection.IsSelected(Selection.Focus) and Selection.Focus or Selection.Items[1]
			self:setState({
				ScrollTo = self.IdMap[FocusedItem]
			})
		else
			self:setState({
				ScrollTo = Roact.None
			})
		end

		IsTreeUpdating = false
		TreeUpdated:Fire()

		self.ItemsQueueTask = nil
	end)

	-- Listen for new and removing items
	local Scope = Core.Targeting.Scope
	self.ScopeMaid.Add = Scope.DescendantAdded:Connect(function (Item)
		-- Queue changed items
		self:QueueUpdate('AddTreeItems', Item, Item.Parent or Item)

		-- Check if queue should be executed
		if not self:ShouldExecuteQueue('AddTreeItems') or not self:ShouldExecuteQueue('RemoveTreeItems') 
			or IsTreeUpdating then

			return
		end

		IsTreeUpdating = true

		self:UpdateTreeFromItems( self:GetUpdateQueue('AddTreeItems') or {}, self:GetUpdateQueue('RemoveTreeItems') or {} )

		IsTreeUpdating = false
		TreeUpdated:Fire()
	end)
	self.ScopeMaid.Remove = Scope.DescendantRemoving:Connect(function (Item)
		-- Queue changed items
		self:QueueUpdate('RemoveTreeItems', Item, Item.Parent or Item)

		-- Check if queue should be executed
		if not self:ShouldExecuteQueue('AddTreeItems') or not self:ShouldExecuteQueue('RemoveTreeItems') 
			or IsTreeUpdating then

			return
		end

		IsTreeUpdating = true

		self:UpdateTreeFromItems( self:GetUpdateQueue('AddTreeItems') or {}, self:GetUpdateQueue('RemoveTreeItems') or {} )

		IsTreeUpdating = false
		TreeUpdated:Fire()
	end)

	-- Listen for selected items
	self.ScopeMaid.Select = Selection.ItemsAdded:Connect(function (Items)
		-- Defer the connection so new descendants can be taken in account (if the likelihood is high)
		task.wait()

		if IsTreeUpdating and (#Items == 1) and not self.IdMap[Items[1]] then
			TreeUpdated:Wait()
		end

		self:UpdateSelection(Items)

		-- If single item selected, get item state
		local ItemId = (#Items == 1) and self.IdMap[Items[1]]

		-- Expand ancestors leading to item
		self:setState(function (State)
			local Changes = {}
			local ItemState = State.Items[ItemId]
			local ParentId = ItemState and self.IdMap[ItemState.Parent]
			local ParentState = ParentId and State.Items[ParentId]

			while ParentState do
				ParentState.Expanded = true
				Changes[ParentId] = ParentState
				ParentId = self.IdMap[ParentState.Parent]
				ParentState = State.Items[ParentId]
			end

			return {
				Items = Support.Merge(State.Items, Changes),
				ScrollTo = ItemId
			}
		end)
	end)
	self.ScopeMaid.Deselect = Selection.ItemsRemoved:Connect(function (Items)
		self:UpdateSelection(Items)
	end)

end

function Explorer:didMount()

	self.Mounted = true

	-- Create maid for cleanup on unmount
	self.ItemMaid = Maid.new()

	self.ItemMaid.ScopeChange = self.props.ScopeChangedSignal:Connect(function(Scope)
		self.props.Scope = Scope

		-- Set scope
		self:UpdateScope(Scope)
	end)

	-- Set scope
	self:UpdateScope(self.props.Scope)
end

function Explorer:willUnmount()
	self.Mounted = false

	-- Clean up resources
	self.ScopeMaid:Destroy()
	self.ItemMaid:Destroy()
end

local function IsTargetable(Item)
	return Item:IsA 'Model' or
		Item:IsA 'BasePart' or
		Item:IsA 'Tool' or
		Item:IsA 'Accessory' or
		Item:IsA 'Accoutrement' or
		Item:IsA 'Attachment'
end

function Explorer.IsItemIndexable(Item)
	return (IsTargetable(Item) and Item.ClassName ~= 'Terrain') or
		Item:IsA 'Folder'
end

-- Updates the explorer from the given items
function Explorer:UpdateTreeFromItems(ItemsToAdd, ItemsToRemove)
	-- Track order of each item
	local OrderCounter = 1
	local IdMap = self.IdMap

	-- Perform update to state
	self:setState(function (State)
		local Changes = {}
		local Appended = {}
		
		local Children = {}

		-- Get a flipped edition of the ItemOrder table
		-- Doing so is way more performant than table.find, since it doesn't go through the table at every call
		-- This means we get O(1) instead of O(n), which is the best we can get
		local FlippedOrder = Support.FlipTable(self.ItemOrder)

		-- Make a recursive function to handle an object's children

		-- Inserts an item's children into the explorer, and returns the index of the last child
		local function HandleChildren(Item, Order)
			local CurrentChildren = Children[Item]

			local ChildOrder = Order

			-- Go through each child
			for ItemOrder, Child in CurrentChildren do

				-- Increment the order
				if ChildOrder then
					ChildOrder += 1
				end

				-- Insert the child
				if not FlippedOrder[Child] then
					self:BuildItemState(Child, self.props.Scope, ChildOrder, Changes, State)
				end

				-- If it has other children, handle them, and update the order according to these
				if Children[Child] then
					ChildOrder = HandleChildren(Child, ChildOrder)
				end
			end

			-- Return the new order for nested operations
			return ChildOrder
		end

		-- Prepare other tables for future operations
		local MustRemove = {}
		local HowManyObjects = Support.CountKeys(ItemsToAdd) + Support.CountKeys(ItemsToRemove)
		local Operation = table.create(HowManyObjects)

		-- Prepare the items we'll use afterwards
		local Items = table.create(HowManyObjects)

		-- Go through the list
		for Item in ItemsToAdd do

			-- Get the item's actual parent, since it can change (with DescendantRemoving)
			local Parent = ItemsToAdd[Item] or ItemsToRemove[Item]
			
			-- Do not remove the item completely, but partly if relevant
			if FlippedOrder[Parent] or Parent == self.props.Scope then
				table.insert(Items, Item)

				Operation[Item] = true
			end

			if self.IsItemIndexable(Item) and ItemsToAdd[Parent] then
				-- If our item is nested in another item we'll add, store it as a child of said item

				-- If the table for this doesn't exist, add it now
				if not Children[Parent] then
					Children[Parent] = {}
				end

				-- Insert the item in said table
				table.insert( Children[Parent], Item )
			end
		end

		-- Insert the items we want to remove if relevant
		-- It's a good idea to handle them with the new items, since we have to sort once
		for Item in ItemsToRemove do
			if IdMap[Item] then
				table.insert(Items, Item)

				Operation[Item] = false
			end
		end

		-- Sort the CurrentItems table in inverse order
		-- This is VERY important, since it allows us to use table.insert and table.remove safely
		-- Both methods will offset every index that follow, which would break the code, or force us to increase operations dramatically
		-- BUT, if we do it in inverse order, said indexes that follow won't be necessary anymore, which lets us use FlippedOrder safely
		table.sort(Items, function(A, B)
			local AParent = ItemsToAdd[A] or ItemsToRemove[A]
			local BParent = ItemsToAdd[B] or ItemsToRemove[B]
			
			if AParent == Support.Blank then
				AParent = A
			elseif BParent == Support.Blank then
				BParent = B
			end

			local CompareA = FlippedOrder[AParent] or #self.ItemOrder
			local CompareB = FlippedOrder[BParent] or #self.ItemOrder

			return CompareA > CompareB
		end)

		-- Go through each item to add
		for _, Item in Items do
			-- Get what operation we must do
			local MustBeAdded = Operation[Item]

			if MustBeAdded then
				-- Get the item's ancestry
				local Ancestry = Support.GetAncestry(Item, self.props.Scope, false)
				local Parent = ItemsToAdd[Item]

				-- Track whether the item can be added to the items list
				local CanBeAdded = true

				-- Make sure every ancestor can be seen
				for _, Ancestor in Ancestry do
					if not self.IsItemIndexable(Ancestor) then
						CanBeAdded = false
					end
				end

				-- If valid, add the item
				if CanBeAdded then

					if FlippedOrder[Parent] or Parent == self.props.Scope then
						-- If the parent already got added, append it to it
						local Order = if Parent == self.props.Scope then nil
							else FlippedOrder[Parent] + #Parent:GetChildren()

						self:BuildItemState(Item, self.props.Scope, Order, Changes, State)

						if Children[Item] then
							HandleChildren(Item, Order)
						end
					end
				end
			else
				-- Get the item's index inside State.Items
				local ItemId = IdMap[Item]

				local Parent = ItemsToRemove[Item]

				-- Clear state
				Changes[ItemId] = Support.Blank

				-- Clear ID
				IdMap[Item] = nil

				-- Clear order
				table.remove( self.ItemOrder, FlippedOrder[Item] )

				-- Clean up resources
				self.ItemMaid[ItemId]:Destroy()
				self.ItemMaid[ItemId] = nil

				-- Update parent child counter
				local ParentId = Parent and self.IdMap[Parent]
				local ParentState = self:GetStagedItemState(ParentId, Changes, State)
				if ParentState then
					ParentState.Children[ItemId] = nil
					ParentState.Unlocked[ItemId] = nil
					ParentState.IsLocked = next(ParentState.Children) and not next(ParentState.Unlocked)
					Changes[ParentId] = ParentState
					self:PropagateLock(ParentState, Changes, State)
				end
			end
		end

		-- Update state
		return { Items = Support.MergeWithBlanks(State.Items, Changes) }
	end)

end

function Explorer:UpdateTree()

	-- Check if queue should be executed
	if not self:ShouldExecuteQueue('Tree') then
		return
	end

	-- Track order of each item
	local OrderCounter = 1
	local ItemsChanged = 0
	local IdMap = self.IdMap

	-- Perform update to state
	self:setState(function (State)
		local FormerItemOrder = Support.FlipTable(self.ItemOrder)
		
		table.clear(self.ItemOrder)
		
		local Changes = {}
		local Descendants = Options.GetIndexableItemsFunction(self.props.Scope, self.props.BTCore)
		local DescendantMap = Support.FlipTable(Descendants)

		-- Check all items in scope
		for Index, Item in ipairs(Descendants) do
			local ItemId = IdMap[Item]
			local ItemState = ItemId and State.Items[ItemId]

			-- Update reordered items
			if ItemState then
				--[[
                if ItemState.Order ~= OrderCounter then
                    ItemState = Support.CloneTable(ItemState)
                    ItemState.Order = OrderCounter
                    Changes[ItemId] = ItemState
                end
                OrderCounter = OrderCounter + 1]]
				
				-- Update parents in case scope changed
				local ParentId = self.IdMap[ItemState.Parent]
				
				table.insert(self.ItemOrder, Item)
				
				if not State.Items[ParentId] then
					self:UpdateItemParent(Item, Changes, State)
				end

				-- Introduce new items
			elseif self:BuildItemState(Item, self.props.Scope, nil, Changes, State) then
				ItemsChanged += 1
			end

			OrderCounter += 1

			if ItemsChanged >= 500 then
				ItemsChanged = 0
				task.wait(0.01)
			end
		end

		-- Remove old items from state
		local ObjectsToRemove = {}
		
		for ItemId, Item in next, State.Items do
			local Object = Item.Instance

			if not DescendantMap[Object] then
				ItemsChanged += 1

				-- Clear state
				Changes[ItemId] = Support.Blank

				-- Clear ID
				IdMap[Object] = nil

				-- Clean up resources
				self.ItemMaid[ItemId]:Destroy()
				self.ItemMaid[ItemId] = nil

				-- Update parent child counter
				local ParentId = Item.Parent and self.IdMap[Item.Parent]
				local ParentState = self:GetStagedItemState(ParentId, Changes, State)
				if ParentState then
					ParentState.Children[ItemId] = nil
					ParentState.Unlocked[ItemId] = nil
					ParentState.IsLocked = next(ParentState.Children) and not next(ParentState.Unlocked)
					Changes[ParentId] = ParentState
					self:PropagateLock(ParentState, Changes, State)
				end

				if ItemsChanged >= 500 then
					ItemsChanged = 0
					task.wait(0.01)
				end
			end
		end
		
		-- Update state
		return { Items = Support.MergeWithBlanks(State.Items, Changes) }
	end)
end

function Explorer:UpdateSelection(Items)
	local Selection = self.props.BTCore.Selection

	-- Queue changed items
	self:QueueUpdate('Selection', Items)

	-- Check if queue should be executed
	if not self:ShouldExecuteQueue('Selection') then
		return
	end

	-- Perform updates to state
	self:setState(function (State)
		local Changes = {}
		local Queue = self:GetUpdateQueue('Selection')

		if not Queue then
			return
		end

		for Items in pairs(Queue) do
			for _, Item in ipairs(Items) do
				local ItemId = self.IdMap[Item]
				if ItemId then
					local ItemState = Support.CloneTable(State.Items[ItemId])
					ItemState.Selected = Selection.IsSelected(Item)
					Changes[ItemId] = ItemState
				end
			end
		end

		return { Items = Support.Merge(State.Items, Changes) }
	end)

end

function Explorer:BuildItemState(Item, Scope, Order, Changes, State)
	local Parent = Item.Parent
	local ParentId = self.IdMap[Parent]

	-- Check if indexable and visible in hierarchy
	local InHierarchy = ParentId or (Parent == Scope)
	if not InHierarchy then
		return nil
	end

	-- Assign ID
	local ItemId = self.LastId + 1
	self.LastId = ItemId
	self.IdMap[Item] = ItemId

	-- Check if item is a part
	local IsPart = Item:IsA 'BasePart'

	-- Create maid for cleanup when item is removed
	local ItemMaid = Maid.new()
	self.ItemMaid[ItemId] = ItemMaid

	-- Prepare item state
	local ItemState = {
		Id = ItemId,
		Name = Item.Name,

		-- CustomName is basically if you want to display something else.

		CustomName = Options.CustomNameFunction(Item, game.Players.LocalPlayer),
		IsPart = IsPart,
		IsLocked = IsPart and Item.Locked == true or IsPart and (not Options.CheckPermission(Item, game.Players.LocalPlayer)) or false,
		Class = Item.ClassName,
		Parent = Parent,
		Children = {},
		Unlocked = {},
		Expanded = nil,
		Instance = Item,
		Selected = self.props.BTCore.Selection.IsSelected(Item) or nil
	}

	if Order then
		table.insert(self.ItemOrder, Order, Item)
	else
		table.insert(self.ItemOrder, Item)
	end

	-- Register item state into changes
	Changes[ItemId] = ItemState

	-- Update parent children
	local ParentState = self:GetStagedItemState(ParentId, Changes, State)
	if ParentState then
		ParentState.Children[ItemId] = true
		Changes[ParentId] = ParentState
	end

	-- Update children
	for PendingChildId in pairs(self.PendingParent[Item] or {}) do
		local ChildState = self:GetStagedItemState(PendingChildId, Changes, State)
		if ChildState then
			ItemState.Children[PendingChildId] = true
			self:PropagateLock(ChildState, Changes, State)
		end
	end

	-- Propagate lock to ancestors
	self:PropagateLock(ItemState, Changes, State)

	-- Listen to name changes
	ItemMaid.Name = Item:GetPropertyChangedSignal('Name'):Connect(function ()

		-- Queue change
		self:QueueUpdate('Name', Item)

		-- Check if queue should be executed
		if not self:ShouldExecuteQueue('Name') then
			return
		end

		-- Perform updates to state
		self:setState(function (State)
			local Changes = {}
			local Queue = self:GetUpdateQueue('Name')
			for Item in pairs(Queue) do
				local ItemId = self.IdMap[Item]
				local ItemState = Support.CloneTable(State.Items[ItemId])
				ItemState.Name = Item.Name
				ItemState.CustomName = Item.Name
				Changes[ItemId] = ItemState
			end
			return { Items = Support.Merge(State.Items, Changes) }
		end)

	end)

	-- Listen to parent changes
	ItemMaid.Parent = Item:GetPropertyChangedSignal('Parent'):Connect(function ()
		if not Item.Parent then
			return
		end

		-- Queue change
		self:QueueUpdate('Parent', Item)

		-- Check if queue should be executed
		if not self:ShouldExecuteQueue('Parent') then
			return
		end

		-- Perform updates to state
		self:setState(function (State)
			local Changes = {}
			local Queue = self:GetUpdateQueue('Parent')
			for Item in pairs(Queue) do
				self:UpdateItemParent(Item, Changes, State)
			end
			return { Items = Support.MergeWithBlanks(State.Items, Changes) }
		end)

		-- Update tree state
		self:UpdateTree()
	end)

	-- Attach part-specific listeners
	if IsPart then
		ItemMaid.Locked = Item:GetPropertyChangedSignal('Locked'):Connect(function ()

			-- Queue change
			self:QueueUpdate('Lock', Item)

			-- Check if queue should be executed
			if not self:ShouldExecuteQueue('Lock') then
				return
			end

			-- Perform updates to state
			self:setState(function (State)
				local Changes = {}
				local Queue = self:GetUpdateQueue('Lock')
				for Item in pairs(Queue) do
					self:UpdateItemLock(Item, Changes, State)
				end
				return { Items = Support.MergeWithBlanks(State.Items, Changes) }
			end)

		end)
	end

	-- Indicate that item state was created
	return true

end

function Explorer:QueueUpdate(Type, Item, Value)
	self.UpdateQueues[Type] = Support.Merge(self.UpdateQueues[Type] or {}, {
		[Item] = if Value ~= nil then Value else true
	})
end

function Explorer:GetUpdateQueue(Type)

	-- Get queue
	local Queue = self.UpdateQueues[Type]
	self.UpdateQueues[Type] = nil

	-- Return queued items
	return Queue

end

function Explorer:ShouldExecuteQueue(Type)
	local ShouldExecute = self.QueueTimers[Type] or Support.CreateConsecutiveCallDeferrer()
	self.QueueTimers[Type] = ShouldExecute

	-- Wait until state updatable
	if ShouldExecute() and self.Mounted then
		return true
	end
end

function Explorer:UpdateItemLock(Item, Changes, State)

	-- Get staged item state
	local ItemId = self.IdMap[Item]
	local ItemState = self:GetStagedItemState(ItemId, Changes, State)
	if not ItemState then
		return
	end

	-- Update state
	ItemState.IsLocked = Item.Locked
	Changes[ItemId] = ItemState

	-- Propagate lock state up hierarchy
	self:PropagateLock(ItemState, Changes, State)

end

function Explorer:GetStagedItemState(ItemId, Changes, State)

	-- Check if item staged yet
	local StagedItemState = ItemId and Changes[ItemId]

	-- Ensure item still exists
	if not ItemId or (StagedItemState == Support.Blank) or
		not (StagedItemState or State.Items[ItemId]) then
		return
	end

	-- Return staged item state
	return StagedItemState or Support.CloneTable(State.Items[ItemId])

end

function Explorer:UpdateItemParent(Item, Changes, State)

	-- Get staged item state
	local ItemId = self.IdMap[Item]
	local ItemState = self:GetStagedItemState(ItemId, Changes, State)
	if not ItemState then
		return
	end

	-- Get current parent ID
	local PreviousParentId = ItemState.Parent and self.IdMap[ItemState.Parent]

	-- Set new parent ID
	local Parent = Item.Parent
	local ParentId = self.IdMap[Parent]
	ItemState.Parent = Parent
	Changes[ItemId] = ItemState

	-- Queue parenting if parent item valid, but not yet registered
	if not ParentId and not (Parent == Scope) then
		if Parent:IsDescendantOf(Scope) then
			self.PendingParent[Parent] = Support.Merge(self.PendingParent[Parent] or {}, { [ItemId] = true })
		end
	end

	-- Update previous parent
	local PreviousParentState = self:GetStagedItemState(PreviousParentId, Changes, State)
	if PreviousParentState then
		PreviousParentState.Children[ItemId] = nil
		PreviousParentState.Unlocked[ItemId] = nil
		PreviousParentState.IsLocked = next(PreviousParentState.Children) and not next(PreviousParentState.Unlocked)
		Changes[PreviousParentId] = PreviousParentState
		
		-- Since we're processing only one item, we can exceptionally use table.find without any issue
		table.remove( self.ItemOrder, table.find(self.ItemOrder, Item) )
	end

	-- Update new parent
	local ParentState = self:GetStagedItemState(ParentId, Changes, State)
	if ParentState then
		ParentState.Children[ItemId] = true
		Changes[ParentId] = ParentState
		table.insert(self.ItemOrder, table.find(self.ItemOrder, Parent) + #Parent:GetChildren())
		self:PropagateLock(ItemState, Changes, State)
	end

end

function Explorer:PropagateLock(ItemState, Changes, State)

	-- Continue if upward propagation is possible
	if not ItemState.Parent then
		return
	end

	-- Start propagation from changed item
	local ItemId = ItemState.Id
	local ItemState = ItemState

	-- Get item's parent state
	repeat
		local Parent = ItemState.Parent
		local ParentId = Parent and self.IdMap[Parent]
		local ParentState = self:GetStagedItemState(ParentId, Changes, State)
		if ParentState then

			-- Update parent lock state
			ParentState.Unlocked[ItemId] = (not ItemState.IsLocked) and true or nil
			ParentState.IsLocked = next(ParentState.Children) and not next(ParentState.Unlocked)
			Changes[ParentId] = ParentState

			-- Continue propagation upwards in the hierarchy
			ItemId = ParentId
			ItemState = ParentState

			-- Stop propagation if parent being removed
		else
			ItemId = nil
			ItemState = nil
		end


		-- Stop at highest reachable point in hierarchy
	until
	not ItemState
end

function Explorer:render()
	local props = self.props
	local state = self.state

	Options = props.BTCore.Options

	-- Display window
	return new("ImageLabel", {
		--    Active = true,
		--    AnchorPoint = Vector2.new(1, 0.5),
		--	Position = UDim2.new(1, -130, 0.6, -380/2),
		--	Size = UDim2.new(0, 145, 0, 0),
		Size = UDim2.new(),
		AutomaticSize = Enum.AutomaticSize.Y,
		RBXTAG_Explorer = true,
		--	Height = 'WRAP_CONTENT',
		--	RBXTAG_Explorer = true
		--    Image = 'rbxassetid://2244248341',
		--     ScaleType = 'Slice',
		--    SliceCenter = Rect.new(4, 4, 12, 12),
		--    ImageTransparency = 1 - 0.4, -- 0.93
		--	ImageColor3 = Color3.new(0, 0, 0) -- 3B3B3B
		[Roact.Ref] = function(rbx)
			if rbx then
				rbx.Size = UDim2.new(0, 0, 0, 1)
				task.wait()
				rbx.Size = UDim2.new(0, 0, 0, 0)
			end
		end,
	},
	{
		Layout = new('UIListLayout', {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 0),
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			SortOrder = Enum.SortOrder.LayoutOrder,
			--Wraps = true
		}),

		-- Window header
		Header = new("TextButton", {
			--	Text = '<font family="rbxassetid://12187365977">  EXPLORER</font>',
			--	Font = Enum.Font.Montserrat,
			--	RichText = true,
			--    TextSize = 9,
			--    Height = UDim.new(0, 14),
			--    TextColor = 'FFFFFF',
			--    TextTransparency = 1 - 0.6/2
			LayoutOrder = 1,
			RBXTAG_Native = true;	
			[Roact.Event.MouseButton1Down] = function (rbx)
				local Dock: ImageLabel = rbx.Parent
				local InitialAbsolutePosition = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
				local InitialPosition = Dock:GetStyled("Position")

				self.DockDragging = UserInputService.InputChanged:Connect(function (Input)
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

				self.DockDraggingEnd = UserInputService.InputEnded:Connect(function (Input)
					if (Input.UserInputType.Name == 'MouseButton1') or (Input.UserInputType.Name == 'Touch') then
						self.DockDragging:Disconnect()
						self.DockDraggingEnd:Disconnect()
						self.DockDragging = nil
						self.DockDraggingEnd = nil
						rbx.Active = true
					end
				end)
			end;
		},

		{
			CloseButton = new("ImageButton", {
				--	Image = 'rbxassetid://2244452978',
				--	ImageRectOffset = Vector2.new(0, 0),
				--	ImageRectSize = Vector2.new(14, 14) * 2,
				--	AspectRatio = 1,
				--	AnchorPoint = Vector2.new(1, 0.5),
				--	Position = UDim2.new(1, 0, 0.5, 0),
				--	ImageTransparency = 1 - 0.34,
				RBXTAG_Native = true;
				[Roact.Event.Activated] = props.Close
			})
		}),

		SearchBox = new("Frame", {
			--	Text = '<font family="rbxassetid://12187365977">  EXPLORER</font>',
			--	Font = Enum.Font.Montserrat,
			--	RichText = true,
			--    TextSize = 9,
			--    Height = UDim.new(0, 14),
			--    TextColor = 'FFFFFF',
			--    TextTransparency = 1 - 0.6/2
			LayoutOrder = 2,
			RBXTAG_Native = true;	
		},

		{
			SearchInput = new("TextBox", {
				--	Image = 'rbxassetid://2244452978',
				--	ImageRectOffset = Vector2.new(0, 0),
				--	ImageRectSize = Vector2.new(14, 14) * 2,
				--	AspectRatio = 1,
				--	AnchorPoint = Vector2.new(1, 0.5),
				--	Position = UDim2.new(1, 0, 0.5, 0),
				--	ImageTransparency = 1 - 0.34,
				Text = "";
				RBXTAG_Native = true;
				[Roact.Event.FocusLost] = function(rbx)
					if rbx then
						self:setState({
							SearchText = rbx.Text ~= "" and rbx.Text or Roact.None
						})
					end
				end
			})
		}),

		-- Scrollable item list
		ItemList = new(ItemList, {
			Scope = props.Scope,
			Items = state.Items,
			ScrollTo = state.ScrollTo,
			BTCore = props.BTCore,
			IdMap = self.IdMap,
			Order = self.ItemOrder,
			RowHeight = state.RowHeight,
			ToggleExpand = self.ToggleExpand,
			SearchText = self.state.SearchText,
			RevertToOldPosition = props.RevertToOldPosition
		})
	},  script.Name, self)
end

return Explorer