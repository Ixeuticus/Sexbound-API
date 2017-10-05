require "/scripts/sexbound/sex.lua"
require "/scripts/sexbound/helper.lua"
require "/scripts/vec2.lua"

--- Hook - Handles object's init phase.
function init()
  if (storage.isInTrance) then 
    object.smash(true)
  end

  resetTranceTimer()

  sex.init(function()
    if (storage.npc ~= nil) then
      actor.setupActor(storage.npc, false)
    end
  end)
end

function uninit()
  object.smash(true)
end

--- Hook - Handles object's death.
function die()
  respawnNPC()
end

--- Hook - Handles object's update phase.
function update(dt)
  sex.loop(dt)
  
  local worldTime = world.day() + world.timeOfDay()
  
  if not sex.isHavingSex() and (worldTime >= self.tranceTimeout) then
    object.smash(true)
  end
end

-- Hook - Handles object's onInteraction event.
function onInteraction(args)
  local result = sex.handleInteract(args)
  
  if (result ~= nil) then return result end
end

--- Respawns NPC.
function respawnNPC()
  -- Set NPC spawn offset offset
  if (storage.npc ~= nil) then
    -- Improve this code.
    if storage.npc.storage.ownerUuid then 
      world.sendEntityMessage(storage.npc.storage.ownerUuid, "transform-into-npc", {uniqueId = storage.npc.uniqueId})
    return end -- Don't respawn a follower
    
    local position = vec2.add(object.position(), {0, 3})
    
    -- Copy reference to pregnant storage into NPC storage
    if storage.pregnant and storage.pregnant.isPregnant then
      storage.npc.storage.pregnant = storage.pregnant
    end
    
    local parameters = {
      statusControllerSettings = {
        statusProperties = {
          prevStorage = storage.npc.storage
        }
      }
    }
    
    if (storage.npc.uniqueId and not world.findUniqueEntity(storage.npc.uniqueId):result()) then
      parameters.scriptConfig = {}
      parameters.scriptConfig.uniqueId = storage.npc.uniqueId
    end
    
    world.spawnNpc(position, storage.npc.species, storage.npc.type, storage.npc.level, storage.npc.seed, parameters)
  end
end

--- Resets this objects trance timer.
function resetTranceTimer()
  storage.isInTrance = true

  self.tranceTimeout = world.day() + world.timeOfDay() + 0.2
end
