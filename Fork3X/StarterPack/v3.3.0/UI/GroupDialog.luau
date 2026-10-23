local Root = script.Parent.Parent
local Vendor = Root:WaitForChild('Vendor')
local Sounds = Root:WaitForChild("Sounds")
local Support = require(Root:WaitForChild("Libraries"):WaitForChild("SupportLibrary"))

-- Libraries
local Roact = require(Vendor:WaitForChild('Roact'))
local new = function(Type, props, ...)
	props["RBXTAG_Native"] = true

	return Roact.createElement(Type, props, ...)
end

-- Services
local TextService = game:GetService("TextService")

local function GroupDialog(props)
	local MainObjectRef = Roact.createRef()

	local function SetSize(rbx)
		if rbx then
			rbx.Parent:ResetPropertyToDefault("Size")
			rbx:ResetPropertyToDefault("Size")

			local OriginalWindowSize = rbx.Parent:GetStyled("Size")
			local OriginalTextSize = rbx:GetStyled("Size")

			local WindowXSize = OriginalWindowSize.X.Offset ~= 0 and OriginalWindowSize.X.Offset or 200
			local TextXSize = OriginalTextSize.X.Offset ~= 0 and OriginalTextSize.X.Offset or 200

			-- Create the parameters for the text size operation
			local TextParams = Instance.new("GetTextBoundsParams")
			TextParams.Font = rbx:GetStyled("FontFace")
			TextParams.RichText = true
			TextParams.Size = rbx:GetStyled("TextScaled") == false and rbx:GetStyled("TextSize") or 14
			TextParams.Width = TextXSize
			TextParams.Text = props.Text
			
			-- Calculate the size
			local TextSize = TextService:GetTextBoundsAsync(TextParams)
			
			-- Use it to determine the window's size
			rbx.Parent.Size = UDim2.new(0, WindowXSize, 0, TextSize.Y + 23 + 30 + 20 + 10 + OriginalWindowSize.Y.Offset)
			rbx.Size = UDim2.new(1, 0, 1, -77)
		end
	end
	
	return new('ScreenGui', {}, {
		Dialog = new('Frame', {
			AnchorPoint = Vector2.new(0.5, 0.5);
			Position = UDim2.new(0.5, 0, 0.5, 0);
			RBXTAG_Window = true;
			[Roact.Ref] = MainObjectRef
		}, {
			FirstButton = new('TextButton', {
				AnchorPoint = Vector2.new(0, 1);
				Modal = true;
				Position = UDim2.new(0, 0, 1, 0);
				Size = UDim2.new(0.5, -5, 0, 23);
				Text = props.Option1;
				[Roact.Event.Activated] = function (rbx)
					props.Function1()
				end;
			});
			SecondButton = new('TextButton', {
				AnchorPoint = Vector2.new(1, 1);
				Modal = true;
				Position = UDim2.new(1, 0, 1, 0);
				Size = UDim2.new(0.5, -5, 0, 23);
				Text = props.Option2;
				[Roact.Event.Activated] = function (rbx)
					props.Function2()
				end;
			});
			Title = new('TextLabel', {
				Size = UDim2.new(1, 0, 0, 30);
				Text = "Arrangement";
			});
			Text = new('TextLabel', {
				Size = UDim2.new(1, 0, 1, -67);
				Position = UDim2.new(0, 0, 0, 37),
				RichText = true;
				Text = props.Text;
				[Roact.Ref] = SetSize,
				[Roact.Event.StyledPropertiesChanged] = SetSize,
			});
		},  script.Name, {props = props, state = {}, MainObjectRef = MainObjectRef});
	})
end

return GroupDialog