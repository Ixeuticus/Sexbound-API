require "/scripts/sexbound/sex.lua"
require "/scripts/vec2.lua"

function init()
  if (storage.isInTrance) then
    respawnNPC()
  end
  
  storage.isInTrance = true

  startTranceTimer()

  sex.init(function()
    if (storage.npc ~= nil) then
      sex.setupActor(storage.npc)
    end
  end)
end

function unit()

end

function update(dt)
  sex.loop(dt)
  
  self.tranceTimer = self.tranceTimer + dt
  
  if (self.tranceTimer >= self.tranceTimeout) then
    respawnNPC()
  end
  
  -- Setup actor 1 with NPC identifiers
  updateMessage("retrieve-npc-identity", function(result)
    sex.setupActor(result)
  end)
end

function onInteraction(args)
  local result = sex.handleInteract(args)
  
  if (result ~= nil) then return result end
end

function respawnNPC()
  -- Set spawn offset
  local position = vec2.add(object.position(), {0, 5})

  if (storage.npc ~= nil) then
    world.spawnNpc(position, storage.npc.species, storage.npc.type, storage.npc.level, storage.npc.seed)
    
    object.smash(true)
  end
end

function startTranceTimer()
  self.tranceTimer = 0

  self.tranceTimeout = 300 -- 5 minutes
end

-- Handles sending a message to the source entity.
function sendMessage(message, args, wait)
  if (wait == nil) then wait = false end

  -- Prepare new message to store data
  if (self.messenger[message] == nil) then
    self.messenger[message] = {}
    self.messenger[message].promise = nil
    self.messenger[message].busy = false
  end
  
  -- If not already busy then send message
  if not (self.messenger[message].busy) then
    self.messenger[message].promise = world.sendEntityMessage(pane.sourceEntity(), message, args)
    
    self.messenger[message].busy = wait
  end
end

-- Handles response from the source entity.
function updateMessage(message, callback)
  if (self.messenger == nil) then return end

  if (self.messenger[message] == nil) then return end

  local promise = self.messenger[message].promise

  if (promise and promise:finished()) then
    local result = promise:result()
    
    self.messenger[message].promise = nil
    self.messenger[message].busy = false
    
    callback(result)
  end
end