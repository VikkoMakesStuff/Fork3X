local RunService = game:GetService 'RunService'
local Workspace = game:GetService 'Workspace'
local Players = game:GetService 'Players'
local ContextActionService = game:GetService 'ContextActionService'
local UserInputService = game:GetService 'UserInputService'
local GuiService = game:GetService 'GuiService'

-- Libraries
local Maid = require(script.Parent:WaitForChild 'Maid')
local Support = require(script.Parent:WaitForChild 'SupportLibrary')

-- Create class
local Handles = {}
Handles.__index = Handles

function Handles.new(Options)
	local self = setmetatable({}, Handles)

	-- Create maid for cleanup on destroyal
	self.Maid = Maid.new()
	
	local IsVR = game:GetService("VRService").VREnabled
	
	-- Create UI container
	if IsVR then
		local Gui = Instance.new('SurfaceGui')
		self.Gui = Gui
		Gui.Name = 'BTHandles'
		Gui.Face = Enum.NormalId.Back
		Gui.LightInfluence = 0
		Gui.ResetOnSpawn = false
		Gui.MaxDistance = 1000
		Gui.AlwaysOnTop = true
		Gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		Gui.CanvasSize = Workspace.CurrentCamera.ViewportSize

		local Surface = Instance.new("Part")
		Surface.CanCollide = false
		Surface.CanQuery = false
		Surface.CanTouch = false
		Surface.AudioCanCollide = false
		Surface.Transparency = 1
		Surface.Size = vector.zero
		Surface.Parent = Workspace.CurrentCamera

		Gui.Adornee = Surface

		self.Surface = Surface
		self.Maid.Gui = Gui
	else
		local Gui = Instance.new('ScreenGui')
		self.Gui = Gui
		Gui.Name = 'BTHandles'
		Gui.IgnoreGuiInset = true
		self.Maid.Gui = Gui
	end

	-- Create interface
	self.IsMouseAvailable = UserInputService.MouseEnabled and not IsVR

	self:CreateHandles(Options)

	-- Get camera and viewport information
	self.Camera = Workspace.CurrentCamera
	self.GuiInset = -GuiService:GetInsetArea(Enum.ScreenInsets.None).Min

	-- Get list of ignorable handle obstacles
	self.ObstacleBlacklistIndex = Support.FlipTable(Options.ObstacleBlacklist or {})
	self.ObstacleBlacklist = Support.Keys(self.ObstacleBlacklistIndex)

	-- Enable handle
	self:SetAdornee(Options.Adornee)
	self.Gui.Parent = Options.Parent

	-- Return new handles
	return self
end

function Handles:CreateHandles(Options)
	self.Handles = {}
	self.HandleStates = {}

	-- Generate a handle for each side
	for _, Side in ipairs(Enum.NormalId:GetEnumItems()) do

		-- Create handle
		local Handle = Instance.new('ImageButton')
		Handle.Name = Side.Name
		Handle.AnchorPoint = Vector2.new(0.5, 0.5)
		Handle.ZIndex = 2
		Handle.ImageTransparency = 1
		Handle.BackgroundTransparency = 1
		Handle.Visible = false
		Handle.Interactable = true
		Handle.Selectable = false
		
		-- Create image
		local HandleImage = Instance.new('ImageButton')
		HandleImage.Name = "HandleImage"
		HandleImage.Position = UDim2.fromScale(0.5, 0.5)
		HandleImage.AnchorPoint = Vector2.new(0.5, 0.5)
		HandleImage.ZIndex = 1
		HandleImage.Visible = true
		HandleImage.Interactable = false
		HandleImage.Selectable = false
		HandleImage.Parent = Handle
		
		-- Create handle dot
		local HandleDot = Instance.fromExisting(HandleImage)
		HandleDot.Active = false
		HandleDot.Name = Side.Name
		--		HandleDot.Size = UDim2.new(0, 4, 0, 4)
		HandleDot.Position = UDim2.new(0.5, 0, 0.5, 0)
		HandleDot.Visible = true
		HandleDot.Parent = HandleImage
		HandleDot.ZIndex = 0

		HandleImage:AddTag("Handle")
		HandleDot:AddTag("Native")

		-- Create maid for handle cleanup
		local HandleMaid = Maid.new()
		self.Maid[Side.Name] = HandleMaid
		
		-- Add handle hover effect
		HandleMaid.HoverStart = Handle.MouseEnter:Connect(function ()
			HandleImage:AddTag("STATE_Hover")
		end)
		HandleMaid.HoverEnd = Handle.MouseLeave:Connect(function ()
			HandleImage:RemoveTag("STATE_Hover")
		end)
		
		local IsVR = game:GetService("VRService").VREnabled
		
		local function StartDragging(X, Y)
			local HandleState = self.HandleStates[Handle]
			local HandlePlane = HandleState.PlaneNormal
			local HandleNormal = HandleState.HandleNormal
			local HandleWorldPoint = HandleState.HandleCFrame.Position
			local HandleAxisLine = (HandleState.HandleViewportPosition - HandleState.AdorneeViewportPosition).Unit

			-- Project viewport aim point onto 2D handle axis line
			local AimAdorneeViewportOffset = Vector2.new(X, Y) - HandleState.AdorneeViewportPosition
			local MappedViewportPointOnAxis = HandleAxisLine:Dot(AimAdorneeViewportOffset) * HandleAxisLine +
				HandleState.AdorneeViewportPosition

			-- Map projected viewport aim point onto 3D handle axis line
			local AimRay = self.Camera:ViewportPointToRay(MappedViewportPointOnAxis.X, MappedViewportPointOnAxis.Y)
			local AimDistance = (HandleWorldPoint - AimRay.Origin):Dot(HandlePlane) / AimRay.Direction:Dot(HandlePlane)
			local AimWorldPoint = (AimDistance * AimRay.Direction) + AimRay.Origin

			-- Calculate dragging distance offset
			local DragDistanceOffset = HandleNormal:Dot(AimWorldPoint - HandleWorldPoint)

			-- Run drag start callback
			if Options.OnDragStart then
				Options.OnDragStart()
			end

			self.ProcessDragChange = function(AimScreenPoint)
				local HandleAxisLine = (HandleState.HandleViewportPosition - HandleState.AdorneeViewportPosition).Unit

				-- Project screen aim point onto 2D handle axis line
				local AdorneeScreenPosition = HandleState.AdorneeViewportPosition - self.GuiInset
				local AimAdorneeScreenOffset = Vector2.new(AimScreenPoint.X, AimScreenPoint.Y) - AdorneeScreenPosition
				local MappedScreenPointOnAxis = HandleAxisLine:Dot(AimAdorneeScreenOffset) * HandleAxisLine +
					AdorneeScreenPosition

				-- Map projected screen aim point onto 3D handle axis line
				local AimRay = self.Camera:ScreenPointToRay(MappedScreenPointOnAxis.X, MappedScreenPointOnAxis.Y)
				local AimDistance = (HandleWorldPoint - AimRay.Origin):Dot(HandlePlane) / AimRay.Direction:Dot(HandlePlane)
				local AimWorldPoint = (AimDistance * AimRay.Direction) + AimRay.Origin

				-- Calculate distance dragged
				local DragDistance = HandleNormal:Dot(AimWorldPoint - HandleWorldPoint) - DragDistanceOffset

				-- Run drag step callback
				if Options.OnDrag then
					Options.OnDrag(Side, DragDistance)
				end

			end

			-- Create maid for dragging cleanup
			local DragMaid = Maid.new()
			HandleMaid.Dragging = DragMaid

			-- Perform dragging when aiming anywhere (except handle)
			if UserInputService.PreferredInput ~= Enum.PreferredInput.Gamepad then
				DragMaid.Drag = Support.AddUserInputListener('Changed', {'MouseMovement', 'Touch'}, true, function (Input)
					self.ProcessDragChange( Vector2.new(Input.Position.X + self.GuiInset.X, Input.Position.Y) )
				end)

				-- Perform dragging while aiming at handle
				DragMaid.InHandleDrag = Handle.MouseMoved:Connect(function (X, Y)
					local AimScreenPoint = Vector2.new(X, Y + self.GuiInset.Y)

					self.ProcessDragChange(AimScreenPoint)
				end)

			end

			-- Finish dragging when input ends
			DragMaid.DragEnd = Support.AddUserInputListener('Ended', {'MouseButton1', 'Touch', 'ButtonR2', 'ButtonA'}, true, function (Input)
				self.ProcessDragChange = nil
				HandleMaid.Dragging = nil
			end)

			-- Fire callback when dragging ends
			DragMaid.Callback = function ()
				coroutine.wrap(Options.OnDragEnd)()
			end
		end
		
		-- Listen for handle interactions on click
		HandleMaid.DragStart = Handle.MouseButton1Down:Connect(StartDragging)
		
		HandleMaid.VRDragListening = IsVR and Handle.InputChanged:Connect(function(InputObject)
			if self.ProcessDragChange ~= nil then
				return
			end
			
			if InputObject.UserInputType == Enum.UserInputType.MouseMovement
				and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				
				StartDragging(InputObject.Position.X, InputObject.Position.Y)
			end
		end) or nil

		-- Finish dragging when input ends while aiming at handle
		HandleMaid.InHandleDragEnd = Handle.MouseButton1Up:Connect(function ()
			self.ProcessDragChange = nil
			HandleMaid.Dragging = nil
		end)

		-- Save handle
		Handle.Parent = self.Gui
		self.Handles[Side.Name] = Handle

	end

end

function Handles:Hide()

	-- Make sure handles are enabled
	if not self.Running then
		return self
	end

	-- Pause updating
	self:Pause()

	-- Hide UI
	self.Gui.Enabled = false

end

function Handles:Pause()
	self.Running = false
end

local function IsFirstPerson(Camera)
	return (Camera.CFrame.p - Camera.Focus.p).magnitude <= 0.6
end

function Handles:Resume()

	-- Make sure handles are disabled
	if self.Running then
		return self
	end

	-- Allow handles to run
	self.Running = true

	-- Keep handle positions updated
	for Side, Handle in pairs(self.Handles) do
		local UnitVector = Vector3.FromNormalId(Side)
		coroutine.wrap(function ()
			while self.Running do
				if self.Adornee ~= nil and self.Adornee.Parent ~= nil then
					self:UpdateHandle(Handle, UnitVector)
					
					-- If a controller is being used, constantly drag the selection
					if (UserInputService.PreferredInput == Enum.PreferredInput.Gamepad or UserInputService.PreferredInput == Enum.PreferredInput.MicroGamepad)
						and self.ProcessDragChange then
						-- + self.GuiInset 
						self.ProcessDragChange( UserInputService:GetMouseLocation() - self.GuiInset )
					end
					
					if self.Surface then
						local FakeScreenDepth = 10
						
						local FieldOfView = self.Camera.FieldOfView
						local ScreenSize = self.Camera.ViewportSize
						
						local ScreenAspectRatio = ScreenSize.X / ScreenSize.Y
						
						local HeightFactor = math.tan( math.rad(FieldOfView) / 2 )
						local WidthFactor = ScreenAspectRatio * HeightFactor
						
						local PhysicalXSize = FakeScreenDepth * 2 * WidthFactor
						local PhysicalYSize = FakeScreenDepth * 2 * HeightFactor
						
						if self.Surface.Parent ~= self.Camera then
							self.Surface.Parent = self.Camera
						end
						
						self.Surface.CFrame = self.Camera.CFrame 
							* game:GetService("VRService"):GetUserCFrame(Enum.UserCFrame.Head) 
							* CFrame.new(0, 0, -FakeScreenDepth * self.Camera.HeadScale)
						
						self.Surface.Size = Vector3.new(
							PhysicalXSize,
							PhysicalYSize,
							1
						) * self.Camera.HeadScale
					end
				else
					self:Destroy()
				end
				
				RunService.PreRender:Wait()
			end
		end)()
	end

	-- Ignore character whenever character enters first person
	if Players.LocalPlayer then
		coroutine.wrap(function ()
			while self.Running do
				local FirstPerson = IsFirstPerson(self.Camera)
				local Character = Players.LocalPlayer.Character
				if Character then
					self.ObstacleBlacklistIndex[Character] = FirstPerson and true or nil
					self.ObstacleBlacklist = Support.Keys(self.ObstacleBlacklistIndex)
				end
				wait(0.2)
			end
		end)()
	end

	-- Show UI
	self.Gui.Enabled = true

end

function Handles:SetAdornee(Item)
	-- Return self for chaining

	-- Save new adornee	
	self.Adornee = Item
	self.IsAdorneeModel = Item and (Item:IsA 'Model') or nil

	-- Resume handles
	if Item then
		self:Resume()
	else
		self:Hide()
	end

	-- Return handles for chaining
	return self

end

local function WorldToViewportPoint(Camera, Position)

	-- Get viewport position for point
	local ViewportPoint, Visible = Camera:WorldToViewportPoint(Position)
	local CameraDepth = ViewportPoint.Z
	ViewportPoint = Vector2.new(ViewportPoint.X, ViewportPoint.Y)

	-- Adjust position if point is behind camera
	if CameraDepth < 0 then
		ViewportPoint = Camera.ViewportSize - ViewportPoint
	end

	-- Return point and visibility
	return ViewportPoint, CameraDepth, Visible

end

function Handles:BlacklistObstacle(Obstacle)
	if Obstacle then
		self.ObstacleBlacklistIndex[Obstacle] = true
		self.ObstacleBlacklist = Support.Keys(self.ObstacleBlacklistIndex)
	end
end

local BTOverlapParams = RaycastParams.new()

function Handles:UpdateHandle(Handle, SideUnitVector)
	local Camera = self.Camera

	-- Hide handles if not attached to an adornee
	if not self.Adornee then
		Handle.Visible = false
		return
	end

	-- Get adornee CFrame and size
	local AdorneeCFrame = self.IsAdorneeModel and
		self.Adornee:GetModelCFrame() or
		self.Adornee:IsA("Attachment") and
		self.Adornee.WorldCFrame or
		self.Adornee.CFrame
	local AdorneeSize = self.IsAdorneeModel and
		self.Adornee:GetModelSize() or
		self.Adornee:IsA("Attachment") and
		Vector3.new(0.2, 0.2, 0.2) or
		self.Adornee.Size

	-- Calculate radius of adornee extents along axis
	local AdorneeRadius = (AdorneeSize * SideUnitVector / 2).magnitude
	local SideCFrame = AdorneeCFrame * CFrame.new(AdorneeRadius * SideUnitVector)
	local AdorneeViewportPoint, AdorneeCameraDepth = WorldToViewportPoint(Camera, SideCFrame.p)
	local StudWidth = 2 * math.tan(math.rad(Camera.FieldOfView) / 2) * AdorneeCameraDepth
	local StudsPerPixel = StudWidth / Camera.ViewportSize.X
	local HandlePadding = math.max(1, StudsPerPixel * 14) * (self.IsMouseAvailable and 1 or 1.6)
	local PaddedRadius = AdorneeRadius + 2 * HandlePadding

	-- Calculate CFrame of the handle's side
	local HandleCFrame = AdorneeCFrame * CFrame.new(PaddedRadius * SideUnitVector)
	local HandleNormal = (HandleCFrame.p - AdorneeCFrame.p).unit
	local HandleViewportPoint, HandleCameraDepth, HandleVisible = WorldToViewportPoint(Camera, HandleCFrame.p)

	-- Display handle if side is visible to the camera
	Handle.Visible = HandleVisible

	-- Calculate handle size (12 px, or at least 0.5 studs)
	local StudWidth = 2 * math.tan(math.rad(Camera.FieldOfView) / 2) * HandleCameraDepth
	local PixelsPerStud = Camera.ViewportSize.X / StudWidth
	local HandleSize = math.max(12, 0.5 * PixelsPerStud) * (self.IsMouseAvailable and 1 or 1.6)
	Handle.Size = UDim2.new(0, HandleSize, 0, HandleSize)
	
	if not self.IsMouseAvailable then
		Handle.Size += UDim2.fromOffset(6, 6)
	end
	
	Handle.HandleImage.Size = UDim2.new(0, HandleSize, 0, HandleSize)

	-- Calculate where handles will appear on the screen
	Handle.Position = UDim2.new(
		0, HandleViewportPoint.X,
		0, HandleViewportPoint.Y
	)

	-- Calculate where handles will appear in the world
	local HandlePlaneNormal = (Handle.Name == 'Top' or Handle.Name == 'Bottom') and
		AdorneeCFrame.LookVector or
		AdorneeCFrame.UpVector

	-- Save handle position
	local HandleState = self.HandleStates[Handle] or {}
	self.HandleStates[Handle] = HandleState
	HandleState.PlaneNormal = HandlePlaneNormal
	HandleState.HandleCFrame = HandleCFrame
	HandleState.HandleNormal = HandleNormal
	HandleState.AdorneeViewportPosition = AdorneeViewportPoint
	HandleState.HandleViewportPosition = HandleViewportPoint

	-- Hide handles if obscured by a non-blacklisted part
	local HandleRay = Camera:ViewportPointToRay(HandleViewportPoint.X, HandleViewportPoint.Y)
	--local TargetRay = Ray.new(HandleRay.Origin, HandleRay.Direction * (HandleCameraDepth - 0.25))
	
	BTOverlapParams.ExcludeInstances = self.ObstacleBlacklist
	
	local TargetRay = workspace:Raycast(HandleRay.Origin, HandleRay.Direction * (HandleCameraDepth - 0.25), BTOverlapParams)

	if TargetRay and not Handle.HandleImage:HasTag("STATE_Invisible") then
		Handle.HandleImage:AddTag("STATE_Invisible")
		--Handle.ImageTransparency = 1
	elseif not TargetRay and Handle.HandleImage:HasTag("STATE_Invisible") then
		Handle.HandleImage:RemoveTag("STATE_Invisible")
	end

end

function Handles:Destroy()

	-- Pause updating
	self.Running = nil

	-- Clean up resources
	self.Maid:Destroy()

end

return Handles