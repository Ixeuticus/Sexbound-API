require "/scripts/vec2.lua"

require "/scripts/sexbound/helper.lua"

-- Hack into the loaded /npcs/bmain.lua file through 'updateUniqueId'
oldUpdateUniqueId = updateUniqueId

updateUniqueId = function()
  oldUpdateUniqueId() -- Run the previous version of the function.
  
  if (status.statusProperty("pregnant") ~= nil) then
    local pregnant = status.statusProperty("pregnant")
  
    -- Handle pregnancy
    if (pregnant.birthDate ~= nil and pregnant.birthTime ~= nil) then
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
  -- Create an object that resembles the npc at the position
  local position = vec2.floor(entity.position())
  position[2] = position[2] - 2
  
  self.newUniqueId = tostring(sb.makeRandomSource():randu64())
  
  local faceDirection = helper.randomDirection()
  
  if (world.placeObject("sexnode", position, faceDirection, {uniqueId = self.newUniqueId})) then
    sendMessage(self.newUniqueId, "store-actor")
  
    unloadNPC()
  end
end

function sendMessage(uniqueId, message, role)
  local data = {
    entityType = entity.entityType(),
    id         = entity.id(),
    identity   = npc.humanoidIdentity(),
    gender     = npc.humanoidIdentity().gender,
    pregnant   = pregnant,
    species    = npc.humanoidIdentity().species,
    level      = npc.level(),
    seed       = npc.seed(),
    type       = npc.npcType()
  }
  
  -- Preserve the pregnancy status
  if (status.statusProperty("pregnant") ~= nil) then
    data.pregnant = status.statusProperty("pregnant")
  end
  
  -- Send the identifying information to the object to be stored.
  helper.sendMessage(uniqueId, message, data, false)
end

function tryToGiveBirth(callback)
  local pregnant = status.statusProperty("pregnant")
  
  if (pregnant.birthDate ~= nil and pregnant.birthTime ~= nil) then
    local birthTime = pregnant.birthDate + pregnant.birthTime
    local worldTime = world.day() + world.timeOfDay()
    
    if (worldTime >= birthTime) then
      if (callback ~= nil) then
        status.setStatusProperty("pregnant", nil) -- Ensure NPC is no longer pregnant
      
        return callback()
      end
      
      return true
    end
  end
  
  return false
end

function unloadNPC()
  npc.setDropPools({}) -- prevent loot drop
  npc.setDeathParticleBurst(nil) -- prevent death particle effect
  
  npc.setPersistent(false)

  -- Kill the NPC
  status.applySelfDamageRequest({
    damageType       = "IgnoresDef",
    damage           = status.resourceMax("health"),
    damageSourceKind = "fire",
    sourceEntityId   = entity.id()
  })
end