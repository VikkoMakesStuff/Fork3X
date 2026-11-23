local Tool = script.Parent.Parent
local Core = require(Tool.Core)
local Vendor = Tool:WaitForChild('Vendor')
local UI = Core.UIFolder
local Libraries = Core.Libraries

local Options = Core.Options

-- Services
local CollectionService = game:GetService('CollectionService')
local ContextActionService = game:GetService 'ContextActionService'

-- Libraries
local ListenForManualWindowTrigger = require(Tool.Core:WaitForChild('ListenForManualWindowTrigger'))
local Roact = require(Vendor:WaitForChild('Roact'))
local Signal = require(Libraries:WaitForChild('Signal'))

-- Import relevant references
local Selection = Core.Selection
local Support = Core.Support
local Security = Core.Security

-- Initialize the tool
local NewPartTool = {
	Name = 'New Part Tool',
	Color = BrickColor.new 'Really black',

	-- Default options
	Type = 'Normal',
	-- Signals
	OnTypeChanged = Signal.new(),
}

if table.find(Core.Options.ToolsBlacklist, NewPartTool.Name) then
	return NewPartTool
end

NewPartTool.ManualText = [[<font size="24"><b>New Part Tool  🛠</b></font>
Lets you create new parts.<font size="6"><br /></font>

<b>TIP:</b> Click and drag where you want your part to be.]]

-- Container for temporary connections (disconnected automatically)
local Connections = {}

function NewPartTool:Equip()
	-- Enables the tool's equipped functionality

	-- Start up our interface
	self:ShowUI()
	EnableClickCreation()

	-- Set our current type
	self:SetType(NewPartTool.Type)

end

function NewPartTool:Unequip()
	-- Disables the tool's equipped functionality

	-- Clear unnecessary resources
	self:HideUI()
	ClearConnections()
	ContextActionService:UnbindAction('BT: Create part')

end

function ClearConnections()
	-- Clears out temporary connections

	for ConnectionKey, Connection in pairs(Connections) do
		Connection:Disconnect()
		Connections[ConnectionKey] = nil
	end

end

function NewPartTool:ShowUI()
	UI = Core.UIFolder

	local Dropdown = require(UI:WaitForChild('Dropdown'))

	-- Creates and reveals the UI

	-- Reveal UI if already created
	if self.UI and self.UI.Parent ~= nil then

		-- Reveal the UI
		self.UI.Visible = true

		-- Skip UI creation
		return

	end

	if self.UI then
		self.UI:Destroy()
	end

	-- Create the UI
	self.UI = Core.Interfaces.BTNewPartToolGUI:Clone()
	self.UI.Parent = Core.UI
	self.UI.Visible = true

	-- Creatable part types
	local Types = {
		'Normal',
		'Truss',
		'Wedge',
		'Corner',
		'Cylinder',
		'Ball',
		'Seat',
		'Vehicle Seat',
		'Spawn',
		'Tool',
		'MeshPart'
	}

	local CustomPartTypes = type(Options.CustomPartTypes) == "function" and Options.CustomPartTypes() or Options.CustomPartTypes

	for Type, _ in CustomPartTypes do
		table.insert(Types, Type)
	end

	for _, Type in Options.InstanceBlacklist do
		local Index = table.find(Types, Type)
		if Index then
			table.remove(Types, Index)
		end
	end



	-- Create type dropdown
	local function BuildTypeDropdown()
		return Roact.createElement(Dropdown, {
			Position = UDim2.new(0, 70, 0, 0),
			Size = UDim2.new(0, 140, 0, 25),
			Options = Types,
			MaxRows = 5,
			CurrentOption = self.Type,
			OnOptionSelected = function (Option)
				self:SetType(Option)
			end,
		})
	end

	-- Mount type dropdown
	local TypeDropdownHandle = Roact.mount(BuildTypeDropdown(), self.UI.TypeOption, 'Dropdown')
	self.OnTypeChanged:Connect(function ()
		Roact.update(TypeDropdownHandle, BuildTypeDropdown())
	end)

	-- Hook up manual triggering
	local SignatureButton = self.UI:WaitForChild('Title'):WaitForChild('Signature')
	ListenForManualWindowTrigger(NewPartTool.ManualText, NewPartTool.Color.Color, SignatureButton)
end

function NewPartTool:HideUI()
	-- Hides the tool UI

	-- Make sure there's a UI
	if not self.UI then
		return
	end

	-- Hide the UI
	self.UI.Visible = false

end

function NewPartTool:SetType(Type)
	if self.Type ~= Type then
		self.Type = Type
		self.OnTypeChanged:Fire(Type)
	end
end

function EnableClickCreation()
	-- Allows the user to click anywhere and create a new part

	local function CreateAtTarget(Action, State, Input)
		-- Drag new parts
		if State.Name == 'Begin' then
			DragNewParts = true
			Core.Targeting.CancelSelecting()

			-- Create new part
			CreatePart(NewPartTool.Type)

			-- Disable dragging on release
		elseif State.Name == 'End' then
			DragNewParts = nil
		end

	end

	-- Register input handler
	ContextActionService:BindAction('BT: Create part', CreateAtTarget, false,
		Enum.UserInputType.MouseButton1,
		Enum.UserInputType.Touch
	)

end

-- Copy of the SyncModule function. If possible, returns a fake part that can be used while the actual one must be created on the server
local function CreateFakePart(PartType)
	local CustomPartTypes = type(Core.Options.CustomPartTypes) == "function" and Core.Options.CustomPartTypes() or Core.Options.CustomPartTypes

	local NewPart

	if PartType == 'Normal' then
		NewPart = Instance.new('Part')
		NewPart.Size = vector.create(4, 1, 2)

	elseif PartType == 'Truss' then
		NewPart = Instance.new('TrussPart')

	elseif PartType == 'Wedge' then
		NewPart = Instance.new('WedgePart')
		NewPart.Size = vector.create(4, 1, 2)

	elseif PartType == 'Corner' then
		NewPart = Instance.new('CornerWedgePart')
		NewPart.Size = vector.one

	elseif PartType == 'Cylinder' then
		NewPart = Instance.new('Part')
		NewPart.Shape = 'Cylinder'
		NewPart.Size = vector.create(2, 2, 2)

	elseif PartType == 'Ball' then
		NewPart = Instance.new('Part')
		NewPart.Shape = 'Ball'
		NewPart.Size = vector.one

	elseif PartType == 'Seat' then
		NewPart = Instance.new('Seat')
		NewPart.Size = vector.create(4, 1, 2)

	elseif PartType == 'Vehicle Seat' then
		NewPart = Instance.new('VehicleSeat')
		NewPart.Size = vector.create(4, 1, 2)

	elseif PartType == 'Spawn' then
		NewPart = Instance.new('SpawnLocation')
		NewPart.Size = vector.create(4, 1, 2)

	elseif PartType == 'MeshPart' then
		NewPart = Instance.new('MeshPart')
		NewPart.Size = vector.create(4, 1, 2)

		NewPart:AddTag("BT_CanModifyMeshPart")
	elseif PartType == 'Tool' then
		NewPart = Instance.new('Tool')

		local Handle = Instance.new('Part')
		Handle.Name = "Handle"
		Handle.Size = vector.one
		Handle.Parent = NewPart
		Handle.Anchored = false

		Handle.TopSurface = Enum.SurfaceType.Smooth;
		Handle.BottomSurface = Enum.SurfaceType.Smooth;
		
		Handle:AddTag("FORK3X_FakeInstance")
		NewPart:AddTag("FORK3X_FakeInstance")

		return NewPart
	elseif CustomPartTypes[PartType] then
		local Success
		
		if type(CustomPartTypes[PartType]) == "function" then
			Success, NewPart = pcall(CustomPartTypes[PartType])
			
			if NewPart then
				NewPart:AddTag("FORK3X_FakeInstance")
			end
		elseif not CustomPartTypes[PartType].ClientUnsafe then
			Success, NewPart = pcall(CustomPartTypes[PartType].Create, Core.Player)
			
			if NewPart then
				NewPart:SetAttribute("BTSubType", PartType)
				NewPart:AddTag("FORK3X_FakeInstance")
			end
			
		end
		
		if Success then
			return NewPart
		end
	end

	-- Make part surfaces smooth
	NewPart.TopSurface = Enum.SurfaceType.Smooth;
	NewPart.BottomSurface = Enum.SurfaceType.Smooth;

	-- Make sure the part is anchored
	NewPart.Anchored = true
	
	-- Mark that this is not a genuine part
	NewPart:AddTag("FORK3X_FakeInstance")

	return NewPart
end

function CreatePart(Type)
	
	local CanUseMoveTool = not table.find(Core.Options.ToolsBlacklist, "Move Tool")
	local FakePart = not Core.Plugin and CreateFakePart(Type) or nil
	
	local MoveTool = CanUseMoveTool and require(Core.Tools.Move)
	
	if FakePart then
		task.spawn(function()
			-- Get the position
			local Position = CFrame.new(Core.Mouse.Hit.p)

			-- Position the part
			if FakePart:IsA("Tool") then
				FakePart:FindFirstChild("Handle").CFrame = Position;
			elseif FakePart:IsA("Model") then
				FakePart:PivotTo(Position)
			else
				FakePart.CFrame = Position
			end

			-- Parent the part so we can check if it can be placed
			FakePart.Parent = workspace

			-- Cache up permissions for all private areas
			local AreaPermissions = Core.Security.GetPermissions( Core.Security.GetSelectionAreas({ FakePart }), Core.Player );

			-- Make sure the player is allowed to create parts in the area
			if Core.Security.ArePartsViolatingAreas( { FakePart }, Core.Player, false, AreaPermissions ) then
				-- If not allowed, destroy the new object
				FakePart:Destroy()
			else

				FakePart.Parent = Core.Targeting.Scope

				-- Select the part
				Selection.Replace({ FakePart })

				-- Switch to the move tool if it's whitelisted
				if CanUseMoveTool then
					Core.EquipTool(MoveTool)

					-- Enable dragging to allow easy positioning of the created part
					if DragNewParts then
						MoveTool.FreeDragging.IsDraggingLocalInstances = true

						MoveTool.FreeDragging:SetUpDragging(FakePart)
					end
				end
			end;
		end)
	end
	
	-- Send the creation request to the server
	local Success, Part = pcall( Core.SyncAPI.Invoke, Core.SyncAPI, 'CreatePart', Type, CFrame.new(Core.Mouse.Hit.p), Core.Targeting.Scope )
	
	if MoveTool.FreeDragging.IsDragging and MoveTool.FreeDragging.IsDraggingLocalInstances then
		MoveTool.FreeDragging:FinishDragging()
	elseif MoveTool.FreeDragging.IsDragging and not MoveTool.FreeDragging.IsDraggingLocalInstances then
		DragNewParts = nil
	end

	MoveTool.FreeDragging.IsDraggingLocalInstances = false
	MoveTool.FreeDragging.IsDragging = false

	if FakePart then
		Selection.Remove( { FakePart } )

		FakePart:Destroy()
	end

	
	if not Success then
		warn("[FORK3X]: An error occured when using the Paint Tool: " .. Part .. "\n\nIf this isn't a modified version of Fork3X, please report this error to the creator.")
		
		return
	end
	
	-- Make sure the part creation succeeds
	if not Part then
		return
	end

	-- Put together the history record
	local HistoryRecord = {
		Part = Part,

		Unapply = function (HistoryRecord)
			-- Reverts this change

			-- Remove the part
			Core.SyncAPI:Invoke('Remove', { HistoryRecord.Part })

		end,

		Apply = function (HistoryRecord)
			-- Reapplies this change

			-- Restore the part
			Core.SyncAPI:Invoke('UndoRemove', { HistoryRecord.Part })

		end,

	}

	-- Register the history record
	Core.History.Add(HistoryRecord)

	-- Select the part
	Selection.Replace({ Part })

	-- Switch to the move tool if it's whitelisted
	if CanUseMoveTool then
		Core.EquipTool(MoveTool)
		
		-- Enable dragging to allow easy positioning of the created part
		if DragNewParts then
			if FakePart then
				Part.CFrame = FakePart.CFrame
			end
			
			MoveTool.FreeDragging:SetUpDragging(Part)
		elseif FakePart then
			MoveTool:TrackChange()

			Part.CFrame = FakePart.CFrame
			
			MoveTool:RegisterChange()
		end
	end

end

-- Return the tool
return NewPartTool