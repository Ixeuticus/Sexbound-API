--- Position Module.
-- @module position
position = {}

require "/scripts/util.lua"

--- Initializes the position module.
position.init = function()
  -- Handle change position
  message.setHandler("changePosition", function(_, _, change)
    local sexState = sex.getSexState()
  
    -- The state machine must be in the "sexState" state
    if (sexState.stateDesc() ~= "sexState") then return end
  
    -- Check if unique positions have been defined. One is always defined by default.
    if (self.positionCount <= 1) then return end
  
    self.currentPositionIndex = self.currentPositionIndex + change
  
    if (self.currentPositionIndex <= 0) then
      self.currentPositionIndex = self.positionCount
    end
    
    if (self.currentPositionIndex > self.positionCount) then
      self.currentPositionIndex = 1
    end
  
    position.changePosition(self.currentPositionIndex)
    
    animator.setAnimationState("sex", "position" .. self.currentPositionIndex)
    
    if (sextalk.isEnabled()) then
      if (self.sexboundConfig.sextalk.trigger == "statemachine") then
        sextalk.sayNext("sexState")
      end
      
      if (self.sexboundConfig.sextalk.trigger == "animation") then
        local animationState = animator.animationState("sex")

        sextalk.sayNext(animationState)
      end
      
      self.timers.talk = 0
    end
  end)
  
  -- Handle reset position
  message.setHandler("reset-position", function()
    self.currentPositionIndex = 1
  
    position.changePosition(1)
  end)
  
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