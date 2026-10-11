local Root = script.Parent.Parent
local Libraries = Root:WaitForChild('Libraries')
local Vendor = Root:WaitForChild('Vendor')
local Support = require(Libraries.SupportLibrary)
local Signal = require(Libraries.Signal)
local Maid = require(Libraries.Maid)

-- Libraries
local Roact = require(Vendor:WaitForChild('Roact'))
local fastSpawn = require(Libraries:WaitForChild('fastSpawn'))

-- Roact
local new = Roact.createElement
local NotificationDialog = require(script:WaitForChild('NotificationDialog'))

-- Create component
local Notifications = Roact.PureComponent:extend(script.Name)

function Notifications:init()
	self.Active = true
    self:setState({
       -- ShouldWarnAboutHttpService = false;
		ShouldWarnAboutBeta = true;
	})
	
	--[[
    fastSpawn(function ()
        local Core = self.props.Core
        local IsHttpServiceDisabled = (Core.Mode == 'Tool') and
            not Core.SyncAPI:Invoke('IsHttpServiceEnabled')
		if self.Active and Core.Options.ShowHttpRequestsWarning == true and Core.Options.EnableAPIs ~= true then
            self:setState({
                ShouldWarnAboutHttpService = IsHttpServiceDisabled;
            })
        end
	end)]]
	fastSpawn(function ()
		local IsOutdated, Version, UpdateText = self.props.Core.IsVersionOutdated(Root.Version.Value)

		if self.Active and self.props.Core.Options.ShowUpdateWarning == true then
			self:setState({
				ShouldWarnAboutUpdate = not _G.FORK3X_ReadUpdate and IsOutdated or false;
				UpdateText = UpdateText and ("\n\nHere are some of the main new features in v<b>" .. Version .. "</b>:\n\n" .. UpdateText) or "";
			})
		end
	end)
	fastSpawn(function ()
		local Core = self.props.Core
		local IsNotOnPC = (Core.Mode == 'Tool') and game:GetService("UserInputService").PreferredInput ~= Enum.PreferredInput.KeyboardAndMouse
		if self.Active then
			self:setState({
				ShouldWarnAboutKeybinds = if not _G.FORK3X_ReadControls then IsNotOnPC else false;
			})
		end
	end)
	fastSpawn(function ()
		local Core = self.props.Core
		local IsBeyondLimit = (Core.Mode == 'Tool') and Core.Options.SizeLimit < -4096 and true or false
		if self.Active then
			self:setState({
				ShouldWarnAboutDataStores = IsBeyondLimit;
			})
		end
	end)
end


function Notifications:willUnmount()
    self.Active = false
end

function Notifications:render()
	local Children = {
		Layout = new('UIListLayout', {
			Padding = UDim.new(0, 10);
			FillDirection = Enum.FillDirection.Vertical;
			HorizontalAlignment = Enum.HorizontalAlignment.Left;
			VerticalAlignment = Enum.VerticalAlignment.Center;
			SortOrder = Enum.SortOrder.LayoutOrder;
		});
		DataStoreNotification = self.state.ShouldWarnAboutDataStores and new(NotificationDialog, {
			LayoutOrder = 1;
			ThemeColor = Color3.fromRGB(255, 0, 4);
			NoticeText = "The current save/load size limit can possibly go beyond 4 MB. This means that builds that go beyond this limit might not get saved completely.";
			DetailText = 'Own this place? Set Options.SizeLimit above -4096 (-4095, -4094) to prevent any data wipe. :-)';
			OnDismiss = function ()
				self:setState({
					ShouldWarnAboutDataStores = false;
				})
			end;
		}) or nil;
		KeybindsNotification = self.state.ShouldWarnAboutKeybinds and new(NotificationDialog, {
			LayoutOrder = 2;
			ThemeColor = Color3.fromRGB(150, 20, 220);
			NoticeText = "Fork3X has been updated to the latest version, with some changes concerning how Fork3X works on your device. Make sure to check the ? buttons on the tools to familiarise with the new keybinds.";
			DetailText = 'You can get started by pressing the Fork3X topbar on the right, which should teach you the main keybinds. :-)';
			OnDismiss = function ()
				self:setState({
					ShouldWarnAboutKeybinds = false;
				})
				_G.FORK3X_ReadControls = true
			end;
		}) or nil;
		BetaNotification = self.state.ShouldWarnAboutBeta and new(NotificationDialog, {
			LayoutOrder = 3;
			ThemeColor = Color3.fromRGB(255, 0, 150);
			NoticeText = '<b>This version of Fork3X is a public beta!</b> The main ideas are here, but the tools are extremely buggy. Please report any bug you encounter to the creator of Fork3X.';
			DetailText = "Not satisfied with the beta? You can always re-install the previous version for a more stable experience.";
			TextXAlignment = Enum.TextXAlignment.Left;
			OnDismiss = function ()
				self:setState({
					ShouldWarnAboutBeta = false;
				})
				_G.FORK3X_BetaWarning = true
			end;
		}) or nil;
		UpdateNotification = self.state.ShouldWarnAboutUpdate and new(NotificationDialog, {
			LayoutOrder = 4;
			ThemeColor = Color3.fromRGB(255, 170, 0);
			NoticeText = '<b>A new version of Fork3X is out!</b> To know some of the main changes and how to update, press <i>"WHAT CAN I DO?"</i>';
			DetailText = (
				(self.props.Core.Mode == 'Plugin') and
				'To update plugins, go to\n<b>PLUGINS</b> > <b>Manage Plugins</b> :-)' or
				"Own this place? Simply <b>reinsert</b> the latest Building Tools model from the GitHub/test place in your game. :-)"
			) .. self.state.UpdateText;
			TextXAlignment = Enum.TextXAlignment.Left;
			OnDismiss = function ()
				self:setState({
					ShouldWarnAboutUpdate = false;
				})
				_G.FORK3X_ReadUpdate = true
			end;
		}) or nil;
	}

	-- Build buttons for each tool
	for Index, Notification in next, self.props.Notifications do
		local AutoSelect = self.props.Core.IsGamepad() and next(self.props.Notifications, Index) == nil
		
		Children[tostring(Index)] = new(NotificationDialog, {
			LayoutOrder = 2 + Index;
			ThemeColor = Notification.ThemeColor;
			NoticeText = Notification.NoticeText;
			DetailText = Notification.DetailText;
			TextXAlignment = Notification.TextXAlignment;
			AutoSelect = AutoSelect;
			OnDismiss = function (rbx)
				rbx:Destroy()
				
				Children[tostring(Index)] = nil
				self.props.Notifications[Index] = nil
			end;
		})
	end

	if self.props.Core.IsGamepad() and Support.CountKeys(Children) == 1 then
		game:GetService("GuiService").SelectedObject = nil
	end
	
    return new('ScreenGui', {}, {
        Container = new('Frame', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(0.5, 0, 0.5, 0);
			Size = UDim2.new(0, 300, 1, 0);
			[Roact.Children] = Children;
        });
    })
end

return Notifications