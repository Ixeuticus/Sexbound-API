require "/scripts/sexbound/sex.lua"
require "/scripts/sexbound/helper.lua"
require "/scripts/vec2.lua"

--- Hook - Handles object's init phase.
function init()
  self.setUniqueIdTimer = 0

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
  if (storage.npc.uniqueId and storage.npc.uniqueId ~= object.uniqueId()) then
    sex.tryToSetUniqueId(storage.npc.uniqueId, function(uniqueId)
      pcall( 
        function() 
          self.canSetUniqueId = true
        end
      ) -- Try to catch any exceptions
    end)
  end
  
  -- Set unique id on timed delay
  if (self.canSetUniqueId) then
    self.setUniqueIdTimer = self.setUniqueIdTimer + dt
    
    if (self.setUniqueIdTimer >= 0.5) then -- wait for 0.5 of a second
      object.setUniqueId( storage.npc.uniqueId ) 
      self.canSetUniqueId = false
    end
  end
  
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
    local position = vec2.add(object.position(), {0, 5})
  
    local parameters = {}
  
    if (pregnant.isPregnant()) then
      parameters.statusControllerSettings = {
        statusProperties = {
          pregnant = storage.pregnant
        }
      }
    end
    
    if (storage.npc.uniqueId or storage.npc.home) then
      parameters.scriptConfig = {}
    
      if (storage.npc.uniqueId) then
        parameters.scriptConfig.actualUniqueId  = storage.npc.uniqueId
      end
      
      if (storage.npc.storage) then
        parameters.scriptConfig.previousStorage = storage.npc.storage
      end
    end
    
    world.spawnNpc(position, storage.npc.species, storage.npc.type, storage.npc.level, storage.npc.seed, parameters)
  end
end

--- Resets this objects trance timer.
function resetTranceTimer()
  storage.isInTrance = true

  self.tranceTimeout = world.day() + world.timeOfDay() + 0.2
end
