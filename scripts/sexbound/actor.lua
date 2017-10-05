--- Actor Module.
-- @module actor
actor = {}

actor.data = {
  count = 0,
  list  = {}
}

--- Returns the enabled status of the actor module.
-- @return boolean
actor.isEnabled = function()
  return self.sexboundConfig.actor.enabled
end

--- Clears all actor data and resets the associated global animator tags.
actor.clearActors = function()
  actor.resetAllGlobalTags()

  actor.data.count = 0
  
  actor.data.list  = {}
end

--- Checks if actor data contains any actors.
-- @return boolean
actor.hasActors = function()
  if (actor.data.count > 0) then return true else return false end
end

--- Checks if actor data contains at least one player.
-- @return boolean
actor.hasPlayer = function()
  local result = false

  helper.each(actor.data.list, function(k, v)
    if (v.type ~= nil and v.type == "player") then 
      result = true
      return result
    end
  end)
  
  return result
end

--- Processes gender value.
-- @param gender male, female, or something else (future)
actor.processGender = function(gender)
  local processed = self.sexboundConfig.sex.defaultPlayerGender -- default is 'male'
  
  processed = helper.find(self.sexboundConfig.sex.supportedPlayerGenders, function(v)
    if (gender == v) then return v end
  end)
  
  return processed
end

--- Processes species value.
-- @param species name of species
actor.processSpecies = function(species)
  local processed = self.sexboundConfig.sex.defaultPlayerSpecies -- default is 'human'
  
  processed = helper.find(self.sexboundConfig.sex.supportedPlayerSpecies, function(v)
   if (species == v) then return v end
  end)
  
  return processed
end

--- Resets an specified actor.
-- @param args The actor's identity data.
-- @param actorNumber The actor's index in the actor data list.
actor.resetActor = function(args, actorNumber)
  gender  = actor.processGender(args.gender)

  species = actor.processSpecies(args.species)
  
  -- Set moan based on actor 2 gender
  if actor.data.count == 2 and actorNumber == 2 then 
    sex.setMoanGender(gender)
  end
  
  -- Check that hair folder is set
  if not args.identity.hairFolder then
    args.identity.hairFolder = args.identity.hairGroup
  
    if species == "apex" then
      args.identity.hairFolder = "hair" .. gender
    end
  end
  
  -- Check that facial hair folder is set
  if not args.identity.facialHairFolder then
    args.identity.facialHairFolder = args.identity.facialHairGroup
    
    if species == "apex" then
      args.identity.facialHairFolder = "beard" .. gender
    end
    
    if species == "avian" then
      args.identity.facialHairFolder = "fluff"
    end
    
    if species == "novakid" then
      args.identity.facialHairFolder = "brand"
    end
  end
  
  -- Check that facial mask folder is set
  if not args.identity.facialMaskFolder then
    args.identity.facialMaskFolder = args.identity.facialMaskGroup
    
    if species == "avian" then
      args.identity.facialHairFolder = "beaks"
    end
  end
  
  -- Make changes to position based on animation state
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
  
  if (args.identity.hairType == "") then
    -- Handle default hair type for apex, avian, floran, glitch, hylotl
    helper.each({"apex", "avian", "floran", "glitch", "hylotl"}, function(k, v)
      if (species == v) then
        args.identity.hairType = "1"
        return true
      end
    end)
    
    -- Handle default hair type for fenerox, human, novakid
    helper.each({"fenerox", "human", "novakid"}, function(k, v)
      if (species == v) then
        if (gender == "male") then
          args.identity.hairType = "male1"
        else
          args.identity.hairType = "fem1"
        end
        return true
      end
    end)
  end
  
  -- Handle default facial hair type for apex, avian, novakid
  if (args.identity.facialHairType == "") then
    helper.each({"apex", "avian", "novakid"}, function(k, v)
      if (species == v) then
        args.identity.facialHairType = "1"
        return true
      end
    end)
  end
  
  -- Handle default facial mask type for avian
  if (args.identity.facialMaskType == "") then
    if (species == "avian") then
      args.identity.facialMaskType = "1"
    end
  end
  
  -- Establish actor's role
  local role = "actor" .. actorNumber
  
  local defaultPath = "/artwork/humanoid/default.png:default"
  
  local partEmote = defaultPath
  
  -- Create the global tags
  if emote.data.list[actorNumber] then
    partEmote = "/humanoid/" .. species .. "/emote.png:" .. emote.data.list[actorNumber]
  end
  
  animator.setGlobalTag("part-" .. role .. "-emote", partEmote)
  
  local partHead = "/artwork/humanoid/" .. role .. "/" .. species .. "/head_" .. gender .. ".png:normal" .. args.identity.bodyDirectives .. args.identity.hairDirectives
  animator.setGlobalTag("part-" .. role .. "-head", partHead)
  
  local partBody = "/artwork/humanoid/" .. role .. "/" .. species  .. "/body_" .. gender .. ".png:" .. position
  animator.setGlobalTag("part-" .. role .. "-body", partBody)
  
  local partArmFront = "/artwork/humanoid/" .. role .. "/" .. species .. "/arm_front.png:" .. position
  animator.setGlobalTag("part-" .. role .. "-arm-front", partArmFront)
  
  local partArmBack = "/artwork/humanoid/" .. role .. "/" .. species .. "/arm_back.png:" .. position
  animator.setGlobalTag("part-" .. role .. "-arm-back", partArmBack)
  
  if (args.identity.facialHairType ~= "") then
   local partFacialHair = "/humanoid/" .. species .. "/" .. args.identity.facialHairFolder .. "/" .. args.identity.facialHairType .. ".png:normal" .. args.identity.facialHairDirectives
   animator.setGlobalTag("part-" .. role .. "-facial-hair", partFacialHair)
  else
    animator.setGlobalTag("part-" .. role .. "-facial-hair", defaultPath)
  end
  
  if (args.identity.facialMaskType ~= "") then
    local partFacialMask = "/humanoid/" .. species .. "/" .. args.identity.facialMaskFolder .. "/" .. args.identity.facialMaskType .. ".png:normal" .. args.identity.facialMaskDirectives
    animator.setGlobalTag("part-" .. role .. "-facial-mask", partFacialMask)
  else
    animator.setGlobalTag("part-" .. role .. "-facial-mask", defaultPath)
  end

  animator.setGlobalTag(role .. "-facialMaskType", args.identity.facialMaskType)
  
  if (args.identity.hairType ~= "") then
    local partHair = "/humanoid/" .. species .. "/" .. args.identity.hairFolder .. "/" .. args.identity.hairType .. ".png:normal" .. args.identity.bodyDirectives .. args.identity.hairDirectives
    animator.setGlobalTag("part-" .. role .. "-hair", partHair)
  else
    animator.setGlobalTag("part-" .. role .. "-hair", defaultPath)
  end
  
  animator.setGlobalTag(role .. "-bodyDirectives",   args.identity.bodyDirectives)
  animator.setGlobalTag(role .. "-hairDirectives",   args.identity.hairDirectives)
end

--- Resets all actors found in the actor data list.
actor.resetAllActors = function()
  -- Reset actors' global animator tags
  actor.resetAllGlobalTags()
  
  helper.each(actor.data.list, function(k, v)
    actor.resetActor(v, k)
  end)
end

--- Resets all global animator tags for all actors.
actor.resetAllGlobalTags = function()
  helper.each(actor.data.list, function(k, v)
    local role = "actor" .. k
    local default = "/artwork/default.png:default"
    
    animator.setGlobalTag("part-" .. role .. "-arm-back",    default)
    animator.setGlobalTag("part-" .. role .. "-arm-front",   default)
    animator.setGlobalTag("part-" .. role .. "-body",        default)
    animator.setGlobalTag("part-" .. role .. "-emote",        default)
    animator.setGlobalTag("part-" .. role .. "-head",        default)
    animator.setGlobalTag("part-" .. role .. "-hair",        default)
    animator.setGlobalTag("part-" .. role .. "-facial-hair", default)
    animator.setGlobalTag("part-" .. role .. "-facial-mask", default)
  end)
end

--- Resets all transformations to animated actor parts.
actor.resetTransformationGroups = function()
  helper.each(actor.data.list, function(k1, v1)
    helper.each({"ArmBack", "ArmFront", "Body", "Climax", "Emote", "FacialHair", "FacialMask", "Hair", "Head"}, function(k2, v2)
      if animator.hasTransformationGroup("actor" .. k1 .. v2) then
        animator.resetTransformationGroup("actor" .. k1 .. v2)
      end
    end)
  end)
end

--- Setup new actor.
-- @param args Table of identifiying data
-- @param storeActor True := Store actor data in this object.
actor.setupActor = function(args, storeActor)
  actor.data.count = actor.data.count + 1
  
  actor.data.list[ actor.data.count ] = args
  
  -- Permenantly store first actor if it is an 'npc' entity type
  if (storeActor) then
    storage.npc  = args
    sex.data.npc = args
    actor.data.list[ actor.data.count ].isSexNode = true
    
    local pregnant = actor.data.list[ actor.data.count ].storage.pregant
    
    if pregnant and pregnant.isPregnant then
      storage.pregnant = pregnant
    end
  else
    actor.data.list[ actor.data.count ].isSexNode = false
  end
  
  if (actor.data.list[ actor.data.count ].identity == nil) then
    local identity = {}
  
    -- Check species is supported
    local species = self.sexboundConfig.sex.defaultPlayerSpecies -- default is 'human'
    -- Check if species is supported by the mod
    species = helper.find(self.sexboundConfig.sex.supportedPlayerSpecies, function(speciesName)
     if (args.species == speciesName) then return args.species end
    end)
    
    local speciesConfig = root.assetJson("/species/" .. species .. ".species")
    
    identity.bodyDirectives = ""
    
    if (speciesConfig.bodyColor[1] ~= "") then
      helper.each(helper.randomChoice(speciesConfig.bodyColor), function(k, v)
        identity.bodyDirectives = identity.bodyDirectives .. "?replace=" .. k .. "=" .. v 
      end)
    end
    
    if (speciesConfig.undyColor[1] ~= "") then
      helper.each(helper.randomChoice(speciesConfig.undyColor), function(k, v)
        identity.bodyDirectives = identity.bodyDirectives .. "?replace=" .. k .. "=" .. v 
      end)
    end
    
    identity.hairDirectives = ""
    
    if (speciesConfig.hairColor[1] ~= "") then
      helper.each(helper.randomChoice(speciesConfig.hairColor), function(k, v)
        identity.hairDirectives = identity.hairDirectives .. "?replace=" .. k .. "=" .. v 
      end)
    end
    
    --identity.facialHairDirectives = identity.bodyDirectives .. identity.hairDirectives
    --identity.facialMaskDirectives = identity.bodyDirectives
    
    local genderCount = 1
    
    if (args.gender == "female") then genderCount = 2 end
    
    local hair = speciesConfig.genders[genderCount].hair
    if not isEmpty(hair) then identity.hairType = helper.randomChoice(hair) end
    
    local facialHair = speciesConfig.genders[genderCount].facialHair
    if not isEmpty(facialHair) then identity.facialHairType = helper.randomChoice(facialHair) end
    
    local facialMask = speciesConfig.genders[genderCount].facialMask
    if not isEmpty(facialMask) then identity.facialMaskType = helper.randomChoice(facialMask) end
    
    actor.data.list[ actor.data.count ].identity = identity
  end
  
  -- Swap roles between male and female by default
  if (actor.data.count == 2) then
    if (actor.data.list[1].gender == "female" and actor.data.list[2].gender == "male") then
     actor.switchRole() -- True to skip reset
    end
  end
  
  -- Reset the actors
  actor.resetAllActors()
end

--- Shifts the actors in actor data list to the right.
-- @param skipReset True := Skip reseting all actors.
actor.switchRole = function(skipReset)
    table.insert(actor.data.list, 1, table.remove(actor.data.list, #actor.data.list)) -- Shift actors
  
    if not (skipReset) then
      actor.resetAllActors()
    end
end