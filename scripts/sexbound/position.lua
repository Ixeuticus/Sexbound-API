--- Position Module.
-- @module position
position = {}

require "/scripts/sexbound/helper.lua"
require "/scripts/vec2.lua"

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

    actor.resetAllActors()
    
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

  actor.resetAllActors()
end

position.adjustTransformations = function()
  actor.resetTransformationGroups()

  local maxActors = 2
  local offsetAll = {0, 0}
  
  if (self.currentPosition.maxAllowedActors ~= nil) then
    maxActors = self.currentPosition.maxAllowedActors -- Normally is 2
  end
  
  for i=1, maxActors do
    offsetAll = {0, 0}
  
    if (self.currentPosition.offsetAll ~= nil) then
      offsetAll = self.currentPosition.offsetAll[i]
    end
  
    helper.each({"Body", "Climax", "Head"}, function(k2, v2)
      if (self.currentPosition["offset" .. v2] ~= nil) then
        position.translateParts(i, v2, self.currentPosition["offset" .. v2][i], offsetAll)
      end
        
      if (self.currentPosition["flip" .. v2] ~= nil and self.currentPosition["flip" .. v2][i] == true) then
        position.flipParts(i, v2)
      end
    end)
  end
end

position.translateParts = function(actorNumber, partName, offset, globalOffset)
  local partsList = {}
  table.insert(partsList, 1, partName)
  
  if (partName == "Body") then partsList = {"ArmBack", "ArmFront", "Body"} end
  
  if (partName == "Head") then partsList = {"FacialHair", "FacialMask", "Hair", "Head"} end
  
  helper.each(partsList, function(k, v)
    if (animator.hasTransformationGroup("actor" .. actorNumber .. v)) then
      position.translatePart(actorNumber, v, vec2.add(offset, globalOffset))
    end
  end)
end

position.translatePart = function(actorNumber, partName, offset)
  animator.resetTransformationGroup("actor" .. actorNumber .. partName)
  
  animator.translateTransformationGroup("actor" .. actorNumber .. partName, offset)
end

position.flipParts = function(actorNumber, partName)
  local partsList = {}
  table.insert(partsList, 1, partName)
  
  if (partName == "Body") then partsList = {"ArmBack", "ArmFront", "Body"} end
  
  if (partName == "Head") then partsList = {"FacialHair", "FacialMask", "Hair", "Head"} end
  
  helper.each(partsList, function(k, v)
    if (animator.hasTransformationGroup("actor" .. actorNumber .. v)) then
      position.flipPart(actorNumber, v)
    end
  end)
end

position.flipPart = function(actorNumber, partName)
  if (animator.hasTransformationGroup("actor" .. actorNumber .. partName)) then
    animator.scaleTransformationGroup("actor" .. actorNumber .. partName, {-1, 1}, {0, 0})
  end
end

position.setupSexPosition = function()
  self.currentPosition = self.sexboundConfig.position[self.currentPositionIndex]

  local minTempo          = self.currentPosition.minTempo
  local maxTempo          = self.currentPosition.maxTempo
  local sustainedInterval = self.currentPosition.sustainedInterval
  
  if ( minTempo == nil ) then self.currentPosition.minTempo = 1 end
  
  if ( maxTempo == nil ) then self.currentPosition.maxTempo = 1 end
  
  if ( sustainedInterval == nil ) then self.currentPosition.sustainedInterval = 1 end

  -- Modify the position data
  self.currentPosition.minTempo     = helper.randomInRange(minTempo)
  self.currentPosition.nextMinTempo = helper.randomInRange(minTempo)
  
  self.currentPosition.maxTempo     = helper.randomInRange(maxTempo)
  self.currentPosition.nextMaxTempo = helper.randomInRange(maxTempo)
  
  self.currentPosition.sustainedInterval     = helper.randomInRange(sustainedInterval)
  self.currentPosition.nextSustainedInterval = helper.randomInRange(sustainedInterval)
  
  position.adjustTransformations()
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