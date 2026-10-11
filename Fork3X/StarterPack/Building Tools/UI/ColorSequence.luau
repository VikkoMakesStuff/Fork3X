local Root = script:FindFirstAncestorWhichIsA('Tool')
local Libraries = Root:WaitForChild('Libraries')
local Vendor = Root:WaitForChild('Vendor')
local Sounds = Root:WaitForChild("Sounds")

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

-- Libraries
local Roact = require(Vendor:WaitForChild('Roact'))
local Maid = require(Libraries:WaitForChild('Maid'))
local fastSpawn = require(Libraries:WaitForChild('fastSpawn'))

local ColorPicker = require(script.Parent:WaitForChild("ColorPicker"))

local Support = require(Libraries.SupportLibrary)

-- Roact
local new = function(Type, props, ...)
	props["RBXTAG_Native"] = true

	return Roact.createElement(Type, props, ...)
end

-- Create component
local ColorSequenceEditor = Roact.Component:extend(script.Name)

function ColorSequenceEditor:init()
	self.Maid = Maid.new()

	self.ColorSequence, self._SetColorSequence = Roact.createBinding(self.props.InitialColorSequence and self.props.InitialColorSequence.Keypoints or {
		ColorSequenceKeypoint.new( 0, Color3.new(0, 0, 0) ),
		ColorSequenceKeypoint.new( 1, Color3.new(1, 1, 1) )
	})

	self.PreviousKeypointsCount = #self.ColorSequence:getValue()

	self.InputListener = UserInputService.InputBegan:Connect(function(InputObject: InputObject, DoNotListen)
		if DoNotListen then
			return
		end

		if InputObject.KeyCode == Enum.KeyCode.Delete and self.state.CurrentKeypoint then
			self:DeleteCurrentKeypoint()
		end
	end)

	self:setState({
		GridIncrement = 0.05,
		CurrentKeypoint = Roact.None,
	})
end

function ColorSequenceEditor:didUpdate(previousProps)
	self.PreviousKeypointsCount = #self.ColorSequence:getValue()

	if previousProps.InitialColor ~= self.props.InitialColor then
		self._SetColorSequence(self.InitialColorSequence and self.ColorSequence.Keypoints or {
			ColorSequenceKeypoint.new( 0, Color3.new(0, 0, 0) ),
			ColorSequenceKeypoint.new( 1, Color3.new(1, 1, 1) )
		})
	end
end

function ColorSequenceEditor:SetColorSequence(Keypoints)
	self._SetColorSequence(Keypoints)
	if self.props.SetPreviewSequence then
		fastSpawn(function ()
			self.props.SetPreviewSequence(ColorSequence.new(Keypoints))
		end)
	end
end

function ColorSequenceEditor:DeleteCurrentKeypoint()
	local SequenceData = self.ColorSequence:getValue()

	if self.state.CurrentKeypoint == 1 or self.state.CurrentKeypoint == #SequenceData then
		return
	end

	table.remove(SequenceData, self.state.CurrentKeypoint)

	self:setState({
		CurrentKeypoint = Roact.None,
	})

	self:SetColorSequence(SequenceData)
end

function ColorSequenceEditor:Finish()
	if self.props.SetPreviewSequence then
		fastSpawn(function ()
			self.props.SetPreviewSequence(nil)
		end)
	end
	if self.props.OnConfirm then
		local Keypoints = self.ColorSequence:getValue()
		local Sequence = ColorSequence.new(Keypoints)
		fastSpawn(function ()
			self.props.OnConfirm(Sequence)
		end)
	end
end

function ColorSequenceEditor:Cancel()
	if self.props.SetPreviewSequence then
		fastSpawn(function ()
			self.props.SetPreviewSequence(nil)
		end)
	end
	if self.props.OnCancel then
		fastSpawn(function ()
			self.props.OnCancel()
		end)
	end
end

local function ModifyKeypoint(Keypoint, PropertyName, Value)
	local KeypointData = {
		Time = Keypoint.Time,
		Value = Keypoint.Value,
	}

	KeypointData[PropertyName] = Value

	return ColorSequenceKeypoint.new(KeypointData.Time, KeypointData.Value)
end

local function InvertColor(Color)
	local R = Color.R
	local G = Color.G
	local B = Color.B
	
	return Color3.new(1 - R, 1 - G, 1 - B)
end

function ColorSequenceEditor:EvaluateKeypoint(Time, Index)
	local SequenceData = self.ColorSequence:getValue()

	-- Check if any keypoint has the same time
	for KeypointIndex, Keypoint in SequenceData do
		if math.abs(Keypoint.Time - Time) <= 0.0001 and KeypointIndex ~= Index then
			return false
		end
	end

	-- Get information about the keypoint
	local IsFirst = Index == 1
	local IsLast = Index == #SequenceData

	local IsExtremity = IsFirst or IsLast

	-- Make sure the time won't cause any issue
	local TimeMinRange = if IsFirst then 0
		elseif IsLast then 1
		else self.state.GridIncrement

	local TimeMaxRange = if IsFirst then 0
		elseif IsLast then 1
		else 1 - self.state.GridIncrement

	-- Clamp the time according to the given information
	Time = math.clamp(Time, TimeMinRange, TimeMaxRange)

	return true, Time
end

local function GetIncrementMultiple(Number, Increment)

	if Increment == 0 then
		return Number
	end

	-- Get how far the actual distance is from a multiple of our increment
	local MultipleDifference = Number % Increment

	-- Identify the closest lower and upper multiples of the increment
	local LowerMultiple = Number - MultipleDifference
	local UpperMultiple = Number - MultipleDifference + Increment

	-- Calculate to which of the two multiples we're closer
	local LowerMultipleProximity = math.abs(Number - LowerMultiple)
	local UpperMultipleProximity = math.abs(Number - UpperMultiple)

	-- Use the closest multiple of our increment as the distance moved
	if LowerMultipleProximity <= UpperMultipleProximity then
		Number = LowerMultiple
	else
		Number = UpperMultiple
	end

	return Number
end

function ColorSequenceEditor:render()

	local KeypointsObjects = {}

	local SequenceData = self.ColorSequence:getValue()

	for Index, Keypoint in next, self.ColorSequence:getValue() do
		local XPosition = Keypoint.Time

		local FinalPosition = UDim2.new(XPosition, 0, 0.5, 0)
		--local 
		
		local function HandleInput(rbx)
			local MovementConnection
			local CancelConnection

			MovementConnection = UserInputService.InputChanged:Connect(function(InputObject: InputObject, DoNotListen)
				if not rbx or rbx.Parent == nil then
					MovementConnection:Disconnect()
					CancelConnection:Disconnect()
					return
				end

				if InputObject.UserInputType == Enum.UserInputType.MouseMovement
					or InputObject.UserInputType == Enum.UserInputType.Touch
					or InputObject.KeyCode == Enum.KeyCode.Thumbstick2 then

					local CurrentPosition = rbx.AbsolutePosition
					local NewPosition

					if InputObject.KeyCode == Enum.KeyCode.Thumbstick2 then
						NewPosition = CurrentPosition + Vector2.new(InputObject.Position.X, InputObject.Position.Y)
					else
						NewPosition = Vector2.new(
							InputObject.Position.X,
							InputObject.Position.Y
						)
					end

					local Parent = rbx.Parent
					local KeypointsFrame = Parent.Parent
					
					local KeypointsFrameAbsoluteSize = KeypointsFrame.AbsoluteSize
					
					local Offset = NewPosition - KeypointsFrame.AbsolutePosition

					local Time = GetIncrementMultiple(Offset.X / KeypointsFrameAbsoluteSize.X, self.state.GridIncrement)

					local Success

					Success, Time = self:EvaluateKeypoint(Time, Index)

					if not Success then
						return
					end

					Parent.Position = UDim2.fromScale(Time, 0.5)

					local NewKeypoint = ColorSequenceKeypoint.new(Time, Keypoint.Value)

					SequenceData[Index] = NewKeypoint

					table.sort(SequenceData, function(A, B)
						return A.Time < B.Time
					end)

					local NewIndex = table.find(SequenceData, NewKeypoint)

					self:setState({
						CurrentKeypoint = NewIndex
					})

					self:SetColorSequence(SequenceData)
				end
			end)

			CancelConnection = UserInputService.InputEnded:Connect(function(InputObject: InputObject, DoNotListen)

				if InputObject.UserInputType == Enum.UserInputType.MouseButton1
					or InputObject.UserInputType == Enum.UserInputType.Touch
					or InputObject.KeyCode == Enum.KeyCode.Thumbstick2 then

					if MovementConnection then
						MovementConnection:Disconnect()
					end

					if CancelConnection then
						CancelConnection:Disconnect()
					end
				end
			end)
		end
		
		local IsCurrent = self.state.CurrentKeypoint == Index
		
		KeypointsObjects[ tostring(Index) ] = new( "Frame", {
			Size = UDim2.new(0, 12, 0, 12),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = FinalPosition,
			RBXTAG_Keypoint = true,
		}, {
			Line = new( "Frame", {
				RBXTAG_STATE_IsCurrent = IsCurrent,
			}),
			Handle = new( "ImageButton", {
				RBXTAG_STATE_IsCurrent = IsCurrent,
				[Roact.Event.InputBegan] = function(rbx, InputObject: InputObject)
					if not rbx then
						return
					end

					if InputObject.UserInputType == Enum.UserInputType.MouseButton1
						or InputObject.UserInputType == Enum.UserInputType.Touch
						or InputObject.KeyCode == Enum.KeyCode.ButtonSelect then

						HandleInput(rbx)

						self:setState({
							CurrentKeypoint = Index
						})
					end
				end,
				[Roact.Ref] = function(rbx)
					if rbx and self.state.CurrentKeypoint == Index and self.PreviousKeypointsCount ~= #SequenceData then
						HandleInput(rbx)
					end
				end,
			}),
		})
	end

	local CurrentKeypoint = self.state.CurrentKeypoint and SequenceData[self.state.CurrentKeypoint] or nil

	return new('ScreenGui', {
		DisplayOrder = 1;
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	}, {
		SequenceEditor = new( "Frame", {
			AnchorPoint = game:GetService("GuiService").ViewportDisplaySize == Enum.DisplaySize.Small
				and Vector2.new(0.5, 0.5)
				or Vector2.new(1, 0),
			Position = game:GetService("GuiService").ViewportDisplaySize == Enum.DisplaySize.Small 
				and UDim2.new(0.5, 0, 0.5, 0)
				or UDim2.new(1, -110, 0.5, 65),
			Active = true,
			Interactable = true,
			RBXTAG_ColorSequenceEditor = true,
			[Roact.Ref] = function(rbx)
				if rbx and not rbx:GetAttribute("ROACT_Styled") then
					self.props.Core.ThemesModule.ApplyThemeComponentsOn(
						rbx, 
						self.props.Core.Components, 
						self.props.Core.ComponentsToRevert, 
						self.props.Core.RoactComponents
					)

					rbx:SetAttribute("ROACT_Styled", true)
				end
			end,
		}, {
			Main = new( "Frame", {
				ClipsDescendants = true,
			},  {
				Sequence = new( "Frame", {}, {
					Data = new( "Frame", {
						ClipsDescendants = true,
						BackgroundTransparency = 1,
					}, {
						Keypoints = new( "Frame", {
							Size = UDim2.new(1, -12, 0, 12),
							AnchorPoint = Vector2.new(0.5, 0),
							Position = UDim2.new(0.5, 0, 1, -12),
						}, KeypointsObjects),
						Result = new( "Frame", {
							Size = UDim2.new(1, -12, 1, -16),
							AnchorPoint = Vector2.new(0.5, 0),
							Position = UDim2.new(0.5, 0, 0, 4),
							[Roact.Event.InputBegan] = function(rbx, InputObject: InputObject, DoNotListen)
								if DoNotListen then
									return
								end

								if InputObject.UserInputType == Enum.UserInputType.MouseButton1
									or InputObject.UserInputType == Enum.UserInputType.Touch
									or InputObject.KeyCode == Enum.KeyCode.ButtonSelect then

									if not rbx or #SequenceData >= 20 then
										return
									end

									local AbsolutePosition = rbx.AbsolutePosition
									local AbsoluteSize = rbx.AbsoluteSize
									local InputAbsolutePosition

									if InputObject.KeyCode == Enum.KeyCode.ButtonSelect then
										InputAbsolutePosition = rbx.AbsolutePosition + Vector2.new(20, 20)
									else
										InputAbsolutePosition = Vector2.new(InputObject.Position.X, InputObject.Position.Y)
									end

									local RelativePosition = InputAbsolutePosition - AbsolutePosition

									local Time = GetIncrementMultiple(RelativePosition.X / AbsoluteSize.X, self.state.GridIncrement)
									
									local Success

									Success, Time = self:EvaluateKeypoint(Time)

									if not Success then
										return
									end
									
									local ReferenceKeypoint = ColorSequenceKeypoint.new(Time, Color3.new(1, 1, 1))

									table.insert(SequenceData, ReferenceKeypoint)

									table.sort(SequenceData, function(A, B)
										return A.Time < B.Time
									end)

									local NewIndex = table.find(SequenceData, ReferenceKeypoint)
									
									local Color = Color3.new(1, 1, 1)
									local PreviousKeypoint = SequenceData[NewIndex - 1]
									local NextKeypoint = SequenceData[NewIndex + 1]
									
									if PreviousKeypoint and NextKeypoint then
										local TimeInterval = NextKeypoint.Time - PreviousKeypoint.Time
										local PreviousToCurrentDelta = ReferenceKeypoint.Time - PreviousKeypoint.Time
										
										Color = PreviousKeypoint.Value:Lerp(NextKeypoint.Value, PreviousToCurrentDelta / TimeInterval)
									end
									
									local NewKeypoint = ColorSequenceKeypoint.new(Time, Color)
									
									SequenceData[NewIndex] = NewKeypoint

									self:setState({
										CurrentKeypoint = NewIndex
									})

									self:SetColorSequence(SequenceData)
								end
							end,
						}, {
							UIGradient = new( "UIGradient", {
								Color = ColorSequence.new(SequenceData),
							}),
						}),
					}),
				}),
				Divider = new("Frame", {
					RBXTAG_Divider = true,
					RBXTAG_STATE_Horizontal = true,
					LayoutOrder = 1,
				}),
				Settings = new( "Frame", {}, {
					Time = new( "Frame", {
						Size = UDim2.new(0, 86, 0, 18),
					}, {
						Input = new( "Frame", {
							AnchorPoint = Vector2.new(1, 0.5),
							Size = UDim2.new(0, 50, 1, 0),
							Position = UDim2.new(1, 0, 0.5, 0),
							RBXTAG_Input = true,
							RBXTAG_STATE_Alternative = true,
						}, {
							Background = new( "Frame", {}),
							TextBox = new( "TextBox", {
								Size = UDim2.new(1, -10, 1, 0),
								Interactable = CurrentKeypoint and true or false,
								Text = CurrentKeypoint and Support.Round(CurrentKeypoint.Time, 3) or "",
								Position = UDim2.new(0, 5, 0, 0),
								[Roact.Event.FocusLost] = function(rbx)
									if rbx then
										local Input = tonumber(rbx.Text)

										if Input then
											local NewKeypoint = ModifyKeypoint(CurrentKeypoint, "Time", Input)

											SequenceData[self.state.CurrentKeypoint] = NewKeypoint

											table.sort(SequenceData, function(A, B)
												return A.Time < B.Time
											end)

											local NewIndex = table.find(SequenceData, NewKeypoint)

											self:setState({
												CurrentKeypoint = NewIndex
											})

											self:SetColorSequence(SequenceData)
										end
									end
								end,
							}),
						}),
						Label = new( "TextLabel", {
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(0, 0, 0.5, 0),
							Text = "Time",
							Size = UDim2.new(0, 27, 0, 12),
							RBXTAG_Label = true,
						}),
					}),
					Padding = new( "Frame", {
						LayoutOrder = 3,
						Size = UDim2.new(1, 0, 1, 0),
					}, {
						UIFlexItem = new( "UIFlexItem", {
							FlexMode = Enum.UIFlexMode.Shrink,
						}),
					}),
					Color = new( "Frame", {
						Size = UDim2.new(0, 90, 0, 18),
						Position = UDim2.new(0, 14, 0, 240),
						LayoutOrder = 1,
						RBXTAG_ColorOption = true
					}, {
						Indicator = new( "Frame", {
							AnchorPoint = Vector2.new(1, 0),
							Size = UDim2.new(0, 17, 0, 18),
							Position = UDim2.new(0, 70, 0, 0),
							BackgroundColor3 = CurrentKeypoint and CurrentKeypoint.Value
						}),
						HSVPicker = new( "ImageButton", {
							AnchorPoint = Vector2.new(1, 0.5),
							Size = UDim2.new(0, 18, 0, 18),
							Position = UDim2.new(0, 90, 0.5, 0),
							[Roact.Event.Activated] = function()
								if not CurrentKeypoint then
									return
								end

								local ColorPickerElement = Roact.createElement(ColorPicker, {
									InitialColor = CurrentKeypoint.Value or Color3.fromRGB(255, 255, 255),
									OnConfirm = function (Color)
										local NewColorKeypoint = ModifyKeypoint(CurrentKeypoint, "Value", Color)
										SequenceData[self.state.CurrentKeypoint] = NewColorKeypoint
										
										self:setState({
											CurrentKeypoint = self.state.CurrentKeypoint
										})
										
										self:SetColorSequence(SequenceData)
										
										self.ColorPickerHandle = Roact.unmount(self.ColorPickerHandle)
									end,
									OnCancel = function ()
										self.ColorPickerHandle = Roact.unmount(self.ColorPickerHandle)
									end,
								})
								self.ColorPickerHandle = self.ColorPickerHandle and
									Roact.update(self.ColorPickerHandle, ColorPickerElement) or
									Roact.mount(ColorPickerElement, self.props.Core.UI, 'ColorPicker')
							end,
						}),
						Label = new( "TextLabel", {
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(0, 0, 0.5, 0),
							Text = "Color",
							Size = UDim2.new(0, 70, 0, 18),
							RBXTAG_Label = true
						}),
					}),
					Increment = new( "Frame", {
						LayoutOrder = 2,
						Size = UDim2.new(0, 86, 0, 18),
					}, {
						Input = new( "Frame", {
							AnchorPoint = Vector2.new(1, 0.5),
							Size = UDim2.new(0, 50, 1, 0),
							Position = UDim2.new(1, 0, 0.5, 0),
							RBXTAG_Input = true,
							RBXTAG_STATE_Alternative = true,
						}, {
							Background = new( "Frame", {}),
							TextBox = new( "TextBox", {
								Size = UDim2.new(1, -10, 1, 0),
								Interactable = CurrentKeypoint and true or false,
								Text = self.state.GridIncrement and Support.Round(self.state.GridIncrement, 3) or "",
								Position = UDim2.new(0, 5, 0, 0),
								[Roact.Event.FocusLost] = function(rbx)
									if rbx then
										local Input = tonumber(rbx.Text)

										if Input then
											self:setState({
												GridIncrement = Input,
											})
										end
									end
								end,
							}),
						}),
						Label = new( "TextLabel", {
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(0, 0, 0.5, 0),
							Text = "Grid",
							Size = UDim2.new(0, 27, 0, 12),
							RBXTAG_Label = true,
						}),
					}),
					Cancel = new( "TextButton", {
						LayoutOrder = 4,
						Size = UDim2.new(0, 45, 0, 18),
						Text = "Cancel",
						[Roact.Event.Activated] = function (rbx)
							Sounds:WaitForChild("Press"):Play()
							self:Cancel()
						end;
						[Roact.Event.MouseEnter] = function ()
							Sounds:WaitForChild("Hover"):Play()
						end;
					}),
					Confirm = new( "TextButton", {
						LayoutOrder = 5,
						Size = UDim2.new(0, 18, 0, 18),
						Text = "✔️",
						[Roact.Event.Activated] = function (rbx)
							Sounds:WaitForChild("Press"):Play()
							self:Finish()
						end;
						[Roact.Event.MouseEnter] = function ()
							Sounds:WaitForChild("Hover"):Play()
						end;
					}),
					Delete = new( "TextButton", {
						LayoutOrder = 6,
						Size = UDim2.new(0, 45, 0, 18),
						Text = "Delete",
						[Roact.Event.Activated] = function (rbx)
							Sounds:WaitForChild("Press"):Play()
							self:DeleteCurrentKeypoint()
						end;
						[Roact.Event.MouseEnter] = function ()
							Sounds:WaitForChild("Hover"):Play()
						end;
					}),
				}),
			}),
		}),
	})
end

return ColorSequenceEditor