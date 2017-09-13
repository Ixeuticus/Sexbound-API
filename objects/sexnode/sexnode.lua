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
      sex.setupActor(storage.npc)
    end
  end)
end

--- Hook - Handles object's death.
function die()
  respawnNPC()
end

--- Hook - Handles object's update phase.
function update(dt)
  sex.loop(dt)
  
  self.tranceTimer = self.tranceTimer + dt
  
  if (self.tranceTimer >= self.tranceTimeout) then
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
  
    world.spawnNpc(position, storage.npc.species, storage.npc.type, storage.npc.level, storage.npc.seed)
  end
end

--- Resets this objects trance timer.
function resetTranceTimer()
  storage.isInTrance = true

  self.tranceTimer = 0

  self.tranceTimeout = 300 -- 5 minutes
end
