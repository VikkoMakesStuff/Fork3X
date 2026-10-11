local Settings = {
	--["Extra Features"] = 
}

local Main = script.Parent.Parent

local function GetSettings(props, Component)
	local Core = props.Core
	local Roact = Core.Roact
	local new = Roact.createElement
	
	local ThemeInfo = props.ThemeInfo
	
	local CategoryItem = require(Main.Objects.Settings.Group)(props)
	local MakeSetting = require(Main.Objects.Setting)
	
	local TypeToComponent = {
		Toggle = require(Main.Objects.Settings.Toggle)(props),
		TextBox = require(Main.Objects.Settings.TextBox)(props),
		Dropdown = require(Main.Objects.Settings.Dropdown)(props),
		Dropbox = require(Main.Objects.Settings.Dropbox)(props),
	}
	
	local SettingsList = Main.Parent.Settings
	local SettingsModules = SettingsList:GetChildren()
	local Categories = {}
	
	local OpenCategories = {}
	
	for _, CategoryModule in SettingsModules do
		table.insert( Categories, {
			Name = CategoryModule.Name,
			Options = require(CategoryModule)(props)
		} )
	end
	
	table.sort(Categories, function(A, B)
		return A.Name < B.Name
	end)
	
	local ShouldReload = true
	local ItemToReturn
	
	Core.SettingChanged:Connect(function()
		ShouldReload = true
	end)
	
	return function(Update)
		if ShouldReload or Update then
			local UIItems = {
				UIListLayout = new( "UIListLayout", {
					Padding = UDim.new(0, 10),
					VerticalAlignment = Enum.VerticalAlignment.Top,
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			}

			for Index, Category in Categories do
				local Children = {}

				for Index, Option in Category.Options do
					if TypeToComponent[Option.Type] then
						Children[Option.Name] = new( MakeSetting({
							Core = Core,
							Environment = props,
							TypeToComponent = TypeToComponent,
						}), {
							LayoutOrder = Index,
							Option = Option,
						} )
					end
				end

				UIItems[Category.Name] = new(CategoryItem, {
					Name = Category.Name,
					LayoutOrder = Index,
					Children = Children,
					OpenCategories = OpenCategories
				})
			end
			
			ItemToReturn = Roact.createFragment(UIItems)
			
			ShouldReload = false
		end

		return ItemToReturn
	end
end

return GetSettings