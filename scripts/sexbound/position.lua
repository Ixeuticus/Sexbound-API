--- Position Module.
-- @module position
position = {}

require "/scripts/util.lua"

--- Initializes the position module.
position.init = function()  
  local positionConfig = config.getParameter("sexboundConfig").position
  
  -- Try to load in position settings
  if (positionConfig ~= nil) then
    util.each(positionConfig, function(k,v)
      self.sexboundConfig.position[k] = v
    end)
  end
  
  -- Set the default position as current
  self.current = self.sexboundConfig.position.default
end

position.setupSexPosition = function()
  local minTempo = self.current.minTempo
  local maxTempo = self.current.maxTempo
  local sustainedInterval = self.current.sustainedInterval
  
  if ( minTempo == nil ) then minTempo = 1 end
  
  if ( maxTempo == nil ) then maxTempo = 1 end
  
  if ( sustainedInterval == nil ) then sustainedInterval = 1 end
  
  self.current.minTempo = util.randomInRange(minTempo)
  self.current.nextMinTempo = util.randomInRange(minTempo)
  
  self.current.maxTempo = util.randomInRange(maxTempo)
  self.current.nextMaxTempo = util.randomInRange(maxTempo)
  
  self.current.sustainedInterval = util.randomInRange(sustainedInterval)
  self.current.nextSustainedInterval = util.randomInRange(sustainedInterval)
end

position.changePosition = function(key)
  local newSexPosition = self.sexboundConfig.position[key] 

  if (newSexPosition ~= nil) then
    self.current = newSexPosition
    
    position.setupSexPosition()
  end
end

position.selectedSexPosition = function()
  return self.current
end