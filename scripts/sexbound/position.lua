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
  
  if (self.isHavingSex) then
    -- Move the npc's facial hair to the correct spot
    if (animator.hasTransformationGroup("npc-facial-hair") and self.currentPosition.npcFacialHairOffset ~= nil) then
      animator.resetTransformationGroup("npc-facial-hair")
      
      animator.translateTransformationGroup("npc-facial-hair", self.currentPosition.npcFacialHairOffset)
    end
  
    -- Move the npc's facial mask to the correct spot
    if (animator.hasTransformationGroup("npc-facial-mask") and self.currentPosition.npcFacialMaskOffset ~= nil) then
      animator.resetTransformationGroup("npc-facial-mask")
      
      animator.translateTransformationGroup("npc-facial-mask", self.currentPosition.npcFacialMaskOffset)
    end
  
    -- Move the npc's hair to the correct spot
    if (animator.hasTransformationGroup("npc-hair") and self.currentPosition.npcHairOffset ~= nil) then
      animator.resetTransformationGroup("npc-hair")
      
      animator.translateTransformationGroup("npc-hair", self.currentPosition.npcHairOffset)
    end
    
    -- Move the npc's head to the correct spot
    if (animator.hasTransformationGroup("npc-head") and self.currentPosition.npcHeadOffset ~= nil) then
      animator.resetTransformationGroup("npc-head")
      
      animator.translateTransformationGroup("npc-head", self.currentPosition.npcHeadOffset)
    end

    -- Move the player's facial hair to the correct spot
    if (animator.hasTransformationGroup("player-facial-hair") and self.currentPosition.playerFacialHairOffset ~= nil) then
      animator.resetTransformationGroup("player-facial-hair")
      
      animator.translateTransformationGroup("player-facial-hair", self.currentPosition.playerFacialHairOffset)
    end
    
    -- Move the players's facial mask to the correct spot
    if (animator.hasTransformationGroup("player-facial-mask") and self.currentPosition.playerFacialMaskOffset ~= nil) then
      animator.resetTransformationGroup("player-facial-mask")
      
      animator.translateTransformationGroup("player-facial-mask", self.currentPosition.playerFacialMaskOffset)
    end
    
    -- Move the player's hair to the correct spot
    if (animator.hasTransformationGroup("player-hair") and self.currentPosition.playerHairOffset ~= nil) then
      animator.resetTransformationGroup("player-hair")
      
      animator.translateTransformationGroup("player-hair", self.currentPosition.playerHairOffset)
    end
    
    -- Move the player's head to the correct spot
    if (animator.hasTransformationGroup("player-head") and self.currentPosition.playerHeadOffset ~= nil) then
      animator.resetTransformationGroup("player-head")
      
      animator.translateTransformationGroup("player-head", self.currentPosition.playerHeadOffset)
    end
  end
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