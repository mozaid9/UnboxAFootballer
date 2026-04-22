local BaseService = {}

local assignedPlots = {}
local nextPlotIndex = 1

function BaseService.AssignPlot(player)
	if assignedPlots[player] then
		return assignedPlots[player]
	end

	assignedPlots[player] = {
		plotId = nextPlotIndex,
		displaySlots = 6,
	}
	nextPlotIndex += 1
	return assignedPlots[player]
end

function BaseService.ReleasePlot(player)
	assignedPlots[player] = nil
end

function BaseService.GetPlot(player)
	return assignedPlots[player]
end

return BaseService
