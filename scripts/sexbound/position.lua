--- Position Module.
-- @module position
position = {}

require "/scripts/sexbound/helper.lua"

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

    sex.resetActors()
    
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
    if (sex.isHavingSex()) then
      position.reset()
    end
  end)
  
  -- Set the default position as current
  self.currentPositionIndex = 1
  
  self.currentPosition = {}
  
  -- Setup the position count
  self.positionCount = 0
  
  -- Count positions
  if (self.sexboundConfig.position ~= nil) then
    helper.each(self.sexboundConfig.position, function(k, v)
      self.positionCount = self.positionCount + 1
    end)
  end
  
  -- Change position to first position
  position.changePosition(1)
end

function position.reset()
  self.currentPositionIndex = 1

  position.changePosition(1)

  animator.setAnimationState("sex", position.selectedSexPosition().animationState)

  sex.resetActors()
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
  self.currentPosition.minTempo     = helper.randomInRange(minTempo)
  self.currentPosition.nextMinTempo = helper.randomInRange(minTempo)
  
  self.currentPosition.maxTempo     = helper.randomInRange(maxTempo)
  self.currentPosition.nextMaxTempo = helper.randomInRange(maxTempo)
  
  self.currentPosition.sustainedInterval     = helper.randomInRange(sustainedInterval)
  self.currentPosition.nextSustainedInterval = helper.randomInRange(sustainedInterval)
  
  if (self.isHavingSex) then
    -- Move the player's facial hair to the correct spot
    if (animator.hasTransformationGroup("actor1-facial-hair")) then
      if (self.currentPosition.actor1FacialHairOffset ~= nil) then
        animator.resetTransformationGroup("actor1-facial-hair")
        
        animator.translateTransformationGroup("actor1-facial-hair", self.currentPosition.actor1FacialHairOffset)
      end
      
      if (self.currentPosition.actor1FacialHairFlip) then
        animator.scaleTransformationGroup("actor1-facial-hair", {-1, 1}, {1, 1})
      end
    end
    
    -- Move the players's facial mask to the correct spot
    if (animator.hasTransformationGroup("actor1-facial-mask")) then
      if (self.currentPosition.actor1FacialMaskOffset ~= nil) then
        animator.resetTransformationGroup("actor1-facial-mask")
        
        animator.translateTransformationGroup("actor1-facial-mask", self.currentPosition.actor1FacialMaskOffset)
      end
      
      if (self.currentPosition.actor1FacialMaskFlip) then
        animator.scaleTransformationGroup("actor1-facial-mask", {-1, 1}, {1, 1})
      end
    end
    
    -- Move the player's hair to the correct spot
    if (animator.hasTransformationGroup("actor1-hair")) then
      animator.resetTransformationGroup("actor1-hair")
      
      if (self.currentPosition.actor1HairOffset ~= nil) then
        animator.translateTransformationGroup("actor1-hair", self.currentPosition.actor1HairOffset)
      end
      
      if (self.currentPosition.actor1HairFlip) then
        animator.scaleTransformationGroup("actor1-hair", {-1, 1}, {1, 1})
      end
    end

    -- Move the player's head to the correct spot
    if (animator.hasTransformationGroup("actor1-head") and self.currentPosition.actor1HeadOffset ~= nil) then
      animator.resetTransformationGroup("actor1-head")
      
      animator.translateTransformationGroup("actor1-head", self.currentPosition.actor1HeadOffset)
    end
  
    -- Move the npc's facial hair to the correct spot
    if (animator.hasTransformationGroup("actor2-facial-hair")) then
      if (self.currentPosition.actor2FacialHairOffset ~= nil) then
        animator.resetTransformationGroup("actor2-facial-hair")
        
        animator.translateTransformationGroup("actor2-facial-hair", self.currentPosition.actor2FacialHairOffset)
      end
      
      if (self.currentPosition.actor2FacialHairFlip) then
        animator.scaleTransformationGroup("actor2-facial-hair", {-1, 1}, {1, 1})
      end
    end
    
    -- Move the npc's facial mask to the correct spot
    if (animator.hasTransformationGroup("actor2-facial-mask")) then
      if (self.currentPosition.actor2FacialMaskOffset ~= nil) then
        animator.resetTransformationGroup("actor2-facial-mask")
        
        animator.translateTransformationGroup("actor2-facial-mask", self.currentPosition.actor2FacialMaskOffset)
      end
      
      if (self.currentPosition.actor2FacialMaskFlip) then
        animator.scaleTransformationGroup("actor2-facial-mask", {-1, 1}, {1, 1})
      end
    end

    -- Move the npc's hair to the correct spot
    if (animator.hasTransformationGroup("actor2-hair")) then
      animator.resetTransformationGroup("actor2-hair")
      
      if (self.currentPosition.actor2HairOffset ~= nil) then
        animator.translateTransformationGroup("actor2-hair", self.currentPosition.actor2HairOffset)
      end

      if (self.currentPosition.actor2HairFlip) then
        animator.scaleTransformationGroup("actor2-hair", {-1, 1}, {1, 1})
      end
    end

    -- Move the npc's head to the correct spot
    if (animator.hasTransformationGroup("actor2-head") and self.currentPosition.actor2HeadOffset ~= nil) then
      animator.resetTransformationGroup("actor2-head")
      
      animator.translateTransformationGroup("actor2-head", self.currentPosition.actor2HeadOffset)
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