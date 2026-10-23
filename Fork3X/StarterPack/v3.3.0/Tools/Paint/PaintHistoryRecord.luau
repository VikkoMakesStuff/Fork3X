local Tool = script.Parent.Parent.Parent
local Core = require(Tool.Core)

-- Libraries
local Libraries = Tool:WaitForChild 'Libraries'
local Support = require(Libraries:WaitForChild 'SupportLibrary')

local PaintHistoryRecord = {}
PaintHistoryRecord.__index = PaintHistoryRecord

function PaintHistoryRecord.new()
    local self = setmetatable({}, PaintHistoryRecord)

    -- Include selection
    self.Selection = Support.CloneTable(Core.Selection.Items)
    self.Parts = Support.CloneTable(Core.Selection.Parts)

    -- Initialize color data
    self.InitialColor = Support.GetMemberMap(self.Parts, 'Color')
    self.TargetColor = nil

    -- Initialize union data
    self.InitialUnionColoring = {}
    for _, Part in pairs(self.Parts) do
		if Part:IsA 'UnionOperation' or Part:IsA 'PartOperation'then
            self.InitialUnionColoring[Part] = Part.UsePartColor
        end
    end

    -- Return new record
    return self
end

function PaintHistoryRecord:Unapply()
    local Changes = {}

    -- Assemble change list
    for _, Part in ipairs(self.Parts) do
        table.insert(Changes, {
            Part = Part,
            Color = self.InitialColor[Part],
            UnionColoring = self.InitialUnionColoring[Part]
        })
    end

    -- Push changes
    Core.SyncAPI:Invoke('SyncColor', Changes)

    -- Restore selection
    Core.Selection.Replace(self.Selection)
end

function PaintHistoryRecord:Apply(KeepSelection)
	local Changes = {}
	
	local Changed = {}

    -- Assemble change list
    for _, Part in ipairs(self.Parts) do
        table.insert(Changes, {
            Part = Part,
            Color = self.TargetColor,
            UnionColoring = true
		})
		
		if not Core.Plugin then
			Part.Color = self.TargetColor
		end
    end

    -- Push changes
	local Success, EventualError = pcall(Core.SyncAPI.Invoke, Core.SyncAPI, 'SyncColor', Changes)
	
	if not Success then
		for Part, InitialColor in self.InitialColor do
			Part.Color = InitialColor
		end
		
		warn("[FORK3X]: An error occured when using the Paint Tool: " .. EventualError .. "\n\nIf this isn't a modified version of Fork3X, please report this error to the creator.")
	end

    -- Restore selection
    if not KeepSelection then
        Core.Selection.Replace(self.Selection)
    end
end

return PaintHistoryRecord