--- Position Module.
-- @module position
position = {}

require "/scripts/sexbound/helper.lua"
require "/scripts/vec2.lua"

position.data = {
  currentIndex = nil,
  currentPosition = nil,
  count = 0
}

--- Initializes the position module.
position.init = function()
  position.setupMessageHandlers()

  position.data.count = helper.count(self.sexboundConfig.position) -- Count positions
  
  position.changePosition(1) -- Start in position #1
end

position.reset = function()
  position.changePosition(1)

  animator.setAnimationState("sex", position.data.currentPosition.animationState)

  actor.resetAllActors()
end

position.setupMessageHandlers = function()
  -- Handle change position
  message.setHandler("changePosition", function(_, _, change)
    local sexState = sex.getSexState()
  
    -- The state machine must be in the "sexState" state
    if (sexState.stateDesc() ~= "sexState") then return end
  
    -- Check if unique positions have been defined. One is always defined by default.
    if (position.data.count <= 1) then return end
  
    local newIndex = position.data.currentIndex + change
  
    if (newIndex <= 0) then
      newIndex = position.data.count
    end
    
    if (newIndex > position.data.count) then
      newIndex = 1
    end
    
    position.changePosition(newIndex)
    
    animator.setAnimationState("sex", "position" .. newIndex)

    actor.resetAllActors()
  end)
  
  -- Handle reset position
  message.setHandler("reset-position", function()
    if (sex.isHavingSex()) then
      position.reset()
    end
  end)
end

position.adjustTransformations = function()
  actor.resetTransformationGroups()

  actor.resetAllActors()
  
  local currentPosition = position.getCurrentPosition()
  
  for i=1, self.sexboundConfig.actor.maxCount do
    offsetAll = {0, 0}
    
    if currentPosition.offsetAll then
      offsetAll = currentPosition.offsetAll[i]
    end
    
    helper.each({"Body", "Climax", "Head"}, function(k2, v2) -- For each major actor part group
      if (currentPosition["offset" .. v2] ~= nil) then
        position.translateParts(i, v2, currentPosition["offset" .. v2][i], offsetAll)
      end
        
      if (currentPosition["rotate" .. v2] ~= nil) then
        position.rotateParts(i, v2, currentPosition["rotate" .. v2][i])
      end
        
      if (currentPosition["flip" .. v2] ~= nil and currentPosition["flip" .. v2][i] == true) then
        position.flipParts(i, v2)
      end
    end)
  end
end

position.getCurrentPosition = function()
  return self.sexboundConfig.position[ position.data.currentIndex ]
end

position.translateParts = function(actorNumber, partName, offset, offsetAll)
  local partsList = {}
  table.insert(partsList, 1, partName)
  
  if (partName == "Body") then partsList = {"ArmBack", "ArmFront", "Body"} end
  
  if (partName == "Head") then partsList = {"FacialHair", "FacialMask", "Emote", "Hair", "Head"} end
  
  helper.each(partsList, function(k, v)
    if (animator.hasTransformationGroup("actor" .. actorNumber .. v)) then
      position.translatePart(actorNumber, v, vec2.add(offset, offsetAll))
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
  
  if (partName == "Head") then partsList = {"FacialHair", "FacialMask", "Emote", "Hair", "Head"} end
  
  helper.each(partsList, function(k, v)
    if (animator.hasTransformationGroup("actor" .. actorNumber .. v)) then
      position.flipPart(actorNumber, v)
    end
  end)
end

position.rotateParts = function(actorNumber, partName, rotation)
  local partsList = {}
  table.insert(partsList, 1, partName)
  
  if (partName == "Body") then partsList = {"ArmBack", "ArmFront", "Body"} end
  
  if (partName == "Head") then partsList = {"FacialHair", "FacialMask", "Emote", "Hair", "Head"} end
  
  helper.each(partsList, function(k, v)
    if (animator.hasTransformationGroup("actor" .. actorNumber .. v)) then
      position.rotatePart(actorNumber, v, rotation)
    end
  end)
end

position.rotatePart = function(actorNumber, partName, rotation)
  if (animator.hasTransformationGroup("actor" .. actorNumber .. partName)) then
    animator.rotateTransformationGroup("actor" .. actorNumber .. partName, rotation)
  end
end

position.flipPart = function(actorNumber, partName)
  if (animator.hasTransformationGroup("actor" .. actorNumber .. partName)) then
    animator.scaleTransformationGroup("actor" .. actorNumber .. partName, {-1, 1}, {0, 0})
  end
end

position.setupSexPosition = function(index)
  position.data.currentPosition = self.sexboundConfig.position[index]

  local minTempo          = position.data.currentPosition.minTempo
  local maxTempo          = position.data.currentPosition.maxTempo
  local sustainedInterval = position.data.currentPosition.sustainedInterval
  
  if ( minTempo == nil ) then position.data.currentPosition.minTempo = 1 end
  
  if ( maxTempo == nil ) then position.data.currentPosition.maxTempo = 1 end
  
  if ( sustainedInterval == nil ) then position.data.currentPosition.sustainedInterval = 1 end

  -- Modify the position data
  position.data.currentPosition.minTempo     = helper.randomInRange(minTempo)
  position.data.currentPosition.nextMinTempo = helper.randomInRange(minTempo)
  
  position.data.currentPosition.maxTempo     = helper.randomInRange(maxTempo)
  position.data.currentPosition.nextMaxTempo = helper.randomInRange(maxTempo)
  
  position.data.currentPosition.sustainedInterval     = helper.randomInRange(sustainedInterval)
  position.data.currentPosition.nextSustainedInterval = helper.randomInRange(sustainedInterval)
  
  position.adjustTransformations()
end

--- Changes position to specified index.
-- @param index Position number.
position.changePosition = function(index)
  if (self.sexboundConfig.position[index]) then
    position.data.currentIndex = index
  
    position.setupSexPosition(index)
  end
end

position.selectedSexPosition = function()
  return position.data.currentPosition
end