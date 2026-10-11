local StudioService = game:GetService("StudioService")

local function IsPointInsideGuiObject(GuiObject: GuiBase2d, Point: Vector2)
	local Position = GuiObject.AbsolutePosition
	local Size = GuiObject.AbsoluteSize
	
	local XStart = GuiObject.AbsolutePosition.X
	local XEnd = XStart + Size.X
	
	local YStart = GuiObject.AbsolutePosition.Y
	local YEnd = XStart + Size.Y
	
	local AfterXStart = Point.X >= XStart
	local BeforeXEnd = Point.X <= XEnd
	
	local AfterYStart = Point.Y >= YStart
	local BeforeYEnd = Point.Y <= YEnd

	if AfterXStart and AfterYStart 
		and BeforeXEnd and BeforeYEnd then
		
		return true
	end
	
	return false
end

local function GetRoactObject(props)
	local Core = props.Core
	local ThemeInfo = props.ThemeInfo
	
	local Maid = require( Core.Libraries:WaitForChild('Maid') )

	local Roact = Core.Roact
	local Support = Core.Support
	local new = Roact.createElement

	local AddButton = Roact.PureComponent:extend("AddButton")
	
	function AddButton:init()
		self.Maid = Maid.new()
		self.ButtonRef = Roact.createRef()
		
		local WidgetWindow: PluginGui = Core.WidgetWindow
		
		self.Maid.PluginDropping = WidgetWindow.PluginDragDropped:Connect(function(DragInfo)
			local MousePosition = WidgetWindow:GetRelativeMousePosition()
			
			local ButtonObject = self.ButtonRef and self.ButtonRef:getValue()
			
			if ButtonObject and IsPointInsideGuiObject(ButtonObject, MousePosition) then
				local MIME = DragInfo.MimeType
				local Sender = DragInfo.Sender
				
				if Sender == "Explorer" and MIME == "roblox/selection" then
					local Selection = game:GetService("Selection")
					
					local Items = Selection:Get()
					
					for Index, Item in Items do
						Items[Index] = Item:Clone()
					end
					
					self.props.FileImported(Items)
				end
			end
		end)
	end
	
	function AddButton:willUnmount()
		self.Maid:Destroy()
	end

	function AddButton:render()
		local IconToDisplay = self.state.ToggleState and ThemeInfo.Icons.CheckOn or ThemeInfo.Icons.CheckOff

		return new( "ImageButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(0, 32, 0, 32),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(0.2, 0.373, 1),
			[Roact.Ref] = self.ButtonRef,
			[Roact.Event.Activated] = function(rbx)
				local ImportedFile = StudioService:PromptImportFileAsync(self.props.FileTypes)
				
				local LoadedObjects
				
				if ImportedFile then
					if string.find(ImportedFile.Name, ".lua", #ImportedFile.Name - 6) then
						local ModuleScriptSource = ImportedFile:GetBinaryContents()
						
						local ModuleScript = Instance.new("ModuleScript")
						ModuleScript.Source = ModuleScriptSource
						ModuleScript.Name = string.match(ImportedFile.Name, "(%w+).lua")
						
						LoadedObjects = {ModuleScript}
					else
						local Id = ImportedFile:GetTemporaryId()

						LoadedObjects = game:GetObjects(Id)
					end
					
					self.props.FileImported(LoadedObjects)
				end
			end,
			[Roact.Event.MouseMoved] = {props.HoverMouseMovement, self.props.Description},
			[Roact.Event.MouseLeave] = props.HoverMouseLeave
		}, {
			UICorner = new( "UICorner", {
				TopLeftRadius = UDim.new(0, 4),
				TopRightRadius = UDim.new(0, 4),
				BottomRightRadius = UDim.new(0, 4),
				BottomLeftRadius = UDim.new(0, 4),
			}),
			ImageLabel = new( "ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = "rbxasset://textures/AvatarCompatibilityPreviewer/add.png",
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 12, 0, 12),
				ResampleMode = Enum.ResamplerMode.Pixelated,
			}),
		})
	end

	return AddButton
end

return GetRoactObject