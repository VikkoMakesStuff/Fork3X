local Settings = {
	--["Extra Features"] = 
}

local Main = script.Parent.Parent
local CoreAddon = Main.Parent

local SerializationMethods = require(CoreAddon.Libraries.SerializationMethods)

local ConfirmText = [[<font size="30" color={color}>Are you sure you want to delete this addon?</font>
								
You can always add it back via the + button at the top.]]

local ApplyText = [[<font size="30" color={color}>Your new addons' configuration was successfully applied!</font>

It will be saved across studio sessions, so you can enjoy the same comfort everywhere. :>

However, in order to use it now, <b>you must restart Fork3X.</b> Restart now?]]

local function GetCategory(props, Component)
	local Core = props.Core
	local Roact = Core.Roact
	local new = Roact.createElement

	local ThemeInfo = props.ThemeInfo

	local ShouldReload = true
	local ItemToReturn
	
	local UIObjects = Main.Objects
	
	local MouseHints = require(script.MouseHints)
	
	local AdditionalContentFolder = UIObjects.AdditionalContent
	
	local ContentComponent = require(AdditionalContentFolder.Content)(props)
	local AddButton = require(AdditionalContentFolder.AddButton)(props)
	
	local Color = ThemeInfo.Colors.Opposite
	local ColorString = string.format('"rgb(%*,%*,%*)"', Color.R * 255, Color.G * 255, Color.B * 255)
	
	local UIObjects
	local AddonsChanged = false
	
	local CreateUI
	
	CreateUI = function(IsUpdate)
		local AddonsObjects = {}
		
		for Index, Addon in Core.EveryAddon do
			local Module = Addon.Module
			local Data = require(Module)

			local Title = Data.Title or Module.Name
			local Description = Data.Description or "This addon has no description."

			local Icon = Data.Icon

			if type(Icon) == "table" then
				Icon = Icon[ThemeInfo.Name]
			end

			local IsBuiltIn = Module:IsDescendantOf(Core.AddonsFolder)

			AddonsObjects[ tostring(Index) ] = new(ContentComponent, {
				Preview = Icon and new( "ImageLabel", {
					AnchorPoint = Vector2.new(0, 0.5),
					Image = Icon,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.new(0, 64, 0, 64),
				}) or nil,
				ObjectYSize = 150,
				Title = Title,
				Description = Description,
				
				Buttons = Roact.createFragment({
					More = new( "ImageButton", {
						Image = ThemeInfo.Icons.More,
						BackgroundTransparency = 1,
						BorderColor3 = Color3.new(0, 0, 0),
						Size = UDim2.new(0, 16, 0, 16),
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.new(1, 1, 1),
						[Roact.Event.Activated] = function()
							props.CreateWindow("DescriptionExtend", "About this addon", {
								Title = Title,
								Description = Description,
							})
						end,
					}),
					Delete = not IsBuiltIn and new( "ImageButton", {
						LayoutOrder = 1,
						BackgroundTransparency = 1,
						Image = ThemeInfo.Icons.Delete,
						BorderColor3 = Color3.new(0, 0, 0),
						Size = UDim2.new(0, 16, 0, 16),
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.new(1, 1, 1),
						[Roact.Event.Activated] = function()
							props.CreateWindow("Confirm", "Are you sure?", {
								Text = ConfirmText:gsub("{color}", ColorString),
							})
							
							local DeleteAddon = props.WindowClosed:Wait()
							
							if DeleteAddon == true then
								table.remove(Core.EveryAddon, Index)
								
								AddonsChanged = true
								
								CreateUI(true)
							end
						end,
					}) or nil,
					Raise = not IsBuiltIn and new( "ImageButton", {
						Image = ThemeInfo.Icons.ArrowUp,
						BackgroundTransparency = 1,
						BorderColor3 = Color3.new(0, 0, 0),
						Size = UDim2.new(0, 16, 0, 16),
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.new(1, 1, 1),
						[Roact.Event.Activated] = function()
							local NextAddon = Core.EveryAddon[Index + 1]
							
							if NextAddon then
								local NextPriority = NextAddon.Priority
								local CurrentPriority = Addon.Priority
								
								Addon.Priority = NextPriority
								NextAddon.Priority = CurrentPriority
								
								AddonsChanged = true
								
								CreateUI(true)
							end
						end,
					}) or nil,
					Lower = not IsBuiltIn and new( "ImageButton", {
						Image = ThemeInfo.Icons.ArrowDown,
						BackgroundTransparency = 1,
						BorderColor3 = Color3.new(0, 0, 0),
						Size = UDim2.new(0, 16, 0, 16),
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.new(1, 1, 1),
						[Roact.Event.Activated] = function()
							local PreviousAddon = Core.EveryAddon[Index + 1]

							if PreviousAddon then
								local IsBuiltIn = PreviousAddon.Module:IsDescendantOf(Core.AddonsFolder)
								
								if not IsBuiltIn then
									local PreviousPriority = PreviousAddon.Priority
									local CurrentPriority = Addon.Priority

									Addon.Priority = PreviousPriority
									NextAddon.Priority = CurrentPriority
									
									AddonsChanged = true
									
									CreateUI(true)
								end
							end
						end,
					}) or nil,
					Padding = new( "Frame", {
						LayoutOrder = 4,
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
					}, {
						UIFlexItem = new( "UIFlexItem", {
							FlexMode = Enum.UIFlexMode.Shrink,
						}),
					}),
					Check = new( "ImageButton", {
						AnchorPoint = Vector2.new(0, 0.5),
						Image = Addon.Enabled and ThemeInfo.Icons.CheckOn or ThemeInfo.Icons.CheckOff,
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 16, 0, 16),
						BorderColor3 = Color3.new(0, 0, 0),
						LayoutOrder = 5,
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.new(1, 1, 1),
						[Roact.Change.GuiState] = function(rbx)
							local IconToDisplay = Addon.Enabled and ThemeInfo.Icons.CheckOn or ThemeInfo.Icons.CheckOff
							
							if rbx then
								local StateToIcon = {
									[Enum.GuiState.Hover] = not Addon.Enabled and ThemeInfo.Icons.CheckHover or IconToDisplay,
									[Enum.GuiState.Press] = not Addon.Enabled and ThemeInfo.Icons.CheckHover or IconToDisplay,
									[Enum.GuiState.Idle] = IconToDisplay,
								}

								if StateToIcon[rbx.GuiState] then
									rbx.Image = StateToIcon[rbx.GuiState]
								end

							end
						end,
						[Roact.Event.Activated] = function()
							Addon.Enabled = not Addon.Enabled
							
							AddonsChanged = true
							
							CreateUI(true)
						end,
					}),
				}),

				LayoutOrder = #Core.EveryAddon - Index + 1
			})
		end

		UIObjects = Roact.createFragment({
			UIListLayout = new( "UIListLayout", {
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Add = new( "Frame", {
				BorderColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(1, 0, 0, 32),
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
			}, {
				UIPadding = new( "UIPadding", {
					PaddingRight = UDim.new(0, 10),
					PaddingLeft = UDim.new(0, 10),
				}),
				AddButton = new( AddButton, {
					FileImported = function(Files)
						local Addon: ModuleScript = Files[1]
						
						local IsAModuleScript = Addon:IsA("ModuleScript")
						
						if IsAModuleScript then
							local Data = require(Addon)
							
							if type(Data) == "table" then
								local Priority = Addon:GetAttribute("Priority") and math.max(Addon:GetAttribute("Priority"), 1) or 1
								
								Priority += Core.BuiltInHighestPriority
								
								local AddonData = {
									Module = Addon,
									Priority = Priority,
									Enabled = true,
									IsBuiltIn = false,
								}
								
								table.insert(Core.EveryAddon, AddonData)
								
								table.sort(Core.EveryAddon, function(A, B)
									return A.Priority < B.Priority
								end)
								
								props.SetNotification({
									Color = ThemeInfo.Colors.Success,
									Text = "The addon was successfully added!"
								})
								
								AddonsChanged = true
								
								props.IsRestartRequired = true
								
								CreateUI(true)
							else
								props.SetNotification({
									Color = ThemeInfo.Colors.Fail,
									Text = "The addon must return a table, not `" .. type(Data) .. "`."
								})
							end
						else
							props.SetNotification({
								Color = ThemeInfo.Colors.Fail,
								Text = "The addon must be a ModuleScript, not an Instance of class `" .. Addon.ClassName .. "`."
							})
						end
					end,
					FileTypes = {"rbx", "rbxm", "lua", "luau"},
					Description = MouseHints.AddButton
				}),
				ApplyChanges = new( "TextButton", {
					FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
					TextColor3 = Color3.new(1, 1, 1),
					Text = "Apply",
					Size = UDim2.new(0, 0, 0, 32),
					BorderSizePixel = 0,
					AutomaticSize = Enum.AutomaticSize.X,
					TextSize = 14,
					BackgroundColor3 = Color3.new(0.2, 0.373, 1),
					Visible = AddonsChanged,
					[Roact.Event.Activated] = function()
						local DisabledAddons = {}
						local UserAddons = {}
						
						for _, Addon in Core.EveryAddon do
							local IsBuiltIn = Addon.IsBuiltIn
							
							if IsBuiltIn then
								if not Addon.Enabled then
									DisabledAddons[Addon.Module.Name] = true
								end
							else
								local AddonToSave = table.clone(Addon)
								
								AddonToSave.IsBuiltIn = nil
								AddonToSave.Module = SerializationMethods.Encode(AddonToSave.Module)
								AddonToSave.Priority -= Core.BuiltInHighestPriority
								
								table.insert(UserAddons, AddonToSave)
							end
						end
						
						table.sort(UserAddons, function(A, B)
							return A.Priority < B.Priority
						end)
						
						Core.Plugin:SetSetting("Addons", UserAddons)
						Core.Plugin:SetSetting("DisabledAddons", DisabledAddons) 
						
						props.CreateWindow("Confirm", "Changes Applied", {
							Text = ConfirmText:gsub("{color}", ColorString)
						})
						
						local ApplyAddons = props.WindowClosed:Wait()
						
						if ApplyAddons then
							Core.ApplyAddons()
						end
					end,
				}, {
					UICorner = new( "UICorner", {
						TopLeftRadius = UDim.new(0, 4),
						TopRightRadius = UDim.new(0, 4),
						BottomRightRadius = UDim.new(0, 4),
						BottomLeftRadius = UDim.new(0, 4),
					}),
					UIPadding = new( "UIPadding", {
						PaddingRight = UDim.new(0, 10),
						PaddingLeft = UDim.new(0, 10),
					}),
				}),
				Description = new( "TextLabel", {
					RichText = true,
					Size = UDim2.new(0, 250, 1, 0),
					TextColor3 = ThemeInfo.Colors.TextColor,
					Text = "You can hover the button to learn more about adding themes.",
					Position = UDim2.new(1, -42, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					TextWrapped = true,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
					TextYAlignment = Enum.TextYAlignment.Top,
					TextSize = 14,
				}),
			}),
			Addons = Roact.createFragment(AddonsObjects)
		})
		
		if IsUpdate then
			Component:setState({
				CurrentCategory = Component.state.CurrentCategory
			})
		end
	end

	return function(Update)
		if not UIObjects or Update then
			CreateUI(false)
		end

		return UIObjects
	end
end

return GetCategory