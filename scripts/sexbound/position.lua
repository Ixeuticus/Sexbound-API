--- Position Module.
-- @module position
position = {}

require "/scripts/util.lua"

--- Initializes the position module.
position.init = function()  
  message.setHandler("changePosition", function(_, _, change)
    self.currentPositionIndex = self.currentPositionIndex + change
  
    if (self.currentPositionIndex <= 0) then
      self.currentPositionIndex = self.positionCount
    end
    
    if (self.currentPositionIndex > self.positionCount) then
      self.currentPositionIndex = 1
    end
  
    position.changePosition(self.currentPositionIndex)
    
    animator.setAnimationState("sex", self.currentPosition.animationState)
    
    animator.setGlobalTag("position", self.currentPosition.animationState)
  end)
  
  local positionConfig = config.getParameter("sexboundConfig").position
  
  -- Try to load in sextoy settings
  if (positionConfig ~= nil) then
    util.each(positionConfig, function(k,v)
      self.sexboundConfig.position[k] = v
    end)
  end

  -- Set the default position as current
  self.currentPositionIndex = 1
  
  self.currentPosition = {}
  
  -- Setup the position count
  self.positionCount = 0
  
  -- Count positions
  if (self.sexboundConfig.position ~= nil) then
    util.each(self.sexboundConfig.position, function(k, v)
      self.positionCount = self.positionCount + 1
    end)
  end
  
  -- Change position to first position
  position.changePosition(1)
end

position.setupSexPosition = function()
  local position = self.sexboundConfig.position[self.currentPositionIndex]

  local minTempo          = position.minTempo
  local maxTempo          = position.maxTempo
  local sustainedInterval = position.sustainedInterval
  
  if ( minTempo == nil ) then minTempo = 1 end
  
  if ( maxTempo == nil ) then maxTempo = 1 end
  
  if ( sustainedInterval == nil ) then sustainedInterval = 1 end
  
  -- Store the position data
  self.currentPosition = position

  -- Modify the position data
  self.currentPosition.minTempo     = util.randomInRange(minTempo)
  self.currentPosition.nextMinTempo = util.randomInRange(minTempo)
  
  self.currentPosition.maxTempo     = util.randomInRange(maxTempo)
  self.currentPosition.nextMaxTempo = util.randomInRange(maxTempo)
  
  self.currentPosition.sustainedInterval     = util.randomInRange(sustainedInterval)
  self.currentPosition.nextSustainedInterval = util.randomInRange(sustainedInterval)
end

position.changePosition = function(index)
  local newSexPosition = self.sexboundConfig.position[index] 

  if (newSexPosition ~= nil) then
    self.current = newSexPosition
    
    position.setupSexPosition()
  end
end

position.selectedSexPosition = function()
  return self.currentPosition
end