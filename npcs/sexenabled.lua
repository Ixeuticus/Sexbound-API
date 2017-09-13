require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/scripts/sexbound/helper.lua"

-- Hack into the loaded /npcs/bmain.lua file through 'updateUniqueId'
oldUpdateUniqueId = updateUniqueId

updateUniqueId = function()
  oldUpdateUniqueId() -- Run the previous version of the function.

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

function handleSexRequest(args)
  local position = vec2.floor(entity.position())
  position[2] = position[2] - 3 -- (3 * 8 = 24)
  
  local entityId = world.objectAt(position)
  
  if (entityId ~= nil) then
    sendMessage(entityId, "setup-actor", "actor1")
  end
end

function transformIntoObject(args)
  -- Create an object that resembles the npc at the position
  local position = vec2.floor(entity.position())
  position[2] = position[2] - 2
  
  self.newUniqueId = tostring(sb.makeRandomSource():randu64())
  
  local faceDirection = util.randomIntInRange({-1, 1})
  
  if (world.placeObject("sexnode", position, faceDirection, {uniqueId = self.newUniqueId})) then
    sendMessage(self.newUniqueId, "setup-actor", "actor2")
  
    unloadNPC()
  end
end

function sendMessage(uniqueId, message, role)
  local base = false
  
  if (role == "actor2") then base = true end

  local data = {
    base       = base,
    entityType = entity.entityType(),
    identity   = npc.humanoidIdentity(),
    gender     = npc.humanoidIdentity().gender,
    species    = npc.humanoidIdentity().species,
    level      = npc.level(),
    seed       = npc.seed(),
    type       = npc.npcType(),
    role       = role
  }
  
  -- Send the identifying information to the object to be stored.
  helper.sendMessage(uniqueId, message, data, false)
end

function unloadNPC()
  npc.setDropPools({}) -- prevent loot drop
  npc.setDeathParticleBurst(nil) -- prevent death particle effect
  
  npc.setPersistent(true) -- keep the npc loaded in memory

  -- Kill the NPC
  status.applySelfDamageRequest({
    damageType       = "IgnoresDef",
    damage           = status.resourceMax("health"),
    damageSourceKind = "fire",
    sourceEntityId   = entity.id()
  })
end