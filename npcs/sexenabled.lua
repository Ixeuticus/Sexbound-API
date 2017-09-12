require "/scripts/vec2.lua"

require "/scripts/sexbound/helper.lua"

-- Hack into the loaded /npcs/bmain.lua file through 'updateUniqueId'
oldUpdateUniqueId = updateUniqueId

updateUniqueId = function()
  oldUpdateUniqueId() -- Run the previous version of the function.
  
  -- Init
  if not self.initOnce == nil then
    message.setHandler("retrieve-npc-identity", function()
      local npcData = {}
      
      npcData.identity = npc.humanoidIdentity()
      npcData.gender   = npcData.identity.gender
      npcData.species  = npcData.identity.species
      
      return npcData
    end)
    
    self.initOnce = true
  end
  
  -- Update
  if (status.statusProperty("lust") == true) then
    status.setStatusProperty("lust", false)

    if type(handleSex) == "function" then
      return handleSex()
    end
  end
  
  if (status.statusProperty("havingSex") == true) then
    status.setStatusProperty("havingSex", false)
    
    if type(handleSexRequest) == "function" then
      return handleSexRequest()
    end
  end
end

function handleSexRequest(args)
  local position = vec2.floor(entity.position())
  position[2] = position[2] - 4
  
  local entityId = world.objectAt(position)
  
  if (entityId ~= nil) then
    sendMessage(entityId, "setup-actor", "actor1")
  end
end

function handleSex(args)
  -- Create an object that resembles the npc at the position
  self.position = vec2.floor(entity.position())
  self.position[2] = self.position[2] - 2
  
  self.newUniqueId = tostring(sb.makeRandomSource():randu64())
  
  if (world.placeObject("sexnode", self.position, -1, {uniqueId = self.newUniqueId})) then
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
  -- Ensure the NPC doesn't drop its loot
  npc.setDropPools({})
  npc.setDeathParticleBurst(nil)
  
  npc.setPersistent(true)

  -- Kill the NPC
  status.applySelfDamageRequest({
    damageType = "IgnoresDef",
    damage = status.resourceMax("health"),
    damageSourceKind = "fire",
    sourceEntityId = entity.id()
  })
end