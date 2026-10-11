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

local Support = require(Libraries.SupportLibrary)

-- Roact
local new = function(Type, props, ...)
	props["RBXTAG_Native"] = true
	
	return Roact.createElement(Type, props, ...)
end

-- Create component
local NumberSequenceEditor = Roact.Component:extend(script.Name)

function NumberSequenceEditor:init()
	self.Maid = Maid.new()
	
	self.PreviousKeypointsCount = self.state.NumberSequence and #self.state.NumberSequence or 0
	
	self.InputListener = UserInputService.InputBegan:Connect(function(InputObject: InputObject, DoNotListen)
		if DoNotListen then
			return
		end
		
		if InputObject.KeyCode == Enum.KeyCode.Delete and self.state.CurrentKeypoint then
			self:DeleteCurrentKeypoint()
		end
	end)
	
	self:setState({
		Max = 5,
		Min = 0,
		GridIncrement = 0.05,
		CurrentKeypoint = Roact.None,
		NumberSequence = self.props.InitialNumberSequence and self.props.InitialNumberSequence.Keypoints or {
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1)
		}
	})
end

function NumberSequenceEditor:didUpdate(previousProps)
	self.PreviousKeypointsCount = #self.state.NumberSequence

    if previousProps.InitialColor ~= self.props.InitialColor then
		self:setState({
			NumberSequence = self.InitialNumberSequence and self.InitialNumberSequence.Keypoints or {
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1)
			}
		})
    end
end

function NumberSequenceEditor:SetNumberSequence(Keypoints)
	self:setState({
		NumberSequence = Keypoints
	})
    if self.props.SetPreviewSequence then
        fastSpawn(function ()
			self.props.SetPreviewSequence(NumberSequence.new(Keypoints))
        end)
    end
end

function NumberSequenceEditor:DeleteCurrentKeypoint()
	local SequenceData = self.state.NumberSequence
	
	if self.state.CurrentKeypoint == 1 or self.state.CurrentKeypoint == #SequenceData then
		return
	end
	
	table.remove(SequenceData, self.state.CurrentKeypoint)

	self:setState({
		CurrentKeypoint = Roact.None,
	})

	self:SetNumberSequence(SequenceData)
end

function NumberSequenceEditor:Finish()
	if self.props.SetPreviewSequence then
        fastSpawn(function ()
			self.props.SetPreviewSequence(nil)
        end)
    end
    if self.props.OnConfirm then
		local Keypoints = self.state.NumberSequence
        local Sequence = NumberSequence.new(Keypoints)
        fastSpawn(function ()
            self.props.OnConfirm(Sequence)
        end)
    end
end

function NumberSequenceEditor:Cancel()
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
		Envelope = Keypoint.Envelope
	}
	
	KeypointData[PropertyName] = Value
	
	return NumberSequenceKeypoint.new(KeypointData.Time, KeypointData.Value, KeypointData.Envelope)
end

function GetGrid(Axis)
	if Axis == "X" then
		
		local Lines = {
			UIListLayout = new( "UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween,
			}),
			UIPadding = new( "UIPadding", {
				PaddingLeft = UDim.new(0.1, 0),
				PaddingRight = UDim.new(0.1, 0),
			}),
		}
		
		for i = 1, 9 do
			Lines[ tostring(i) ] = new( "Frame", {
				Size = UDim2.new(0, 1, 1, 0),
				RBXTAG_GridBar = true,
			})
		end
		
		return Lines
	else
		
		local Lines = {
			UIListLayout = new( "UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalFlex = Enum.UIFlexAlignment.SpaceBetween,
			}),
			UIPadding = new( "UIPadding", {
				PaddingBottom = UDim.new(0.1, 0),
				PaddingTop = UDim.new(0.1, 0),
			}),
		}
		
		for i = 1, 9 do
			Lines[ tostring(i) ] = new( "Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				RBXTAG_GridBar = true,
			})
		end
		
		return Lines
	end
end

function NumberSequenceEditor:EvaluateKeypoint(Time, Value, Index)
	local SequenceData = self.state.NumberSequence
	
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
	
	-- Clamp the value between the maximum and the minimum
	Value = math.clamp(Value, self.state.Min, self.state.Max)
	
	return true, Time, Value
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

function NumberSequenceEditor:render()
	
	local KeypointsObjects = {}
	local Path2DData = {
		Main = {},
		Min = {},
		Max = {}
	}
	
	local SequenceData = self.state.NumberSequence
	
	for Index, Keypoint in next, self.state.NumberSequence do
		local SequenceRange = self.state.Max - self.state.Min
		local DeltaY = Keypoint.Value - self.state.Min
		
		local XPosition = Keypoint.Time
		local YPosition = DeltaY / SequenceRange
		
		local FinalPosition = UDim2.new(XPosition, 0, 1 - YPosition, 0)
		local Envelope = UDim2.fromScale(0, Keypoint.Envelope / self.state.Max)
		
		local MinPosition = FinalPosition - Envelope
		local MaxPosition = FinalPosition + Envelope
		
		local OutOfBounds = YPosition > 1 or YPosition < 0
		
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
					local ParentAbsoluteSize = Parent.AbsoluteSize

					local Offset = NewPosition - Parent.AbsolutePosition

					local Time = GetIncrementMultiple(Offset.X / ParentAbsoluteSize.X, self.state.GridIncrement)
					local Value = GetIncrementMultiple(Offset.Y / ParentAbsoluteSize.Y, self.state.GridIncrement)
					
					local Success

					Success, Time, Value = self:EvaluateKeypoint(
						Time, 
						math.lerp( self.state.Min, self.state.Max, (1 - Value) ),
						Index
					)
					
					local MaxRange = self.state.Max - self.state.Min
					local YDelta = Value - self.state.Min
					
					local RelativeYPosition = YDelta / MaxRange
					
					if not Success or rbx.Position == UDim2.fromScale(Time, 1 - RelativeYPosition) then
						return
					end
					
					rbx.Position = UDim2.fromScale(Time, 1 - RelativeYPosition)

					local NewKeypoint = NumberSequenceKeypoint.new(Time, Value, SequenceData[Index].Envelope)

					SequenceData[Index] = NewKeypoint

					table.sort(SequenceData, function(A, B)
						return A.Time < B.Time
					end)

					local NewIndex = table.find(SequenceData, NewKeypoint)

					self:setState({
						CurrentKeypoint = NewIndex
					})
					
					self:SetNumberSequence(SequenceData)
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
		
		KeypointsObjects[ tostring(Index) ] = new( "ImageButton", {
			Position = FinalPosition,
			AnchorPoint = Vector2.new(0.5, 0.5),
			RBXTAG_Keypoint = true,
			RBXTAG_STATE_IsCurrent = self.state.CurrentKeypoint == Index,
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
		}, OutOfBounds and {
			ReminderLine = new("ImageButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1024, 0, 1024, 0),
				[Roact.Event.InputBegan] = function(rbx, InputObject: InputObject)
					if not rbx then
						return
					end

					if InputObject.UserInputType == Enum.UserInputType.MouseButton1
						or InputObject.UserInputType == Enum.UserInputType.Touch
						or InputObject.KeyCode == Enum.KeyCode.ButtonSelect then
						
						self:setState({
							CurrentKeypoint = Index
						})
					end
				end,
			})
		} or nil)
		
		Path2DData.Main[Index] = Path2DControlPoint.new(FinalPosition)
		Path2DData.Min[Index] = Path2DControlPoint.new(MinPosition)
		Path2DData.Max[Index] = Path2DControlPoint.new(MaxPosition)
	end

	local CurrentKeypoint = self.state.CurrentKeypoint and SequenceData[self.state.CurrentKeypoint] or nil
	
	local ResultChildren = {
		Grid = new( "CanvasGroup", {
			Size = UDim2.new(1, 0, 1, 0),
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
					local Value = GetIncrementMultiple(RelativePosition.Y / AbsoluteSize.Y, self.state.GridIncrement)
					
					local Success
					
					Success, Time, Value = self:EvaluateKeypoint(Time, Value)
					
					if not Success then
						return
					end
					
					local NewKeypoint = NumberSequenceKeypoint.new(Time, math.lerp(self.state.Min, self.state.Max, Value), 0)

					table.insert(SequenceData, NewKeypoint)

					table.sort(SequenceData, function(A, B)
						return A.Time < B.Time
					end)

					local NewIndex = table.find(SequenceData, NewKeypoint)

					self:setState({
						CurrentKeypoint = NewIndex
					})

					self:SetNumberSequence(SequenceData)
				end
			end,
		}, {
			Path = new( "Path2D", {
				ZIndex = 10,
				[Roact.Ref] = function(rbx: Path2D?)
					if rbx then
						rbx:SetControlPoints(Path2DData.Main)
					end
				end,
			} ),
			MinPath = new( "Path2D", {
				ZIndex = 9,
				RBXTAG_STATE_IsEnvelope = true,
				[Roact.Ref] = function(rbx: Path2D?)
					if rbx then
						rbx:SetControlPoints(Path2DData.Min)
					end
				end,
			} ),
			MaxPath = new( "Path2D", {
				ZIndex = 9,
				RBXTAG_STATE_IsEnvelope = true,
				[Roact.Ref] = function(rbx: Path2D?)
					if rbx then
						rbx:SetControlPoints(Path2DData.Max)
					end
				end,
			} ),
			Time = new( "Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
			}, GetGrid("X")),

			Value = new( "Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
			}, GetGrid("Y")),
		}),
	}
	
	ResultChildren = Support.Merge(ResultChildren, KeypointsObjects)
	
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
			RBXTAG_NumberSequenceEditor = true,
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
					Panel = new( "Frame", {
						Size = UDim2.new(0, 120, 1, 0),
					}, {
						Increment = new( "Frame", {
							Size = UDim2.new(1, 0, 0, 18),
							AnchorPoint = Vector2.new(1, 0.5),
							Position = UDim2.new(1, 0, 0.5, 0),
						}, {
							Input = new( "Frame", {
								AnchorPoint = Vector2.new(1, 0.5),
								Size = UDim2.new(0, 42, 1, 0),
								Position = UDim2.new(1, 0, 0.5, 0),
								RBXTAG_Input = true,
								RBXTAG_STATE_Alternative = true,
							}, {
								Background = new( "Frame", {}),
								TextBox = new( "TextBox", {
									Size = UDim2.new(1, -10, 1, 0),
									Text = self.state.GridIncrement or "",
									Position = UDim2.new(0, 5, 0, 0),
									[Roact.Event.FocusLost] = function(rbx)
										if rbx then
											local Input = tonumber(rbx.Text)

											if Input then
												self:setState({
													GridIncrement = Input
												})
											end
										end
									end,
								}),
							}),
							Label = new( "TextLabel", {
								AnchorPoint = Vector2.new(0, 0.5),
								Position = UDim2.new(0, 0, 0.5, 0),
								Text = "Unit",
								Size = UDim2.new(0, 30, 0, 12),
								RBXTAG_Label = true,
							}),
						}),
						Max = new( "Frame", {
							Size = UDim2.new(1, 0, 0, 18),
							AnchorPoint = Vector2.new(1, 0),
							Position = UDim2.new(1, 0, 0, 0),
						}, {
							Input = new( "Frame", {
								AnchorPoint = Vector2.new(1, 0.5),
								Size = UDim2.new(0, 42, 1, 0),
								Position = UDim2.new(1, 0, 0.5, 0),
								RBXTAG_Input = true,
								RBXTAG_STATE_Alternative = true,
							}, {
								Background = new( "Frame", {}),
								TextBox = new( "TextBox", {
									Size = UDim2.new(1, -10, 1, 0),
									Text = self.state.Max or "",
									Position = UDim2.new(0, 5, 0, 0),
									[Roact.Event.FocusLost] = function(rbx)
										if rbx then
											local Input = tonumber(rbx.Text)

											if Input then
												self:setState({
													Max = Input
												})
											end
										end
									end,
								}),
							}),
							Label = new( "TextLabel", {
								AnchorPoint = Vector2.new(0, 0.5),
								Position = UDim2.new(0, 0, 0.5, 0),
								Text = "Max",
								Size = UDim2.new(0, 30, 0, 12),
								RBXTAG_Label = true,
							}),
						}),
						Min = new( "Frame", {
							Size = UDim2.new(1, 0, 0, 18),
							AnchorPoint = Vector2.new(1, 1),
							Position = UDim2.new(1, 0, 1, 0),
						}, {
							Input = new( "Frame", {
								AnchorPoint = Vector2.new(1, 0.5),
								Size = UDim2.new(0, 42, 1, 0),
								Position = UDim2.new(1, 0, 0.5, 0),
								RBXTAG_Input = true,
								RBXTAG_STATE_Alternative = true,
							}, {
								Background = new( "Frame", {}),
								TextBox = new( "TextBox", {
									Size = UDim2.new(1, -10, 1, 0),
									Text = self.state.Min or "",
									Position = UDim2.new(0, 5, 0, 0),
									[Roact.Event.FocusLost] = function(rbx)
										if rbx then
											local Input = tonumber(rbx.Text)

											if Input then
												self:setState({
													Min = Input
												})
											end
										end
									end,
								}),
							}),
							Label = new( "TextLabel", {
								AnchorPoint = Vector2.new(0, 0.5),
								Position = UDim2.new(0, 0, 0.5, 0),
								Text = "Min",
								Size = UDim2.new(0, 30, 0, 12),
								RBXTAG_Label = true,
							}),
						}),
					}),
					FirstDivider = new("Frame", {
						RBXTAG_Divider = true,
						RBXTAG_STATE_Vertical = true,
						LayoutOrder = 1,
					}),
					Result = new( "Frame", {
						ClipsDescendants = true
					}, ResultChildren),
					SecondDivider = new("Frame", {
						RBXTAG_Divider = true,
						RBXTAG_STATE_Vertical = true,
						LayoutOrder = 3,
					}),
				}),
				Divider = new("Frame", {
					RBXTAG_Divider = true,
					RBXTAG_STATE_Horizontal = true,
					LayoutOrder = 1,
				}),
				Settings = new( "Frame", {}, {
					Envelope = new( "Frame", {
						LayoutOrder = 2,
						Size = UDim2.new(0, 113, 0, 18),
					}, {
						Input = new( "Frame", {
							AnchorPoint = Vector2.new(0, 0.5),
							Size = UDim2.new(0, 53, 1, 0),
							Position = UDim2.new(0, 60, 0.5, 0),
							RBXTAG_Input = true,
							RBXTAG_STATE_Alternative = true,
						}, {
							Background = new( "Frame", {}),
							TextBox = new( "TextBox", {
								Size = UDim2.new(1, -10, 1, 0),
								Interactable = CurrentKeypoint and true or false,
								Text = CurrentKeypoint and Support.Round(CurrentKeypoint.Envelope, 3) or "",
								Position = UDim2.new(0, 5, 0, 0),
								[Roact.Event.FocusLost] = function(rbx)
									if rbx then
										local Input = tonumber(rbx.Text)

										if Input then
											SequenceData[self.state.CurrentKeypoint] = ModifyKeypoint(SequenceData[self.state.CurrentKeypoint], "Envelope", Input)

											self:SetNumberSequence(SequenceData)
										end
									end
								end,
							}),
						}),
						Label = new( "TextLabel", {
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(0, 0, 0.5, 0),
							Text = "Envelope",
							Size = UDim2.new(0, 51, 0, 12),
							RBXTAG_Label = true,
						}),
					}),
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
											local NewKeypoint = ModifyKeypoint(SequenceData[CurrentKeypoint], "Time", Input)

											SequenceData[self.state.CurrentKeypoint] = NewKeypoint

											table.sort(SequenceData, function(A, B)
												return A.Time < B.Time
											end)

											local NewIndex = table.find(SequenceData, NewKeypoint)

											self:setState({
												CurrentKeypoint = NewIndex
											})

											self:SetNumberSequence(SequenceData)
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
					Value = new( "Frame", {
						LayoutOrder = 1,
						Size = UDim2.new(0, 92, 0, 18),
					}, {
						Input = new( "Frame", {
							AnchorPoint = Vector2.new(0, 0.5),
							Size = UDim2.new(0, 53, 1, 0),
							Position = UDim2.new(0, 39, 0.5, 0),
							RBXTAG_Input = true,
							RBXTAG_STATE_Alternative = true,
						}, {
							Background = new( "Frame", {}),
							TextBox = new( "TextBox", {
								Size = UDim2.new(1, -10, 1, 0),
								Text = CurrentKeypoint and Support.Round(CurrentKeypoint.Value, 3) or "",
								Position = UDim2.new(0, 5, 0, 0),
								Interactable = CurrentKeypoint and true or false,
								[Roact.Event.FocusLost] = function(rbx)
									if rbx then
										local Input = tonumber(rbx.Text)
										
										if Input then
											SequenceData[self.state.CurrentKeypoint] = ModifyKeypoint(SequenceData[self.state.CurrentKeypoint], "Value", Input)
											
											self:SetNumberSequence(SequenceData)
										end
									end
								end,
							}),
						}),
						Label = new( "TextLabel", {
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(0, 0, 0.5, 0),
							Text = "Value",
							Size = UDim2.new(0, 30, 0, 12),
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
						LayoutOrder = 4,
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
						LayoutOrder = 4,
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
		},  script.Name, self),
    })
end

return NumberSequenceEditor