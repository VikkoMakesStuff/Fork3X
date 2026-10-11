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
	local Colors = ThemeInfo.Colors
	
	local Maid = require( Core.Libraries:WaitForChild('Maid') )

	local Roact = Core.Roact
	local Support = Core.Support
	local new = Roact.createElement

	local Dropbox = Roact.PureComponent:extend("Dropbox")

	function Dropbox:init()
		self.Maid = Maid.new()
		self.DropboxRef = Roact.createRef()
		
		local WidgetWindow: PluginGui = Core.WidgetWindow
		
		self.Maid.PluginDropping = WidgetWindow.PluginDragDropped:Connect(function(DragInfo)
			local MousePosition = WidgetWindow:GetRelativeMousePosition()
			
			local DropboxObject = self.DropboxRef and self.DropboxRef:getValue()
			
			if DropboxObject and IsPointInsideGuiObject(DropboxObject, MousePosition) then
				local MIME = DragInfo.MimeType
				local Sender = DragInfo.Sender
				
				if Sender == "Explorer" and MIME == "roblox/selection" then
					local Selection = game:GetService("Selection")
					
					local Items = Selection:Get()
					local OptionConfiguration = self.props.Configuration
					
					props:SetNotificationFromResult( OptionConfiguration:OnActivated(Items) )
				end
			end
		end)
	end
	
	function Dropbox:willUnmount()
		self.Maid:Destroy()
	end

	function Dropbox:render()
		local IconToDisplay = self.state.ToggleState and ThemeInfo.Icons.CheckOn or ThemeInfo.Icons.CheckOff

		return new( "TextButton", {
			FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
			TextColor3 = Colors.TextColor,
			Text = "Drop a file here...",
			Size = UDim2.new(0, 114, 0, 24),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = ThemeInfo.Colors.HighlightedButtonColor,
			TextSize = 15,
			LayoutOrder = 1,
			AutoButtonColor = false,
			[Roact.Ref] = self.DropboxRef,
			[Roact.Event.Activated] = function(rbx)
				local ImportedFile = StudioService:PromptImportFileAsync(self.props.FileTypes)
				
				if ImportedFile then
					local Id = ImportedFile:GetTemporaryId()

					local LoadedObjects = game:GetObjects(Id)
					local OptionConfiguration = self.props.Configuration

					props:SetNotificationFromResult( OptionConfiguration:OnActivated(LoadedObjects) )
				end
			end,
		}, {
			UICorner = new( "UICorner", {
				CornerRadius = UDim.new(0, 4),
			}),		
			UIPadding = new( "UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
		})
	end

	return Dropbox
end

return GetRoactObject