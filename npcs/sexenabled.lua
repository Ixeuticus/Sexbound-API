require "/scripts/vec2.lua"
require "/scripts/sexbound/helper.lua"

-- Override init
sexbound_oldInit = init
init = function()
  sexbound_oldInit()
  
  message.setHandler("become-pregnant", function(_, _, args)
    sb.logInfo("Other Non-SexNode NPC has become pregnant!")
  
    storage.pregnant = args
  end)
  
  message.setHandler("unload", function(_, _, args)
    unloadNPC()
  end)
  
  self.lustConfig = { damageSourceKind = "lust" }
  
  -- Restore tenant type NPC
  if hasRespawner() and findEntityWithUid(storage.respawner) then
    world.sendEntityMessage(storage.respawner, "transform-into-npc", {uniqueId = entity.uniqueId()})
  end
  
  -- Restore companion NPC
  if hasOwnerUuid() and findEntityWithUid(storage.ownerUuid) then
    world.sendEntityMessage(storage.ownerUuid, "transform-into-npc", {uniqueId = entity.uniqueId()})
  end
end

-- Override update
sexbound_oldUpdate = update
update = function(dt)
  sexbound_oldUpdate(dt) -- Run the previous version of the function.
  
  -- Restore the NPCs storage parameters
  if status.statusProperty("prevStorage") ~= nil and status.statusProperty("prevStorage") ~= "default" then
    storage = helper.mergeTable(storage, status.statusProperty("prevStorage"))

    status.setStatusProperty("prevStorage", "default") -- clear it afterwards
  end
  
  -- Handle pregnancy
  if storage.pregnant and storage.pregnant.isPregnant then
    if (storage.pregnant.birthDate ~= nil and storage.pregnant.birthTime ~= nil) then
      tryToGiveBirth(function()
        giveBirth()
      end)
    end
  end
  
  -- Transform into object when status property 'lust' is true
  if (status.statusProperty("lust") == true) then
    status.setStatusProperty("lust", false)
    
    transformIntoObject()
  end
  
  -- Handle sex request when status property 'havingSex' is true
  if (status.statusProperty("havingSex") == true) then
    status.setStatusProperty("havingSex", false)
    
    handleSexRequest()
  end
end

function getName()
  return npc.humanoidIdentity().name
end

function giveBirth()
  local position = entity.position()
  local level = 1
  
  -- Spawn in an NPC for now
  local entityId     = world.spawnNpc(position, npc.species(), npc.npcType(), level)
  local entityName   = world.entityName(entityId)
  local entityGender = world.entityGender(entityId)
  
  if (entityGender == "male") then
    entityGender = "^blue;boy^reset;"
  end
  
  if (entityGender == "female") then
    entityGender = "^pink;girl^reset;"
  end
  
  local players = world.players()
  
  local txtMessage = "^green;" .. getName() .. "^reset; just gave birth to baby " .. entityGender .. " named ^green;" .. entityName .. "^reset;!"
  
  helper.each(players, function(k, v)
    world.sendEntityMessage(v, "queueRadioMessage", {
      messageId = "npcgivingbirth",
      unique = false,
      text = txtMessage
    })
  end)
end

function handleSexRequest(args)
  local position = vec2.floor(entity.position())
  position[2] = position[2] - 3 -- (3 * 8 = 24)
  
  local entityId = world.objectAt(position)

  if (entityId ~= nil) then
    sendMessage(entityId, "setup-actor")
  end
end

function transformIntoObject(args)
  -- Attempt to override default lustConfig options
  if (status.statusProperty("lustConfigOverride") ~= "default") then
    self.lustConfig = helper.mergeTable(self.lustConfig, status.statusProperty("lustConfigOverride"))
  end
  
  -- Create an object that resembles the npc at the position
  local position = vec2.floor(entity.position())
  position[2] = position[2] - 2
  
  self.newUniqueId = sb.makeUuid()

  local faceDirection = helper.randomDirection()
  
  if world.placeObject("sexnode", position, faceDirection, {uniqueId = self.newUniqueId}) then
    -- Check for respawner (tenant)
    if hasRespawner() or hasOwnerUuid() then
      if hasRespawner() and findEntityWithUid(storage.respawner) then
        sendMessage(self.newUniqueId, "store-actor")
        world.sendEntityMessage(storage.respawner, "transform-into-object", {uniqueId = entity.uniqueId()})
      end
      
      -- Check for crew member
      if hasOwnerUuid() and findEntityWithUid(storage.ownerUuid) then
        splashDamage()
        --world.sendEntityMessage(storage.ownerUuid, "transform-into-object", {uniqueId = entity.uniqueId()})
      end
    else
      sendMessage(self.newUniqueId, "store-actor")
      unloadNPC()
    end
  else
    splashDamage()
  end
end

function splashDamage()
  status.applySelfDamageRequest({
    damageType       = "IgnoresDef",
    damage           = 0,
    damageSourceKind = self.lustConfig.damageSourceKind,
    sourceEntityId   = entity.id()
  })
end

function findEntityWithUid(uniqueId)
  if world.findUniqueEntity(uniqueId):result() then return true end
  return false
end

function hasOwnerUuid()
  if (storage ~= nil and storage.ownerUuid) then return true end
  return false
end

function hasRespawner()
  if (storage ~= nil and storage.respawner) then return true end
  return false
end

function sendMessage(uniqueId, message)
  local data = {
    entityType = entity.entityType(),
    id         = entity.id(),
    identity   = npc.humanoidIdentity(),
    gender     = npc.humanoidIdentity().gender,
    species    = npc.humanoidIdentity().species,
    level      = npc.level(),
    seed       = npc.seed(),
    type       = npc.npcType(),
    uniqueId   = entity.uniqueId()
  }

  -- Preserve storage information
  if (storage) then
    data.storage = storage
  end
  
  -- Send the identifying information to the object to be stored.
  helper.sendMessage(uniqueId, message, data, false)
end

function tryToGiveBirth(callback)
  local pregnant = storage.pregnant
  
  if (pregnant.birthDate ~= nil and pregnant.birthTime ~= nil) then
    local birthTime = pregnant.birthDate + pregnant.birthTime
    local worldTime = world.day() + world.timeOfDay()
    
    if (worldTime >= birthTime) then
      if (callback ~= nil) then
        storage.pregnant = {
          isPregnant = false
        } -- Ensure NPC is no longer pregnant
      
        return callback()
      end
      
      return true
    end
  end
  
  return false
end

tryToSetUniqueId = function(uniqueId, callback)
  if not self.findUniqueId then
    self.findUniqueId = world.findUniqueEntity(uniqueId)
  else
    if (self.findUniqueId:finished()) then
      if not self.findUniqueId:result() then
        if (callback ~= nil) then
          callback(uniqueId)
        end
      end
      
      self.findUniqueId = nil
    end
  end
end

function unloadNPC()
  npc.setDropPools({}) -- prevent loot drop
  
  npc.setDeathParticleBurst(nil) -- prevent death particle effect
  
  npc.setPersistent(false)

  -- Kill the NPC
  status.applySelfDamageRequest({
    damageType       = "IgnoresDef",
    damage           = status.resourceMax("health"),
    damageSourceKind = self.lustConfig.damageSourceKind,
    sourceEntityId   = entity.id()
  })
  
  --self.forceDie = true
end