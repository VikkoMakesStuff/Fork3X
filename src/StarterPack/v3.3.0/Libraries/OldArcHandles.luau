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
local ArcHandles = {}
ArcHandles.__index = ArcHandles

-- Mapping side handles to axes
ArcHandles.SideToAxis = {
	Top = 'Z',
	Bottom = 'Z',
	Left = 'Y',
	Right = 'Y',
	Front = 'X',
	Back = 'X'
}
ArcHandles.AxisToSide = {
	X = 'Front',
	Y = 'Right',
	Z = 'Top'
}

-- Colors for axis circles
ArcHandles.AxisColors = {
	X = Color3.new(1, 0, 0),
	Y = Color3.new(0, 1, 0),
	Z = Color3.new(0, 0, 1)
}

-- Number of lines used to draw axis circles
ArcHandles.CircleSlices = 60

function ArcHandles.new(Options)
	local self = setmetatable({}, ArcHandles)

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
	self:CreateCircles()
	self:CreateHandles(Options)

	-- Get camera and viewport information
	self.Camera = Workspace.CurrentCamera
	self.GuiInset = -GuiService:GetInsetArea(Enum.ScreenInsets.None).Min
	
	-- Get list of ignorable handle obstacles
	self.ObstacleBlacklistIndex = Support.FlipTable(Options.ObstacleBlacklist or {})
	self.ObstacleBlacklist = Support.Keys(self.ObstacleBlacklistIndex)

	-- Enable handles
	self:SetAdornee(Options.Adornee)
	self.Gui.Parent = Options.Parent

	-- Return new handles
	return self
end

function ArcHandles:CreateCircles()

	-- Create folder to contain circles
	local CircleFolder = Instance.new('Folder')
	CircleFolder.Name = 'AxisCircles'
	CircleFolder.Parent = self.Gui
	local Circles = {}
	self.AxisCircles = Circles

	-- Determine angle for each circle slice
	local CircleSliceAngle = 2 * math.pi / self.CircleSlices

	-- Set up each axis
	for _, Axis in ipairs(Enum.Axis:GetEnumItems()) do
		local AxisColor = self.AxisColors[Axis.Name]

		-- Create container for circle
		local Circle = Instance.new('Folder', CircleFolder)
		Circle.Name = Axis.Name
		local Lines = {}
		Circles[Axis.Name] = Lines

		-- Create lines for circle
		for i = 1, self.CircleSlices do
			local Line = Instance.new 'CylinderHandleAdornment'
			Line.Transparency = 0.4
			Line.Color3 = AxisColor
			Line.Radius = 0
			Line.Height = 0
			Line.Parent = Circle
			Lines[i] = Line
		end
	end

end

function ArcHandles:CreateHandles(Options)

	-- Create folder to contain handles
	local HandlesFolder = Instance.new('Folder')
	HandlesFolder.Name = 'Handles'
	HandlesFolder.Parent = self.Gui
	self.Handles = {}
	self.HandleStates = {}

	-- Generate a handle for each side
	for _, Side in ipairs(Enum.NormalId:GetEnumItems()) do

		-- Get axis information
		local Axis = self.SideToAxis[Side.Name]
		local AxisColor = self.AxisColors[Axis]

		-- Create handle
		local Handle = Instance.new('ImageButton')
		Handle.Name = Side.Name
		--		Handle.Image = 'rbxassetid://2347145012'
		--		Handle.ImageColor3 = Options.Color
		--		Handle.ImageTransparency = 0.33
		Handle.AnchorPoint = Vector2.new(0.5, 0.5)
		--		Handle.BackgroundTransparency = 1
		--		Handle.BorderSizePixel = 0
		Handle.BackgroundColor3 = AxisColor
		Handle.ImageColor3 = AxisColor
		Handle.ZIndex = 1
		Handle.Visible = false

		-- Create handle dot
		local HandleDot = Handle:Clone()
		HandleDot.Active = false
		--		HandleDot.Size = UDim2.new(0, 4, 0, 4)
		HandleDot.Position = UDim2.new(0.5, 0, 0.5, 0)
		HandleDot.Visible = true
		HandleDot.Parent = Handle
		HandleDot.ZIndex = 0

		-- Create maid for handle cleanup
		local HandleMaid = Maid.new()
		self.Maid[Side.Name] = HandleMaid

		Handle:AddTag("Handle")
		HandleDot:AddTag("Native")

		-- Add handle hover effect
		HandleMaid.HoverStart = Handle.MouseEnter:Connect(function ()
			Handle:AddTag("STATE_Hover")
			self:SetCircleTransparency(Axis, 0)
		end)
		HandleMaid.HoverEnd = Handle.MouseLeave:Connect(function ()
			Handle:RemoveTag("STATE_Hover")
			self:SetCircleTransparency(Axis, 0.4)
		end)

		local IsVR = game:GetService("VRService").VREnabled

		-- Listen for handle interactions on click
		local function StartDragging(X, Y)
			local InitialHandlePlane = self.HandleStates[Handle].PlaneNormal
			local InitialHandleCFrame = self.HandleStates[Handle].HandleCFrame
			local InitialAdorneeCFrame = self.HandleStates[Handle].AdorneeCFrame

			-- Calculate aim offset
			local AimRay = self.Camera:ViewportPointToRay(X, Y)
			local AimDistance = (InitialHandleCFrame.p - AimRay.Origin):Dot(InitialHandlePlane) / AimRay.Direction:Dot(InitialHandlePlane)
			local AimWorldPoint = (AimDistance * AimRay.Direction) + AimRay.Origin
			local InitialDragOffset = InitialAdorneeCFrame:PointToObjectSpace(AimWorldPoint)

			Handle:AddTag("STATE_Press")

			-- Run callback
			if Options.OnDragStart then
				Options.OnDragStart()
			end

			self.ProcessDragChange = function(AimScreenPoint)

				-- Calculate current aim
				local AimRay = self.Camera:ScreenPointToRay(AimScreenPoint.X, AimScreenPoint.Y)
				local AimDistance = (InitialHandleCFrame.p - AimRay.Origin):Dot(InitialHandlePlane) / AimRay.Direction:Dot(InitialHandlePlane)
				local AimWorldPoint = (AimDistance * AimRay.Direction) + AimRay.Origin
				local CurrentDragOffset = InitialAdorneeCFrame:PointToObjectSpace(AimWorldPoint)

				-- Calculate angle on dragged axis
				local DragAngle
				if Axis == 'X' then
					local InitialAngle = math.atan2(InitialDragOffset.Y, -InitialDragOffset.Z)
					DragAngle = math.atan2(CurrentDragOffset.Y, -CurrentDragOffset.Z) - InitialAngle
				elseif Axis == 'Y' then
					local InitialAngle = math.atan2(InitialDragOffset.X, InitialDragOffset.Z)
					DragAngle = math.atan2(CurrentDragOffset.X, CurrentDragOffset.Z) - InitialAngle
				elseif Axis == 'Z' then
					local InitialAngle = math.atan2(InitialDragOffset.X, InitialDragOffset.Y)
					DragAngle = math.atan2(-CurrentDragOffset.X, CurrentDragOffset.Y) - InitialAngle
				end

				-- Run drag callback
				if Options.OnDrag then
					Options.OnDrag(Axis, DragAngle)
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
		Handle.Parent = HandlesFolder
		self.Handles[Side.Name] = Handle

	end

end

function ArcHandles:Hide()

	-- Make sure handles are enabled
	if not self.Running then
		return self
	end

	-- Pause updating
	self:Pause()

	-- Hide UI
	self.Gui.Enabled = false

end

function ArcHandles:Pause()
	self.Running = false
end

local function IsFirstPerson(Camera)
	return (Camera.CFrame.p - Camera.Focus.p).magnitude <= 0.6
end

function ArcHandles:Resume()

	-- Make sure handles are disabled
	if self.Running then
		return self
	end

	-- Allow handles to run
	self.Running = true

	-- Update each handle
	for Side, Handle in pairs(self.Handles) do
		coroutine.wrap(function ()
			while self.Running do
				if self.Adornee ~= nil and ( self.Adornee.Parent ~= nil or self.Adornee:HasTag("SnapPoint") ) then
					self:UpdateHandle(Side, Handle)

					-- If a controller is being used, constantly drag the selection
					if (UserInputService.PreferredInput == Enum.PreferredInput.Gamepad or UserInputService.PreferredInput == Enum.PreferredInput.MicroGamepad)
						and self.ProcessDragChange then
						
						local Position = UserInputService:GetMouseLocation()
						
						self.ProcessDragChange( Vector2.new(Position.X + self.GuiInset.X, Position.Y) )
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

				RunService.RenderStepped:Wait()
			end
		end)()
	end

	-- Update each axis circle
	for Axis, Lines in pairs(self.AxisCircles) do
		coroutine.wrap(function ()
			while self.Running do
				self:UpdateCircle(Axis, Lines)
				RunService.RenderStepped:Wait()
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

function ArcHandles:SetAdornee(Item)
	-- Return self for chaining

	-- Save new adornee
	self.Adornee = Item
	self.IsAdorneeModel = Item and (Item:IsA 'Model') or nil

	-- Attach axis circles to adornee
	for Axis, Lines in pairs(self.AxisCircles) do
		for _, Line in ipairs(Lines) do
			if Item and Item:IsA("Attachment") then
				Line.Adornee = Item:FindFirstAncestorWhichIsA("BasePart")
			else
				Line.Adornee = Item
			end

		end
	end

	-- Resume handles
	if Item then
		self:Resume()
	else
		self:Hide()
	end

	-- Return handles for chaining
	return self

end

function ArcHandles:SetCircleTransparency(Axis, Transparency)
	for _, Line in ipairs(self.AxisCircles[Axis]) do
		Line.Transparency = Transparency
	end
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

function ArcHandles:BlacklistObstacle(Obstacle)
	if Obstacle then
		self.ObstacleBlacklistIndex[Obstacle] = true
		self.ObstacleBlacklist = Support.Keys(self.ObstacleBlacklistIndex)
	end
end

local BTOverlapParams = RaycastParams.new()
BTOverlapParams.FilterType = Enum.RaycastFilterType.Exclude

function ArcHandles:UpdateHandle(Side, Handle)
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

	-- Calculate radius of adornee extents
	local ViewportPoint, CameraDepth, Visible = WorldToViewportPoint(Camera, AdorneeCFrame.p)
	local StudWidth = 2 * math.tan(math.rad(Camera.FieldOfView) / 2) * CameraDepth
	local StudsPerPixel = StudWidth / Camera.ViewportSize.X
	local HandlePadding = math.max(1, StudsPerPixel * 14) * (self.IsMouseAvailable and 1 or 1.6)
	local AdorneeRadius = AdorneeSize.magnitude / 2
	local Radius = AdorneeRadius + 2 * HandlePadding

	-- Calculate CFrame of the handle's side
	local SideUnitVector = Vector3.FromNormalId(Side)
	local HandleCFrame = AdorneeCFrame * CFrame.new(Radius * SideUnitVector)
	local AxisCFrame = AdorneeCFrame * Vector3.FromAxis(self.SideToAxis[Side])
	local HandleNormal = (AxisCFrame - AdorneeCFrame.p).unit

	-- Get viewport position of adornee and the side the handle will be on
	local HandleViewportPoint, HandleCameraDepth, HandleVisible = WorldToViewportPoint(Camera, HandleCFrame.p)

	-- Display handle if side is visible to the camera
	Handle.Visible = HandleVisible

	-- Calculate handle size (12 px, or at least 0.5 studs)
	local StudWidth = 2 * math.tan(math.rad(Camera.FieldOfView) / 2) * HandleCameraDepth
	local PixelsPerStud = Camera.ViewportSize.X / StudWidth
	local HandleSize = math.max(12, 0.5 * PixelsPerStud) * (self.IsMouseAvailable and 1 or 1.6)
	Handle.Size = UDim2.new(0, HandleSize, 0, HandleSize)

	-- Calculate where handles will appear on the screen
	Handle.Position = UDim2.new(
		0, HandleViewportPoint.X,
		0, HandleViewportPoint.Y
	)

	-- Save handle position
	local HandleState = self.HandleStates[Handle] or {}
	self.HandleStates[Handle] = HandleState
	HandleState.HandleCFrame = HandleCFrame
	HandleState.PlaneNormal = HandleNormal
	HandleState.AdorneeCFrame = AdorneeCFrame

	-- Hide handles if obscured by a non-blacklisted part
	local HandleRay = Camera:ViewportPointToRay(HandleViewportPoint.X, HandleViewportPoint.Y)
	--local TargetRay = Ray.new(HandleRay.Origin, HandleRay.Direction * (HandleCameraDepth - 0.25))

	BTOverlapParams.FilterDescendantsInstances = self.ObstacleBlacklist

	local TargetRay = workspace:Raycast(HandleRay.Origin, HandleRay.Direction * (HandleCameraDepth - 0.25), BTOverlapParams)

	if TargetRay and not Handle:HasTag("STATE_Invisible") then
		Handle:AddTag("STATE_Invisible")
		--Handle.ImageTransparency = 1
	elseif not TargetRay and Handle:HasTag("STATE_Invisible") then
		Handle:RemoveTag("STATE_Invisible")
	end
end

function ArcHandles:UpdateCircle(Axis, Lines)

	local Camera = self.Camera

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

	-- Get circle information
	local AxisVector = Vector3.FromAxis(Axis)
	local CircleVector = Vector3.FromNormalId(self.AxisToSide[Axis])

	-- Determine circle radius
	local ViewportPoint, CameraDepth, Visible = WorldToViewportPoint(Camera, AdorneeCFrame.p)
	local StudWidth = 2 * math.tan(math.rad(Camera.FieldOfView) / 2) * CameraDepth
	local StudsPerPixel = StudWidth / Camera.ViewportSize.X
	local HandlePadding = math.max(1, StudsPerPixel * 14) * (self.IsMouseAvailable and 1 or 1.6)
	local AdorneeRadius = AdorneeSize.magnitude / 2
	local Radius = AdorneeRadius + 2 * HandlePadding

	-- Determine angle of each circle slice
	local Angle = 2 * math.pi / #Lines

	-- Circle thickness (px)
	local Thickness = 1.5

	-- Redraw lines for circle
	for i, Line in ipairs(Lines) do

		-- Calculate arc's endpoints
		local From = CFrame.fromAxisAngle(AxisVector, Angle * (i - 1)) *
			(CircleVector * Radius)
		local To = CFrame.fromAxisAngle(AxisVector, Angle * i) *
			(CircleVector * Radius)
		local Center = From:Lerp(To, 0.5)

		-- Determine thickness of line (in studs)
		local ViewportPoint, CameraDepth, Visible = WorldToViewportPoint(Camera, AdorneeCFrame * Center)
		local StudWidth = 2 * math.tan(math.rad(Camera.FieldOfView) / 2) * CameraDepth
		local StudsPerPixel = StudWidth / Camera.ViewportSize.X
		Line.Radius = Thickness * StudsPerPixel / 2

		-- Position line between the endpoints
		if self.Adornee:IsA("Attachment") then
			Line.CFrame = self.Adornee.CFrame * CFrame.new(Center, To) *
				CFrame.new(0, 0, Line.Radius / 2)
		else
			Line.CFrame = CFrame.new(Center, To) *
				CFrame.new(0, 0, Line.Radius / 2)
		end



		-- Make line span between endpoints
		Line.Height = (To - From).magnitude

	end
end
function ArcHandles:Destroy()

	-- Pause updating
	self.Running = nil

	-- Clean up resources
	self.Maid:Destroy()

end

return ArcHandles