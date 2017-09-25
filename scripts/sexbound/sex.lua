--- Sex Module.
-- @module sex
sex = {}

sex.data = {}

sex.majorVersion = 1

require "/scripts/stateMachine.lua"
require "/scripts/sexbound/pov.lua"
require "/scripts/sexbound/pregnant.lua"
require "/scripts/sexbound/actor.lua"
require "/scripts/sexbound/emote.lua"
require "/scripts/sexbound/moan.lua"
require "/scripts/sexbound/music.lua"
require "/scripts/sexbound/portrait.lua"
require "/scripts/sexbound/position.lua"
require "/scripts/sexbound/sextalk.lua"
require "/scripts/sexbound/sextoy.lua"
require "/scripts/sexbound/sexui.lua"

require "/scripts/sexbound/helper.lua"

--- Initializes the sex module.
function sex.init(callback)
  sex.setupHandlers()
  
  -- Load custom configuration
  self.sexboundConfig = helper.mergeTable(root.assetJson("/scripts/sexbound/default.config"), config.getParameter("sexboundConfig"))
  
  -- Predefined sex states
  self.sexStates = stateMachine.create({ "idleState", "sexState", "climaxState", "exitState" })
  
  -- Store climax data in a new table
  self.climaxPoints = {
    current    = 0,
    min        = self.sexboundConfig.sex.minClimaxPoints,
    max        = self.sexboundConfig.sex.maxClimaxPoints,
    threshold  = self.sexboundConfig.sex.climaxThreshold,
    autoClimax = self.sexboundConfig.sex.autoClimax
  }
  
  -- Temporary storage for cooldowns
  self.cooldowns = {}
  self.cooldowns.emote = helper.randomInRange(self.sexboundConfig.sex.emoteCooldown)
  self.cooldowns.moan  = helper.randomInRange(self.sexboundConfig.sex.moanCooldown)
  self.cooldowns.talk  = helper.randomInRange(self.sexboundConfig.sex.talkCooldown)

  self.isCumming   = false
  self.isHavingSex = false
  self.isReseting  = false
  
  sex.setupTimers()
  
  -- Init specified submodules
  helper.each({"moan", "portrait", "position", "pov", "pregnant", "sextalk", "sextoy"}, function(k, v)
    _ENV[v].init()
  end)

  self.animationRate = 1
  
  if (callback ~= nil) then
    callback()
  end
end

---Updates the timers and state machine.
-- @param dt delta time
-- @param[opt] callback function to execute afters updating timers and state machine
function sex.loop(dt, callback)
  -- Updates all timers
  sex.updateTimers({"emote", "moan", "talk"}, dt)

  -- Check if an this entity is occupied
  if (config.getParameter("objectType") == "loungeable") then
    self.isHavingSex = sex.isOccupied()
  end
  
  -- Update the curent state machine state
  self.sexStates.update(dt)
    
  -- Execute your logic as a callback within this sex loop
  if (callback ~= nil) then
    callback()
  end
end

---Handles the interact event of the entity.
function sex.handleInteract(args)
  self.isHavingSex = true

  -- check if is a player or an npc
  if (args ~= nil) then
    local entityType = world.entityType(args.sourceId)
  
    if (entityType == "player" and sexui.isEnabled()) then
      -- Invoke script pane which will then force player to lounge in the object
      return {"ScriptPane", "/interface/sexbound/sexui.config"}
    end
  end

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

function sex.getActors()
  return actor.data.list
end

function sex.getAnimationRate()
  return self.animationRate
end

function sex.getAutoMoan()
  return self.sexboundConfig.sex.autoMoan
end

function sex.getAutoRestart()
  return self.sexboundConfig.sex.autoRestart
end

function sex.getSexState()
  return self.sexStates
end

sex.isCumming = function()
  return self.isCumming
end

sex.setIsCumming = function(value)
  self.isCumming = value
end

sex.setIsReseting = function(value)
  self.isReseting = value
end

sex.isReseting = function()
  return self.isReseting
end

sex.setIsHavingSex = function(value)
  self.isHavingSex = value
end

sex.setMoanGender = function(gender)
  self.moanGender = gender
end

sex.getClimaxPause = function()
  return self.sexboundConfig.sex.climaxPause
end

sex.defaultStateAnimation = function(stateName)
  return self.sexboundConfig.sex[stateName .. "Animation"]
end

sex.getResetPause = function()
  return self.sexboundConfig.sex.resetPause
end

sex.getTimer = function(name)
  return self.timers[name]
end

sex.setTimer = function(name, value)
  self.timers[name] = value
  return self.timers[name]
end

function sex.setupHandlers()  
  -- Handle message 'isClimaxing'. Receives player's intent to climax.
  message.setHandler("isClimaxing", function()
    self.isCumming = true
    self.climaxPoints.current = 0
    return {}
  end)
  
  -- Handle message 'setup-actor'. Stores identifying information about actor.
  message.setHandler("setup-actor", function(_, _, args)
    if (args.type == "player") then
      sex.data.player = args
    end
  
    if (actor.isEnabled) then actor.setupActor(args, false) end 
  end)
  
  -- Handle message 'store-actor'. Permentantly stores identifying information about actor.
  message.setHandler("store-actor", function(_, _, args)
    if (actor.isEnabled) then actor.setupActor(args, true) end
  end)
  
  -- Handle message 'switch-role'. Receives player's intent to switch actor roles.
  message.setHandler("switch-role", function()
    if not self.isCumming and not self.isReseting then
      actor.switchRole()
    end
  end)
  
  -- Handle message 'sync-ui'. Receives request for data and sends data back.
  message.setHandler("sync-ui", function()
    local data = {}
    
    data.animator = {}
    data.climax   = {}
    data.sex      = {}
    data.sextalk  = {}
    data.sextoy   = {}
    
    data.animator.rate = self.animationRate
    data.animator.currentState = animator.animationState("sex")
    
    data.climax.points  = self.climaxPoints
    
    data.sex.currentState  = self.sexStates.stateDesc()
    
    data.portrait = self.sexboundConfig.portrait
    
    data.position = position.selectedSexPosition()
    
    data.pov = self.sexboundConfig.pov
    
    data.music = self.sexboundConfig.music
    
    data.sextalk.currentDialog = sextalk.getCurrentDialog()
    
    data.sextoy.slot1 = self.sexboundConfig.sextoy.slot1[self.slot1Current]
    
    return data
  end)
  
  -- Handle message 'sync-position'. Receives request to return sex position data.
  message.setHandler("sync-position", function()
    local data = {}
    
    data.position = position.selectedSexPosition()
    
    return data
  end)
  
  -- Handle message 'isOccupied'. Recieves request to check if is the scripted entity is occupied.
  message.setHandler("isOccupied", function()
    return sex.isOccupied()
  end)
end

---Setup all internal timers.
sex.setupTimers = function()
  self.timers = {
    climax = 0,
    emote  = 0,
    moan   = 0,
    reset  = 0,
    talk   = 0
  }
end

---Automatically say next sextalk dialog.
sex.talk = function(stateDesc)
  if (sextalk.getTrigger() == "statemachine") then
    sextalk.sayNext( stateDesc )
  end
  
  if (sextalk.getTrigger() == "animation") then
    sextalk.sayNext( animator.animationState("sex") )
  end
end

---Try to Cum.
function sex.tryToCum(callback)
  if (self.climaxPoints.current >= self.climaxPoints.threshold) then
    -- Execute your cum logic as a callback
    if (callback ~= nil) then
      callback()
    end
    
    -- All NPC-to-NPC interactions will automatically climax
    if (actor.isEnabled() and not actor.hasPlayer()) then
      self.climaxPoints.current = 0
      self.isCumming = true
      
      return true
    end
    
    -- Automatically climax in the case that it is set to true
    if (self.climaxPoints.autoClimax or self.isCumming) then
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
  
    self.cooldowns.talk = helper.randomInRange(self.sexboundConfig.sex.talkCooldown)
  
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
    
    self.cooldowns.emote = helper.randomInRange(self.sexboundConfig.sex.emoteCooldown)
    
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
    
    self.cooldowns.moan  = helper.randomInRange(self.sexboundConfig.sex.moanCooldown)
    
    -- Execute your moan logic as a callback
    if (callback ~= nil) then
      callback()
    end
    
    return true
  end
  
  return false
end

--- Updates all specified timers with the Delta Time
-- @param timers List of timers names
-- @param dt Delta Time
sex.updateTimers = function(timers, dt)
  helper.each(timers, function(k, v)
    self.timers[v] = self.timers[v] + dt
  end)
end

---Adjusts the animation rate of the animator.
sex.adjustTempo = function(dt)
  local sexPosition  = position.selectedSexPosition()

  self.animationRate = self.animationRate + (sexPosition.maxTempo / (sexPosition.sustainedInterval / dt))
  
  self.animationRate = helper.clamp(self.animationRate, sexPosition.minTempo, sexPosition.maxTempo)
  
  -- Set the animator's animation rate
  animator.setAnimationRate(self.animationRate)
  
  -- Calculate the climax points
  self.climaxPoints.current = self.climaxPoints.current + ((sexPosition.maxTempo * 1) * dt)
  
  self.climaxPoints.current = helper.clamp(self.climaxPoints.current, self.climaxPoints.min, self.climaxPoints.max)
  
  if (self.animationRate >= sexPosition.maxTempo) then
      self.animationRate = sexPosition.minTempo
      
      sexPosition.maxTempo = sexPosition.nextMaxTempo
      sexPosition.nextMaxTempo = helper.randomInRange(sexPosition.maxTempo)
      
      sexPosition.sustainedInterval = sexPosition.nextSustainedInterval
      sexPosition.nextSustainedInterval = helper.randomInRange(sexPosition.sustainedInterval)
  end
end

--[Idle State]-------------------------------------------------------------------------------

idleState = {}

function idleState.enter()
  if not sex.isHavingSex() then return true end
end

function idleState.enteringState(stateData)
  -- Set the default state animation for the idleState state. Start new animation.
  animator.setAnimationState("sex", sex.defaultStateAnimation("idleState"), true)
  
  
  -- Clear climax points
  self.climaxPoints.current = 0
  
  -- Reset all actors.
  if (actor.isEnabled() and actor.hasActors()) then
    actor.resetTransformationGroups()
    
    if (not sex.isOccupied()) then
      sex.data.player = nil
    
      actor.clearActors()
      
      if (storage.npc ~= nil) then
        actor.data.list[1] = storage.npc
        
        actor.data.count = 1
      end
    end
    
    actor.resetAllActors()
  end
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

--[Sex State]--------------------------------------------------------------------------------

sexState = {}

function sexState.enter()
  if sex.isHavingSex() and not sex.isCumming() and not sex.isReseting() then return true end
end

function sexState.enteringState(stateData)
  -- Set the default state animation for the sexState state. Start new animation.
  animator.setAnimationState("sex", sex.defaultStateAnimation("sexState"), true)

  position.changePosition( position.data.currentIndex )
  
  actor.resetAllActors()

  sex.talk("sexState")
end

function sexState.update(dt, stateData)
  if not sex.isHavingSex() then return true end
  if sex.isCumming() then return true end
  
  -- Try to talk
  sex.tryToTalk(function()
    sex.talk("sexState")
  end)
  
  local sexPosition = position.selectedSexPosition()
  
  -- Try to climax
  if (sexPosition.allowClimax) then 
    sex.tryToCum()
  end
  
  -- Try to emote
  if (sexPosition.allowEmote) then
    sex.tryToEmote(function() 
      emote.playRandom("sexState")
    end)
  end
  
  -- Try to moan
  if (sexPosition.allowMoan) then
    sex.tryToMoan(function()
      moan.playRandom(self.moanGender)
    end)
  end
  
  -- Adjust the tempo of the sex
  sex.adjustTempo(dt)
  
  -- Check that the current animation state name matches the sex position state name
  if (animator.animationState("sex") ~= sexPosition.animationState) then return false end
  
  return false
end

function sexState.leavingState(stateData)
  animator.setAnimationRate(1)
end

--[Climax State]-----------------------------------------------------------------------------

climaxState = {}

function climaxState.enter()
  if (sex.isHavingSex() and sex.isCumming()) then
    return true
  end
end

function climaxState.enteringState(stateData)
  local sexPosition = position.selectedSexPosition()
  
  -- Get climax animation state for position or use default climax animation state
  if (sexPosition.climaxAnimationState ~= nil) then
    animator.setAnimationState("sex", sexPosition.climaxAnimationState, true)
  else
    animator.setAnimationState("sex", sex.defaultStateAnimation("climaxState"), true)
  end
  
  sex.setTimer("dialog", 0)
  
  emote.playRandom("climaxState")
  
  sex.talk("climaxState")
end

function climaxState.update(dt, stateData)
  if not sex.isHavingSex() then return true end

  -- Try to talk
  sex.tryToTalk(function()
    sex.talk("climaxState")
  end)
  
  local climaxTimer = sex.getTimer("climax")
  climaxTimer = sex.setTimer("climax", climaxTimer + dt)
  
  sex.tryToEmote(function() 
    emote.playRandom("climaxState")
  end)

  sex.tryToMoan(function()
    moan.playRandom(self.moanGender)
  end)

  if (climaxTimer >= sex.getClimaxPause()) then
    sex.setIsReseting(true)
    return true
  end
  
  return false
end

function climaxState.leavingState(stateData)
  -- If pregnant module is enable then try to become pregnant 
  if (pregnant.isEnabled()) then pregnant.tryBecomePregnant() end
  
  sex.setTimer("climax", 0)
  
  sex.setIsCumming(false)
end

--[Reset State]------------------------------------------------------------------------------

exitState = {}

function exitState.enter()
  if (sex.isHavingSex() and sex.isReseting()) then
    return true
  end
end

function exitState.enteringState(stateData)
  animator.setAnimationState("sex", sex.defaultStateAnimation("exitState"), true) -- Change animation state
end

function exitState.update(dt, stateData)
  if not sex.isHavingSex() then
    position.changePosition(1)
    
    return true
  end

  local resetTimer = sex.getTimer("reset")
  resetTimer = sex.setTimer("reset", resetTimer + dt)
  
  if ( resetTimer >= sex.getResetPause() ) then
    -- Determines whether to continue having sex after exitting this state
    if not sex.getAutoRestart() then
      sex.setIsHavingSex(false)
    end

    return true
  end
  
  return false
end

function exitState.leavingState(stateDate)
  sex.setTimer("reset", 0)
  
  sex.setIsReseting(false)
end