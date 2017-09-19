--- Sex Module.
-- @module sex
sex = {}

sex.majorVersion = 1

require "/scripts/stateMachine.lua"
require "/scripts/sexbound/pov.lua"
require "/scripts/sexbound/pregnant.lua"
require "/scripts/sexbound/emote.lua"
require "/scripts/sexbound/moan.lua"
require "/scripts/sexbound/music.lua"
require "/scripts/sexbound/portrait.lua"
require "/scripts/sexbound/position.lua"
require "/scripts/sexbound/sextalk.lua"
require "/scripts/sexbound/sextoy.lua"
require "/scripts/sexbound/sexui.lua"

--- Initializes the sex module.
function sex.init(callback)
  sex.setupHandlers()
  
  -- Load custom configuration
  self.sexboundConfig = util.mergeTable(root.assetJson("/scripts/sexbound/default.config"), config.getParameter("sexboundConfig"))
  
  -- Predefined sex states
  self.sexStates = stateMachine.create({ "idleState", "sexState", "climaxState", "exitState" })
  
  -- Temporary storage for actors
  self.actors = {}
  self.actorsCount = 0
  
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
  self.cooldowns.emote = util.randomInRange(self.sexboundConfig.sex.emoteCooldown)
  self.cooldowns.moan  = util.randomInRange(self.sexboundConfig.sex.moanCooldown)
  self.cooldowns.talk  = util.randomInRange(self.sexboundConfig.sex.talkCooldown)

  self.isCumming   = false
  self.isHavingSex = false
  self.isReseting  = false
  
  resetTimers()
  
  -- Init specified submodules
  util.each({"moan", "portrait", "position", "pov", "sextalk", "sextoy"}, function(k, v)
    _ENV[v].init()
  end)

  self.animationRate = 1
  
  animator.setGlobalTag("part-actor1-head", "parts/actor1/human/head.png:default.default")
  animator.setGlobalTag("part-actor1-hair", "/humanoid/human/hair/male1.png:normal")
  
  if (callback ~= nil) then
    callback()
  end
end

function sex.resetActors()
  if not (self.sexboundConfig.sex.enableActors) then return false end

  util.each(self.actors, function(k, v)
    sex.resetActor(v, k)
  end)
end

function sex.resetActor(args, actorNumber)
  local gender = self.sexboundConfig.sex.defaultPlayerGender -- default is 'male'
  -- Check if gender is supported by the mod
  gender = util.find(self.sexboundConfig.sex.supportedPlayerGenders, function(genderName)
    if (args.gender == genderName) then return args.gender end
  end)

  args.gender = gender
  
  if (self.actorsCount == 2 and actorNumber == 2) then sex.setMoanGender(gender) end
  
  local species = self.sexboundConfig.sex.defaultPlayerSpecies -- default is 'human'
  -- Check if species is supported by the mod
  species = util.find(self.sexboundConfig.sex.supportedPlayerSpecies, function(speciesName)
   if (args.species == speciesName) then return args.species end
  end)

  args.species = species
  
  local bodyDirectives   = ""
  local facialHairFolder = "facialhair"
  local facialHairGroup  = "default"
  local facialHairType   = "default"
  local facialMaskFolder = "facialmask"
  local facialMaskGroup  = "default"
  local facialMaskType   = "default"
  local hairType         = "male1"
  local hairFolder       = "hair"
  local hairDirectives   = ""
  
  -- Set animator global tag "gender"
  animator.setGlobalTag("gender",  gender)
  animator.setGlobalTag("actor" .. actorNumber .. "-gender",  gender)
  
  -- Set animator global tag "species"
  animator.setGlobalTag("species", species)
  animator.setGlobalTag("actor" .. actorNumber .. "-species", species)
  
  -- Set animator global tags for identifying information
  if (args.identity ~= nil) then
    if (args.identity.bodyDirectives ~= nil) then bodyDirectives = args.identity.bodyDirectives end
    if (args.identity.facialHairType ~= nil) then facialHairType = args.identity.facialHairType end
    if (facialHairType == "") then facialHairType = "default" end
    if (args.identity.hairType ~= nil) then hairType = args.identity.hairType end
    if (args.identity.hairDirectives ~= nil) then hairDirectives = args.identity.hairDirectives end
    
    if (args.identity.species == "apex") then
      hairFolder = hairFolder .. gender
    
      if (args.identity.facialHairGroup ~= nil) then 
        facialHairGroup = args.identity.facialHairGroup
        facialHairFolder = "beard" .. gender -- beard + gender
      end
    end
    
    if (args.identity.species == "avian") then
      if (args.identity.facialHairGroup ~= nil) then 
        facialHairGroup  = args.identity.facialHairGroup
        facialHairFolder = "fluff"
        facialMaskFolder  = "beaks"
        facialMaskType   = args.identity.facialMaskType
      end
    end
    
    if (args.identity.species == "novakid") then
      if (args.identity.facialHairGroup ~= nil) then 
        facialHairGroup = args.identity.facialHairGroup
        facialHairFolder = "brand"
      end
    end
    
    local position = position.selectedSexPosition().animationState
  
    if (animator.animationState("sex") == "idle") then
      position = "idle"
    end
    
    if (animator.animationState("sex") == "climax") then
      position = position .. "-climax"
    end
    
    if (animator.animationState("sex") == "reset") then
      position = position .. "-reset"
    end
    
    local role = "actor" .. actorNumber
    
    local partHead = "parts/" .. role .. "/" .. args.species .. "/head.png:" .. position .. ".1" .. bodyDirectives
    animator.setGlobalTag("part-" .. role .. "-head", partHead)

    local partHair = "/humanoid/" .. args.species .. "/" .. hairFolder .. "/" .. hairType .. ".png:normal" .. hairDirectives
    animator.setGlobalTag("part-" .. role .. "-hair", partHair)
    
    local partFacialHair = "/humanoid/" .. args.species .. "/" .. facialHairFolder .. "/" .. facialHairType .. ".png:normal" .. hairDirectives
    animator.setGlobalTag("part-" .. role .. "-facial-hair", partFacialHair)
    
    local partFacialMask = "/humanoid/" .. args.species .. "/" .. facialMaskFolder .. "/" .. facialMaskType .. ".png:normal" .. hairDirectives
    animator.setGlobalTag("part-" .. role .. "-facial-mask", partFacialMask)
    
    local partBody = "parts/" .. role .. "/" .. args.species  .. "/body_" .. args.gender .. ".png:" .. position
    animator.setGlobalTag("part-" .. role .. "-body", partBody)
  end
  
  animator.setGlobalTag("actor" .. actorNumber .. "-bodyDirectives",   bodyDirectives)
  animator.setGlobalTag("actor" .. actorNumber .. "-hairFolder",       hairFolder)
  animator.setGlobalTag("actor" .. actorNumber .. "-hairType",         hairType)
  animator.setGlobalTag("actor" .. actorNumber .. "-hairDirectives",   hairDirectives)
  animator.setGlobalTag("actor" .. actorNumber .. "-facialHairFolder", facialHairFolder)
  animator.setGlobalTag("actor" .. actorNumber .. "-facialHairType",   facialHairType)
  animator.setGlobalTag("actor" .. actorNumber .. "-facialMaskFolder", facialMaskFolder)
  animator.setGlobalTag("actor" .. actorNumber .. "-facialMaskType",   facialMaskType)
end

function sex.setupActor(args)
  if not (self.sexboundConfig.sex.enableActors) then return false end

  -- Permenantly store first actor if it is an 'npc' entity type
  if (args.entityType == "npc" and isEmpty(self.actors)) then
    self.actorsCount = 1
    
    storage.npc = args
    
    self.actors = {}
  else
    self.actorsCount = self.actorsCount + 1
  end
  
  self.actors[ self.actorsCount ] = args
  
  if (self.actorsCount == 2) then
    if (self.actors[1].gender == "female" and self.actors[2].gender == "male") then
     sex.switchRole(true) -- True to skip reset
    end
  end
  
  -- Reset the actors
  sex.resetActors()
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
  return self.actors
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

---Updates the timers and state machine.
--@param dt delta time
--@param[opt] callback function to execute afters updating timers and state machine
function sex.loop(dt, callback)
  self.timers.talk  = self.timers.talk  + dt
  
  self.timers.emote = self.timers.emote + dt

  self.timers.moan  = self.timers.moan  + dt
  
  -- Check if an this entity is occupied
  if (config.getParameter("objectType") == "loungeable") then
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

function sex.setMoanGender(gender)
  self.moanGender = gender
end

function sex.getClimaxPause()
  return self.sexboundConfig.sex.climaxPause
end

function sex.getSexStateAnimation()
  return self.sexboundConfig.sex.sexStateAnimation
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

function sex.switchRole(skipReset)
    table.insert(self.actors, 1, table.remove(self.actors, #self.actors)) -- Shift actors
  
    if not (skipReset) then
      sex.resetActors()
    end
end

function sex.setupHandlers()
  -- Handle message 'setup-actor'. Stores identifying information about actor.
  message.setHandler("setup-actor", function(_, _, args)
    --sex.clearActors()
  
    sex.setupActor(args)
  end)
  
  -- Handle message 'isClimaxing'. Receives player's intent to climax.
  message.setHandler("isClimaxing", function()
    self.isCumming = true
    return {}
  end)
  
  -- Handle message 'switch-role'. Receives player's intent to switch actor roles.
  message.setHandler("switch-role", function()
    sex.switchRole()
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
  
  self.animationRate = util.clamp(self.animationRate, position.minTempo, position.maxTempo)
  
  animator.setAnimationRate(self.animationRate)
  
  self.climaxPoints.current = self.climaxPoints.current + ((position.maxTempo * 1) * dt)
  
  self.climaxPoints.current = util.clamp(self.climaxPoints.current, self.climaxPoints.min, self.climaxPoints.max)
  
  if (self.animationRate >= position.maxTempo) then
      self.animationRate = position.minTempo
      
      position.maxTempo = position.nextMaxTempo
      position.nextMaxTempo = util.randomInRange(position.maxTempo)
      
      position.sustainedInterval = position.nextSustainedInterval
      position.nextSustainedInterval = util.randomInRange(position.sustainedInterval)
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

function resetTransformationGroups()
    util.each({
      "actor1-facial-hair",
      "actor1-facial-mask",
      "actor1-hair",
      "actor1-head",
    
      "actor2-facial-hair",
      "actor2-facial-mask",
      "actor2-hair",
      "actor2-head"
    }, function(k, v)
      if animator.hasTransformationGroup(v) then
        animator.resetTransformationGroup(v)
      end
    end)
end

function sex.clearActors()
  util.each(self.actors, function(k, v)
    local role = "actor" .. k
    local default = "parts/default.png:default"
    
    animator.setGlobalTag("part-" .. role .. "-body",        default)
    animator.setGlobalTag("part-" .. role .. "-head",        default)
    animator.setGlobalTag("part-" .. role .. "-hair",        default)
    animator.setGlobalTag("part-" .. role .. "-facial-hair", default)
    animator.setGlobalTag("part-" .. role .. "-facial-mask", default)
  end)
  
  self.actorsCount = 1
  
  self.actors = {}
end

--[Idle State]-------------------------------------------------------------------------------

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

  resetTransformationGroups()
  
  if (not isEmpty(self.actors)) then
    if (not sex.isOccupied()) then
      sex.clearActors()
    
      self.actors[1] = storage.npc
    end
    
    -- Reset main actors
    sex.resetActors()
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
  -- Return non-nil if is having sex, but not cumming
  if sex.isHavingSex() and not sex.isCumming() and not sex.isReseting() then
    return true
  end
end

function sexState.enteringState(stateData)
  position.changePosition("default")

  position.setupSexPosition()
  
  animator.setAnimationState("sex", sex.getSexStateAnimation(), true)
  
  sex.resetActors()
  
  if (self.sexboundConfig.sextalk.trigger == "statemachine") then
    sextalk.sayNext("sexState")
  end
  
  if (self.sexboundConfig.sextalk.trigger == "animation") then
    local animationState = animator.animationState("sex")

    sextalk.sayNext(animationState)
  end
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

  -- Check that the current animation state name matches the sex position state name
  if (animator.animationState("sex") ~= sexPosition.animationState) then return false end
  
  -- Adjust the tempo of the sex
  adjustTempo(dt)
  
  if (sexPosition.allowEmote) then
    sex.tryToEmote(function() 
      emote.playRandom()
    end)
  end
  
  if (sexPosition.allowMoan) then
    sex.tryToMoan(function()
      moan.playRandom(self.moanGender)
    end)
  end
  
  sex.tryToTalk(function()
    if (self.sexboundConfig.sextalk.trigger == "statemachine") then
      sextalk.sayNext("sexState")
    end
    
    if (self.sexboundConfig.sextalk.trigger == "animation") then
      local animationState = animator.animationState("sex")

      sextalk.sayNext(animationState)
    end
  end)
  
  if (sexPosition.allowClimax) then
    return sex.tryToCum()
  end
  
  return false
end

function sexState.leavingState(stateData)
  animator.setAnimationRate(1)
end

--[Climax State]-----------------------------------------------------------------------------

climaxState = {}

function climaxState.enter()
  -- Return non-nil if is having sex and is cumming
  if (sex.isHavingSex() and sex.isCumming()) then
    return true
  end
end

function climaxState.enteringState(stateData)
  local position = position.selectedSexPosition()

  animator.setAnimationState("sex", position.climaxAnimationState, true)
  
  animator.setGlobalTag("positionState", position.animationState)
  
  -- Try to become pregnant if enabled
  pregnant.tryBecomePregnant()
  
  sex.setTimer("dialog", 0)

  if (self.sexboundConfig.sextalk.trigger == "statemachine") then
    sextalk.sayNext("climaxState")
  end
  
  if (self.sexboundConfig.sextalk.trigger == "animation") then
    local animationState = animator.animationState("sex")

    sextalk.sayNext(animationState)
  end
  
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
    moan.playRandom(self.moanGender)
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

--[Reset State]------------------------------------------------------------------------------

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
  self.currentPositionIndex = 1
  
  position.changePosition(1)

  sex.setTimer("reset", 0)
end