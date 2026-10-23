local Tool = script.Parent.Parent
local Core = require(Tool.Core)
local Options = Core.Options
local Sounds = Core.Sounds

local HistoryRecord

-- Libraries
local ListenForManualWindowTrigger = require(Tool.Core:WaitForChild('ListenForManualWindowTrigger'))

-- Import relevant references
local Selection = Core.Selection
local Support = Core.Support
local Security = Core.Security

-- Initialize the tool
local MarketplaceTool = {
	Name = 'Marketplace Tool',
	Color = BrickColor.new 'Pink',
	
	CreationYear = 0,
}

if table.find(Core.Options.ToolsBlacklist, MarketplaceTool.Name) then
	return MarketplaceTool
end

MarketplaceTool.ManualText = [[<font size="24"><b>Marketplace Tool  🛠</b></font>
Opens a catalog of images, allowing you to get image IDs quickly.

{split}

<font size="15" color="rgb(150, 150, 150)"><b>Understanding IDs</b></font>
IDs are short codes that represent an object some uploaded on Roblox. These can be used to set a decal/texture or a mesh's appearance.

Usually, you'd have to open the Roblox website, and head to the creator store to find these. However, thanks to the marketplace tool, this is no longer necessary.

{split}

<font size="15" color="rgb(150, 150, 150)"><b>Getting IDs</b></font>
After searching and finding the asset you want to use, you can press its icon, and copy the code displayed inside the icon.

You must paste said ID into the corresponding field when using the Texture tool or the Mesh tool. Once done, your decal/mesh should now have the asset applied to it.

{split}

<font size="15" color="rgb(150, 150, 150)"><b>Improving results</b></font>
Search results might not be optimal, hence why you must sometimes use the <b>minimum creation year</b> setting sometimes.

If you know when what you're looking for has become trendy, you can always set this setting to the years that elapsed between today and when it became popular.

For instance: when searching nyan cat, you might want to use a value between 7 and 14, since it was when said meme was popular.]]

local SearchItem = "Decal"
local Page = 1
local ElementsNumber = 0
local FirstTimeEquipped = true
local IsSearching = false
local UseHttp

local UI, UIUpdater

function MarketplaceTool.Equip()
	-- Enables the tool's equipped functionality

	-- Start up our interface
	ShowUI()
	if FirstTimeEquipped == true then
		FirstTimeEquipped = false
		Search("", Page, false)
	end
end

function MarketplaceTool.Unequip()
	-- Disables the tool's equipped functionality

	-- Clear unnecessary resources
	HideUI()

end

function ShowUI()
	
	UseHttp = Options.EnableAPIs == true and Core.SyncAPI:Invoke("IsHttpServiceEnabled") or false
	-- Creates and reveals the UI

	-- Reveal UI if already created
	if MarketplaceTool.UI and MarketplaceTool.UI.Parent ~= nil then

		-- Reveal the UI
		UI.Visible = true

		-- Update the UI every 0.1 seconds
		UIUpdater = Support.ScheduleRecurringTask(UpdateUI, 0.1)

		-- Skip UI creation
		return

	end
	
	if MarketplaceTool.UI then
		MarketplaceTool.UI:Destroy()
	end

	-- Create the UI
	UI = Core.Interfaces.BTMarketplaceGUI:Clone()
	UI.Parent = Core.UI
	UI.Visible = true
	
	MarketplaceTool.UI = UI

	-- References to UI elements
	local DecalButton = UI.Status.Decals.Button
	local MeshButton = UI.Status.Meshes.Button
	local SearchBox = UI.Search.SearchBox.SearchInput
	local YearOption = UI.CreationOption.Input.TextBox
	
	MeshButton.Parent.Visible = UseHttp

	-- Enable the collision status switch
	DecalButton.Activated:Connect(function ()
		game:GetService("SoundService"):PlayLocalSound(Sounds:WaitForChild("Press"))
		SearchItem = "Decal"
		Page = 1
		Core.ToggleSwitch('Decals', UI.Status)
		Search(tostring(SearchBox.Text) or "", Page, false)
	end)
	MeshButton.Activated:Connect(function ()
		game:GetService("SoundService"):PlayLocalSound(Sounds:WaitForChild("Press"))
		SearchItem = "MeshPart"
		Page = 1
		Core.ToggleSwitch('Meshes', UI.Status)
		Search(tostring(SearchBox.Text) or "", Page, false)
	end)
	MeshButton.MouseEnter:Connect(function ()
		game:GetService("SoundService"):PlayLocalSound(Sounds:WaitForChild("Hover"))
	end)
	DecalButton.MouseEnter:Connect(function ()
		game:GetService("SoundService"):PlayLocalSound(Sounds:WaitForChild("Hover"))
	end)
	
	SearchBox.Focused:Connect(function ()
		SearchBox.FocusLost:Connect(function ()
			Page = 1
			Search(tostring(SearchBox.Text) or "", Page, false)
		end)
	end)
	
	UI.CreationOption.Visible = false
	
	if Core.Options.EnableAPIs == false then
		UI.CreationOption.Visible = true
		
		YearOption.Focused:Connect(function ()
			YearOption.FocusLost:Connect(function ()
				MarketplaceTool.CreationYear = tonumber(YearOption.Text) or 0
				YearOption.Text = MarketplaceTool.CreationYear
				Page = 1
				Search(tostring(SearchBox.Text) or "", Page, false)
			end)
		end)
	end
	

	-- Hook up manual triggering
	local SignatureButton = UI:WaitForChild('Title'):WaitForChild('Signature')
	ListenForManualWindowTrigger(MarketplaceTool.ManualText, MarketplaceTool.Color.Color, SignatureButton)
	
	-- Update the UI every 0.1 seconds
	UIUpdater = Support.ScheduleRecurringTask(UpdateUI, 0.25)

end

function UpdateUI()
	-- Updates information on the UI

	-- Make sure the UI's on
	if not UI then
		return
	end

	-- Check the common collision status of selection
	if UI.Search.Images.CanvasPosition.Y >= UI.Search.Images.AbsoluteCanvasSize.Y - UI.Search.Images.AbsoluteSize.Y and IsSearching == false then
		Page = Page + 1
		Search(tostring(UI.Search.SearchBox.SearchInput.Text) or "", Page, true)
	end

end

function HideUI(Toggle)
	-- Hides the tool UI

	-- Make sure there's a UI
	if not UI then
		return
	end

	-- Hide the UI
	UI.Visible = false

	-- Stop updating the UI
	UIUpdater:Stop()

end

function Search(Input, Page, Cumulate)
	
	local Content, IDWasLoaded, NextPage = {}, true, 1
	
	IsSearching = true
	
	if Cumulate == false then
		local OtherButtons = UI.Search.Images:GetChildren()
		for _, OtherElement in pairs(OtherButtons) do
			if OtherElement.Name ~= "Example" and OtherElement:IsA("Frame") then
				OtherElement:Destroy()
			end
		end
		Page = 1
	end
	
	Content, IDWasLoaded, NextPage = Core.SyncAPI:Invoke('SearchAsset', SearchItem, Input, Page, {UseHttp = UseHttp, Time = MarketplaceTool.CreationYear}) 
	
	local ItemLoaded = ElementsNumber
	
	if type(Content) == "table" then --> The value returned was a table
		if UseHttp then
			for _, Data in pairs(Content) do



				if IsSearching == false then return elseif Data == {} or not Data.asset.id then continue end

				--> Also remove short audios to further avoid loading sound effects:

				local button = UI.Search.Images.Example:Clone()
				button.Preview.Image = "https://www.roblox.com/asset-thumbnail/image?assetId=".. Data.asset.id .."&width=420&height=420&format=png"
				button.Name = "ImageNumber" .. ItemLoaded + 1
				button.LayoutOrder = ItemLoaded + 1
				button.ID.Text = Data.asset.id
				button.Parent = UI.Search.Images
				button.Visible = true
				
				--> Select audio:
				button:WaitForChild("Preview").Activated:Connect(function()

					--> Disable any other hover.

					local EveryOtherButtons = UI.Search.Images:GetChildren()

					for _, Hover in pairs(EveryOtherButtons) do
						if Hover.Name ~= "Example" and Hover:IsA("Frame") then
							Hover.ID:RemoveTag("STATE_Displayed")
						end
					end

					button.ID:AddTag("STATE_Displayed")

				end)

				--> Toggle audio as favourite:

				ItemLoaded += 1

				if ItemLoaded / 4 * UI.Search.Images.Example.AbsoluteSize.Y > UI.Search.Images.CanvasSize.Y.Offset then
					--				UI.Search.Images.CanvasSize = UDim2.new(UI.Search.Images.CanvasSize.X.Scale, UI.Search.Images.CanvasSize.X.Offset, UI.Search.Images.CanvasSize.Y.Scale, UI.Search.Images.CanvasSize.Y.Offset + 50)
				end

			end
		else
			for _, Data in pairs(Content) do



				if IsSearching == false then return elseif Data == {} or not Data.AssetId then continue end

				--> Also remove short audios to further avoid loading sound effects:

				local button = UI.Search.Images.Example:Clone()
				button.Preview.Image = "https://www.roblox.com/asset-thumbnail/image?assetId=".. Data.AssetId .."&width=420&height=420&format=png"
				button.Name = "ImageNumber" .. ItemLoaded + 1
				button.LayoutOrder = ItemLoaded + 1
				button.ID.Text = Data.AssetId
				button.Parent = UI.Search.Images
				button.Visible = true

				--> Select audio:
				button:WaitForChild("Preview").Activated:Connect(function()

					--> Disable any other hover.

					local EveryOtherButtons = UI.Search.Images:GetChildren()

					for _, Hover in pairs(EveryOtherButtons) do
						if Hover.Name ~= "Example" and Hover:IsA("Frame") then
							Hover.ID:RemoveTag("STATE_Displayed")
						end
					end

					button.ID:AddTag("STATE_Displayed")

				end)

				--> Toggle audio as favourite:

				ItemLoaded += 1

				if ItemLoaded / 4 * UI.Search.Images.Example.AbsoluteSize.Y > UI.Search.Images.CanvasSize.Y.Offset then
					--				UI.Search.Images.CanvasSize = UDim2.new(UI.Search.Images.CanvasSize.X.Scale, UI.Search.Images.CanvasSize.X.Offset, UI.Search.Images.CanvasSize.Y.Scale, UI.Search.Images.CanvasSize.Y.Offset + 50)
				end

			end
		end
		
		Page = NextPage

		ElementsNumber += ItemLoaded
		
		IsSearching = false

--[[	if (ElementsNumber < math.round(UI.Search.Images.AbsoluteSize.Y * 4 * 50) and not IDWasLoaded and ItemLoaded > 0) then
			canLoad = true
			checkIfPageHasEnded()
		end ]]	

		

		return ElementsNumber --> Return the number of Content loaded

	else
		warn(Content) --> Print error message to console
		
		IsSearching = false
		Page = ""
	end
end

-- Return the tool
return MarketplaceTool