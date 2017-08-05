--- Sex Module.
-- @module sex
sex = {}

sex.majorVersion = 1

require "/scripts/stateMachine.lua"
require "/scripts/sexbound/pov.lua"
require "/scripts/sexbound/pregnant.lua"
require "/scripts/sexbound/emote.lua"
require "/scripts/sexbound/moan.lua"
require "/scripts/sexbound/portrait.lua"
require "/scripts/sexbound/position.lua"
require "/scripts/sexbound/sextalk.lua"
require "/scripts/sexbound/sextoy.lua"
require "/scripts/sexbound/sexui.lua"

--- Initializes the sex module.
function sex.init()
  object.setInteractive(true)

  message.setHandler("isClimaxing", function()
    self.isCumming = true
    return {}
  end)
  
  message.setHandler("sync-ui", function()
    local data = {}
    
    data.animator = {}
    data.climax = {}
    data.sex = {}
    data.sextalk = {}
    data.sextoy = {}
    
    data.animator.rate = self.animationRate
    data.animator.currentState = animator.animationState("sex")
    
    data.climax.points  = self.climaxPoints
    
    data.sex.currentState  = self.sexStates.stateDesc()
    
    data.portrait = self.sexboundConfig.portrait
    
    data.position = position.selectedSexPosition()
    
    data.pov = self.sexboundConfig.pov
    
    data.sextalk.currentDialog = sextalk.getCurrentDialog()
    
    data.sextoy.slot1 = self.sexboundConfig.sextoy.slot1[self.slot1Current]
    
    return data
  end)
  
  -- Handle request to return Animation Data
  message.setHandler("sync-position", function()
    local data = {}
    
    data.position = position.selectedSexPosition()
    
    return data
  end)
  
  -- Handle request to check if is occupied
  message.setHandler("isOccupied", function()
    return sex.isOccupied()
  end)
  
  -- Load the default Sexbound config file
  self.sexboundConfig = root.assetJson("/scripts/sexbound/default.config")
  
  -- Store the custom sex config
  local sexCustomConfig = config.getParameter("sexboundConfig").sex
  
  -- Insert custom sex config
  util.each(sexCustomConfig, function(k, v)
    self.sexboundConfig.sex[k] = v
  end)
  
  self.animationRate = 1
  
  -- Predefined sex states
  self.sexStates = stateMachine.create({
    "idleState",
    "sexState",
    "climaxState",
    "exitState"
  })
  
  -- Temp store climax data
  self.climaxPoints = {}
  self.climaxPoints.current = 0
  self.climaxPoints.min = self.sexboundConfig.sex.minClimaxPoints
  self.climaxPoints.max = self.sexboundConfig.sex.maxClimaxPoints
  self.climaxPoints.threshold = self.sexboundConfig.sex.climaxThreshold
  self.climaxPoints.autoClimax = self.sexboundConfig.sex.autoClimax

  self.autoMoan = self.sexboundConfig.sex.autoMoan
  
  self.autoRestart = self.sexboundConfig.sex.autoRestart
  
  -- Temp store cooldown data 
  self.cooldowns = {}
  self.cooldowns.emote = util.randomInRange(self.sexboundConfig.sex.emoteCooldown)
  self.cooldowns.moan  = util.randomInRange(self.sexboundConfig.sex.moanCooldown)
  self.cooldowns.talk  = util.randomInRange(self.sexboundConfig.sex.talkCooldown)

  self.objectType = config.getParameter("objectType")
  
  self.isCumming = false
  self.isHavingSex = false
  self.isReseting = false
  
  resetTimers()
  
  -- Init emote module
  emote.init()
  
  -- Init moan module
  moan.init()
  
  -- Init portrait module
  portrait.init()
  
  -- Init position module
  position.init()
  
  -- Init pov module
  pov.init()
  
  -- Init pregnant module
  pregnant.init()
  
  -- Init sextalk module
  sextalk.init()
  
  -- Init sextoy module
  sextoy.init()
  
  -- Init sexui module
  sexui.init()
  
  -- Change position to default to set the anim rate variables
  position.changePosition("default")
end

---Handles the interact event of the entity.
function sex.handleInteract()
  self.isHavingSex = true

  -- Invoke script pane which will force player to lounge in the object
  if (sexui.isEnabled()) then
    return {"ScriptPane", "/interface/sexbound/sexui.config"} end

  return nil
end

function sex.isHavingSex()
  return self.isHavingSex
end

function sex.isOccupied()
  if (world.loungeableOccupied(entity.id())) then
    return true
  end
  
  return false
end

function sex.getAnimationRate()
  return self.animationRate
end

function sex.getAutoMoan()
  return self.autoMoan
end

function sex.getAutoRestart()
  return self.autoRestart
end

---Updates the timers and state machine.
--@param dt delta time
--@param[opt] callback function to execute afters updating timers and state machine
function sex.loop(dt, callback)
  self.timers.talk  = self.timers.talk  + dt
  
  self.timers.emote = self.timers.emote + dt
  
  self.timers.moan  = self.timers.moan  + dt
  
  -- Check if an this entity is occupied
  if (self.objectType == "loungeable") then
    if (sex.isOccupied()) then
      self.isHavingSex = true
    else
      self.isHavingSex = false
    end
  end
  
  -- Update the state
  self.sexStates.update(dt)
  
  -- Execute your logic as a callback within this sex loop
  if (callback ~= nil) then
    callback()
  end
end

function sex.isCumming()
  return self.isCumming
end

function sex.setIsCumming(value)
  self.isCumming = value
end

function sex.setIsReseting(value)
  self.isReseting = value
end

function sex.isReseting()
  return self.isReseting
end

function sex.setIsHavingSex(value)
  self.isHavingSex = value
end

function sex.getClimaxPause()
  return self.sexboundConfig.sex.climaxPause
end

function sex.getResetPause()
  return self.sexboundConfig.sex.resetPause
end

function sex.getTimer(name)
  return self.timers[name]
end

function sex.setTimer(name, value)
  self.timers[name] = value
  return self.timers[name]
end

---Try to Cum.
function sex.tryToCum(callback)
  if (self.climaxPoints.current >= self.climaxPoints.threshold) then
    local autoClimax = self.climaxPoints.autoClimax

    -- Execute your cum logic as a callback
    if (callback ~= nil) then
      callback()
    end
    
    if (autoClimax or self.isCumming) then
      self.isCumming = true
      self.climaxPoints.current = 0
      
      return true
    end
  end
  
  return false
end

---Try to Talk.
function sex.tryToTalk(callback)
  if not (sextalk.isEnabled()) then return false end

  if (self.timers.talk >= self.cooldowns.talk) then
    self.timers.talk = 0
  
    self.cooldowns.talk = util.randomInRange(self.sexboundConfig.sex.talkCooldown)
  
    -- Execute your talk logic as a callback
    if (callback ~= nil) then
      callback()
    end

    return true
  end
  
  return false
end

---Try to Emote.
function sex.tryToEmote(callback)
  if not (emote.isEnabled()) then return false end

  if (self.timers.emote >= self.cooldowns.emote) then 
    self.timers.emote = 0
    
    self.cooldowns.emote = util.randomInRange(self.sexboundConfig.sex.emoteCooldown)
    
    -- Execute your emote logic as a callback
    if (callback ~= nil) then
      callback()
    end
    
    return true
  end
  
  return false
end

---Try to Moan.
function sex.tryToMoan(callback)
  if (self.timers.moan >= self.cooldowns.moan) then 
    self.timers.moan = 0
    
    self.cooldowns.moan  = util.randomInRange(self.sexboundConfig.sex.moanCooldown)
    
    -- Execute your moan logic as a callback
    if (callback ~= nil) then
      callback()
    end
    
    return true
  end
  
  return false
end

---Adjusts the animation rate of the animator.
function adjustTempo(dt)
  local position = position.selectedSexPosition()

  self.animationRate = self.animationRate + (position.maxTempo / (position.sustainedInterval / dt))
  
  if (self.animationRate > position.maxTempo) then
    self.animationRate = position.maxTempo
  end
  
  animator.setAnimationRate(self.animationRate)
  
  self.climaxPoints.current = self.climaxPoints.current + ((position.maxTempo * 1) * dt)
  
  self.climaxPoints.current = util.clamp(self.climaxPoints.current, self.climaxPoints.min, self.climaxPoints.max)
  
  if (self.animationRate >= position.maxTempo) then
      self.animationRate = position.minTempo
      
      position.maxTempo = position.nextMaxTempo
      position.nextMaxTempo = util.randomInRange(self.sexboundConfig.sex.maxTempo)
      
      position.sustainedInterval = position.nextSustainedInterval
      position.nextSustainedInterval = util.randomInRange(self.sexboundConfig.sex.sustainedInterval)
  end
end

---Resets all timers.
function resetTimers()
  -- Zeroize timers
  self.timers = {}
  self.timers.emote = 0
  self.timers.talk  = 0
  self.timers.moan  = 0
  self.timers.reset = 0
  self.timers.climax = 0
end

--------------------------------------------------------------------------------

idleState = {}

function idleState.enter()
  -- Return non-nil if not currently having sex
  if not sex.isHavingSex() then
    return true
  end
  
  return nil
end

function idleState.enteringState(stateData)
  animator.setAnimationState("sex", "idle")
end

function idleState.update(dt, stateData)
  -- Check if this entity is having sex
  if sex.isHavingSex() then
    return true
  end
  
  return false
end

function idleState.leavingState(stateData)
  -- Nothing for now
end

--------------------------------------------------------------------------------

sexState = {}

function sexState.enter()
  -- Return non-nil if is having sex, but not cumming
  if sex.isHavingSex() and not sex.isCumming() and not sex.isReseting() then
    return true
  end
end

function sexState.enteringState(stateData)
  position.changePosition("default")

  local sexPosition = position.selectedSexPosition()
  local animState   = sexPosition.animationState
  
  animator.setAnimationState("sex", animState, true)
  
  sextalk.sayNext("sexState")
end

function sexState.update(dt, stateData)
  local sexPosition = position.selectedSexPosition()

  if not sex.isHavingSex() then
    return true
  end

  -- Return true if is cumming
  if sex.isCumming() then 
    return sex.tryToCum()
  end

  -- Adjust the tempo of the sex
  adjustTempo(dt)
  
  sex.tryToEmote(function() 
    emote.playRandom()
  end)
  
  if sex.getAutoMoan() then
    sex.tryToMoan(function()
      moan.playRandom()
    end)
  end
  
  sex.tryToTalk(function()
    sextalk.sayNext("sexState")
  end)
  
  if (sexPosition.allowClimax) then
    return sex.tryToCum()
  end
  
  return false
end

function sexState.leavingState(stateData)
  animator.setAnimationRate(1)
end

--------------------------------------------------------------------------------

climaxState = {}

function climaxState.enter()
  -- Return non-nil if is having sex and is cumming
  if (sex.isHavingSex() and sex.isCumming()) then
    return true
  end
end

function climaxState.enteringState(stateData)
  animator.setAnimationState("sex", "climax", true)
  
  -- Try to become pregnant if enabled
  pregnant.tryBecomePregnant()
  
  sex.setTimer("dialog", 0)
  
  sextalk.sayNext("climaxState")
  
  animator.setAnimationRate(1)
end

function climaxState.update(dt, stateData)
  if not sex.isHavingSex() then
    return true
  end

  local climaxTimer = sex.getTimer("climax")
  climaxTimer = sex.setTimer("climax", climaxTimer + dt)
  
  sex.tryToEmote(function() 
    emote.playRandom()
  end)

  sex.tryToMoan(function()
    moan.playRandom()
  end)

  if (climaxTimer >= sex.getClimaxPause()) then
    sex.setIsReseting(true)
    sex.setIsCumming(false)
    return true
  end
  
  return false
end

function climaxState.leavingState(stateData)
  sex.setTimer("climax", 0)

  animator.setAnimationRate(1)
end

--------------------------------------------------------------------------------

exitState = {}

function exitState.enter()
  if (sex.isHavingSex() and sex.isReseting()) then 
    return true 
  end
end

function exitState.enteringState(stateData)
  -- Change animator state to the 'reset' state - starts new.
  animator.setAnimationState("sex", "reset", true)
end

function exitState.update(dt, stateData)
  if not sex.isHavingSex() then
    return true
  end

  local resetTimer = sex.getTimer("reset")
  resetTimer = sex.setTimer("reset", resetTimer + dt)
  
  if ( resetTimer >= sex.getResetPause() ) then
    -- Determines whether to continue having sex after exitting this state
    if (not sex.getAutoRestart() or not sex.isOccupied()) then
      sex.setIsHavingSex(false)
    end
    
    sex.setIsReseting(false)
  
    return true
  end
  
  return false
end

function exitState.leavingState(stateDate)
  sex.setTimer("reset", 0)
end