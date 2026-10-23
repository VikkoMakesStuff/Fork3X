local Tool = script.Parent.Parent.Parent
local Libraries = Tool:WaitForChild('Libraries')

-- API
local Core = require(Tool.Core)
local Selection = Core.Selection
local BoundingBox = require(Tool.Core.BoundingBox)

local Sounds = Core.Sounds

-- Libraries
local Support = require(Libraries:WaitForChild 'SupportLibrary')
local Maid = require(Libraries:WaitForChild 'Maid')
local ListenForManualWindowTrigger = require(Tool.Core:WaitForChild('ListenForManualWindowTrigger'))

-- Create class
local UIController = {}
UIController.__index = UIController

function UIController.new(Tool)
	local self = {
		Tool = Tool;

		-- State
		UI = nil;
		Maid = Maid.new()
	}

	return setmetatable(self, UIController)
end

function UIController:UpdateScrollIndicator()
	if Core.Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) 
		or Core.Services.UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then


		self.ScrollStepIndicator.Position = UDim2.fromOffset(Core.Mouse.X - 5, Core.Mouse.Y + 19)
		
		local Increment = Support.Round(self.Tool.Increment, 4)
		
		self.ScrollStepIndicator.Text = "△: " .. Increment
		self.UI.IncrementOption.Increment.TextBox.Text = Increment
	else
		self.ScrollStepIndicator.Visible = false
	end
end

function UIController:SetUpConnections()
	-- Update the UI every 0.1 seconds
	self.Maid.UIUpdater = Support.Loop(0.1, self.UpdateUI, self)
	
	if Core.Services.UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse then
		
		self.Maid.ScrollStep = self.Tool.ScrollStepChanged:Connect(function(ScrollStep)
			
			self.ScrollStepIndicator.Visible = ScrollStep
			
			if ScrollStep then
				self.ScrollStepIndicator.Text = "△: " .. self.Tool.Increment
				self.ScrollStepIndicator.Position = UDim2.fromOffset(Core.Mouse.X - 5, Core.Mouse.Y + 19)
				
				self.Maid.UpdateIndicator = self.Tool.IncrementChanged:Connect(function(Increment)
					self.ScrollStepIndicator.Text = "△: " .. Increment
					self.UI.IncrementOption.Increment.TextBox.Text = Increment
				end)
				
				self.Maid.UpdatePosition = Support.AddUserInputListener("Changed", "MouseMovement", true, function()
					self.ScrollStepIndicator.Position = UDim2.fromOffset(Core.Mouse.X - 5, Core.Mouse.Y + 19)
				end)
			else
				self.Maid.UpdateIndicator = nil
				self.Maid.UpdatePosition = nil
			end
		end)
	end
end

function UIController:ShowUI()
	-- Creates and reveals the UI

	-- Reveal UI if already created
	if self.UI and self.UI.Parent ~= nil then
		self.UI.Visible = true

		self:SetUpConnections()
		
		--[[
		if Core.Services.UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse then
			self.Maid.UpdateIndicator = Core.Services.RunService.PostSimulation:Connect(function()
				self:UpdateScrollIndicator()
			end)
		end]]
		
		self:AttachDragListener()
		self:AttachAxesListener()
		return
	end

	if self.UI then
		self.UI:Destroy()
	end

	-- Create the UI
	self.UI = Core.Interfaces.BTMoveToolGUI:Clone()
	self.UI.Parent = Core.UI
	self.UI.Visible = true
	
	self.UI:WaitForChild("Info")

	-- Add functionality to the axes option switch
	local AxesSwitch = self.UI.AxesOption
	AxesSwitch.Global.Button.MouseButton1Down:Connect(function ()
		Core.PlaySound("Press")
		
		self.Tool:SetAxes('Global')
	end)
	AxesSwitch.Global.Button.MouseEnter:Connect(function ()
		Core.PlaySound("Hover")
	end)
	AxesSwitch.Local.Button.MouseButton1Down:Connect(function ()
		Core.PlaySound("Press")
		
		self.Tool:SetAxes('Local')
	end)
	AxesSwitch.Local.Button.MouseEnter:Connect(function ()
		Core.PlaySound("Hover")
	end)
	AxesSwitch.Last.Button.MouseButton1Down:Connect(function ()
		Core.PlaySound("Press")
		
		self.Tool:SetAxes('Last')
	end)
	AxesSwitch.Last.Button.MouseEnter:Connect(function ()
		Core.PlaySound("Hover")
	end)
	
	local AreSettingsOpen = false
	
	local SettingsFrame = self.UI.Settings
	local SettingsList = SettingsFrame.Options
	
	local SettingsButton = self.UI.SettingsButton.Button
	
	SettingsButton.Activated:Connect(function()
		Core.PlaySound("Press")
		
		AreSettingsOpen = not AreSettingsOpen
		
		local TagMethod = AreSettingsOpen and script.AddTag or script.RemoveTag

		TagMethod(SettingsButton.Parent, "STATE_CurrentOption")
		
		SettingsFrame.Visible = AreSettingsOpen
	end)
	
	SettingsButton.MouseEnter:Connect(function()
		Core.PlaySound("Hover")
	end)

	local FocusToggle = SettingsList.FocusOption.Check
	local JointsToggle = SettingsList.JointsOption.Check
	local ScrollStepInput = SettingsList.ScrollStepOption.Increment.TextBox

	FocusToggle.Activated:Connect(function()
		self.Tool.FocusWise = not self.Tool.FocusWise
		
		UpdateToggleInput(FocusToggle, self.Tool.FocusWise)
	end)
	
	JointsToggle.Activated:Connect(function()
		self.Tool.UseJointsSystem = not self.Tool.UseJointsSystem

		UpdateToggleInput(JointsToggle, self.Tool.UseJointsSystem)
	end)

	UpdateToggleInput(FocusToggle, self.Tool.FocusWise)
	UpdateToggleInput(JointsToggle, self.Tool.UseJointsSystem)
	
	ScrollStepInput.Parent.Parent.Visible = Core.Services.UserInputService.MouseEnabled
	
	if Core.Services.UserInputService.MouseEnabled then
		ScrollStepInput.FocusLost:Connect(function (EnterPressed)
			local NewIncrement = tonumber(ScrollStepInput.Text)
			
			if NewIncrement then
				self.Tool.ScrollStep = NewIncrement
			end
		end)
	end

	-- Add functionality to the increment input
	local IncrementInput = self.UI.IncrementOption.Increment.TextBox
	IncrementInput.FocusLost:Connect(function (EnterPressed)
		self.Tool.Increment = tonumber(IncrementInput.Text) or self.Tool.Increment
		IncrementInput.Text = Support.Round(self.Tool.Increment, 4)
	end)

	-- Add functionality to the position inputs
	local XInput = self.UI.Info.Center.X.TextBox
	local YInput = self.UI.Info.Center.Y.TextBox
	local ZInput = self.UI.Info.Center.Z.TextBox
	XInput.FocusLost:Connect(function (EnterPressed)
		local NewPosition = tonumber(XInput.Text)
		if NewPosition then
			self.Tool:SetAxisPosition('X', NewPosition)
		end
	end)
	YInput.FocusLost:Connect(function (EnterPressed)
		local NewPosition = tonumber(YInput.Text)
		if NewPosition then
			self.Tool:SetAxisPosition('Y', NewPosition)
		end
	end)
	ZInput.FocusLost:Connect(function (EnterPressed)
		local NewPosition = tonumber(ZInput.Text)
		if NewPosition then
			self.Tool:SetAxisPosition('Z', NewPosition)
		end
	end)
	
	self.ScrollStepIndicator = Core.Make('TextLabel')({
		Name = "IndicatorText";
		Parent = Core.UI;
		AnchorPoint = Vector2.new(1, 0);
		Visible = false;
		RBXTAG_Indicator = true;
		AutomaticSize = Enum.AutomaticSize.XY;
	});
	
	self:SetUpConnections()

	-- Hook up manual triggering
	local SignatureButton = self.UI:WaitForChild('Title'):WaitForChild('Signature')
	ListenForManualWindowTrigger(self.Tool.ManualText, self.Tool.Color.Color, SignatureButton)


	-- Attach state listeners
	self:AttachDragListener()
	self:AttachAxesListener()

end

function UpdateToggleInput(Toggle, Data)
	-- Updates the data in the given buttons

	-- Go through the inputs and data
	if Data == true then
		-- Clear every UI tags
		Toggle:AddTag("STATE_True")
		Toggle:RemoveTag("STATE_Multiple")

		--			ShadowsCheckbox.Image = Core.Assets.CheckedCheckbox;
	elseif Data == false then
		-- Clear every UI tags
		Toggle:RemoveTag("STATE_True")
		Toggle:RemoveTag("STATE_Multiple")

		--			ShadowsCheckbox.Image = Core.Assets.UncheckedCheckbox;
	elseif Data == nil then
		-- Clear every UI tags
		Toggle:RemoveTag("STATE_True")
		Toggle:AddTag("STATE_Multiple")

		--			ShadowsCheckbox.Image = Core.Assets.SemicheckedCheckbox;
	end;

end;

function UIController:AttachDragListener()
	self.Maid.DragListener = self.Tool.DragChanged:Connect(function (Distance)

		-- Update the "distance moved" indicator
		self.UI.Changes.Text.Text = 'moved ' .. math.abs(Distance) .. ' studs'

	end)
end

function UIController:AttachmentsOnlyWarning()
	-- Update the "distance moved" indicator
	self.UI.Changes.Text.Text = "Global axis doesn't work when only attachments are selected. Use local or last instead."
end

function UIController:AttachAxesListener()
	self.Maid.AxesListener = self.Tool.AxesChanged:Connect(function (AxesMode)

		-- Update the UI switch
		Core.ToggleSwitch(AxesMode, self.UI.AxesOption)

	end)
end

function UIController:HideUI()
	-- Hides the tool UI

	-- Make sure there's a UI
	if not self.UI then
		return
	end

	-- Hide the UI
	self.UI.Visible = false

	-- Stop updating the UI
	self.Maid:Destroy()

end

function UIController:UpdateUI()
	-- Updates information on the UI

	-- Make sure the UI's on
	if not self.UI then
		return
	end
	
	local SettingsFrame = self.UI.Settings
	local SettingsList = SettingsFrame.Options
	
	-- Display the focus wise option only when available
	SettingsList.FocusOption.Visible = self.Tool.Axes ~= "Local" and true or false

	-- Only show and calculate selection info if it's not empty
	if #Selection.Parts == 0 and #Selection.Attachments == 0 then
		self.UI.Info.Visible = false
		self.UI.Size = UDim2.new(0, 245, 0, 90)
		return
	else
		self.UI.Info.Visible = true
		self.UI.Size = UDim2.new(0, 245, 0, 150)
	end

	---------------------------------------------
	-- Update the position information indicators
	---------------------------------------------

	local CommonX --= Support.IdentifyCommonItem(XVariations)
	local CommonY --= Support.IdentifyCommonItem(YVariations)
	local CommonZ --= Support.IdentifyCommonItem(ZVariations)

	-- Identify common positions across axes
	if self.Tool.FocusWise == false or self.Tool.Axes == "Local" then
		if Selection.Parts[1] then
			local Part = Selection.Parts[1]
			
			CommonX, CommonY, CommonZ = Support.Round(Part.Position.X, 3)
			, Support.Round(Part.Position.Y, 3)
			, Support.Round(Part.Position.Z, 3)
		else
			local Attachment = Selection.Attachments[1]

			CommonX, CommonY, CommonZ = Support.Round(Attachment.WorldCFrame.Position.X, 3)
			, Support.Round(Attachment.WorldCFrame.Position.Y, 3)
			, Support.Round(Attachment.WorldCFrame.Position.Z, 3)
		end
		
		for _, Part in Selection.Parts do
			if not CommonX and not CommonY and not CommonZ then break end
			
			local X, Y, Z = Support.Round(Part.Position.X, 3)
			, Support.Round(Part.Position.Y, 3)
			, Support.Round(Part.Position.Z, 3)
			
			CommonX = if CommonX ~= X then nil else CommonX
			CommonY = if CommonY ~= Y then nil else CommonY
			CommonZ = if CommonZ ~= Z then nil else CommonZ
		end
		for _, Attachment in Selection.Attachments do
			if not CommonX and not CommonY and not CommonZ then break end
			
			local X, Y, Z = Support.Round(Attachment.WorldCFrame.Position.X, 3)
			, Support.Round(Attachment.WorldCFrame.Position.Y, 3)
			, Support.Round(Attachment.WorldCFrame.Position.Z, 3)
			
			CommonX = if CommonX ~= X then nil else CommonX
			CommonY = if CommonY ~= Y then nil else CommonY
			CommonZ = if CommonZ ~= Z then nil else CommonZ
		end
		
	else
		-- Just output the focus/bounding box's position
		local FocusedObject = self.Tool.Axes == "Global" and BoundingBox.GetBoundingBox() or Selection.Focus
		
		if FocusedObject:IsA("BasePart") then
			CommonX = Support.Round(FocusedObject.Position.X, 3)
			CommonY = Support.Round(FocusedObject.Position.Y, 3)
			CommonZ = Support.Round(FocusedObject.Position.Z, 3)
		elseif FocusedObject:IsA("Attachment") then
			CommonX = Support.Round(FocusedObject.WorldCFrame.Position.X, 3)
			CommonY = Support.Round(FocusedObject.WorldCFrame.Position.Y, 3)
			CommonZ = Support.Round(FocusedObject.WorldCFrame.Position.Z, 3)
		end
	end

	-- Shortcuts to indicators
	local XIndicator = self.UI.Info.Center.X.TextBox
	local YIndicator = self.UI.Info.Center.Y.TextBox
	local ZIndicator = self.UI.Info.Center.Z.TextBox

	-- Update each indicator if it's not currently being edited
	if not XIndicator:IsFocused() then
		XIndicator.Text = CommonX or '*'
	end
	if not YIndicator:IsFocused() then
		YIndicator.Text = CommonY or '*'
	end
	if not ZIndicator:IsFocused() then
		ZIndicator.Text = CommonZ or '*'
	end

end

function UIController:FocusIncrementInput()
	self.UI.IncrementOption.Increment.TextBox:CaptureFocus()
end

return UIController