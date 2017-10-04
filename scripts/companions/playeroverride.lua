-- Override init function. First defined in '/scripts/companions/player.lua'
sexbound_oldInit = init
function init()
  sexbound_oldInit()

  message.setHandler("transform-into-object", function(_, _, args)
    --sb.logInfo("Recruit recieved message to transform into object!")
    --sb.logInfo("Unique Id: " .. args.uniqueId)
    
    recruitSpawner:forEachCrewMember(function(recruit)
      if ( args.uniqueId == recruit.uniqueId ) then
        recruit.storage.transformIntoObject = true
        recruit.storage.previousUuid = recruit.uniqueId
        
        world.sendEntityMessage(args.uniqueId, "unload", nil)
        return true
      end
    end)
    
    return true
  end)
  
  message.setHandler("transform-into-npc", function(_, _, args)
    --sb.logInfo("Recruit recieved message to transform into npc!")
    --sb.logInfo("Unique Id: " .. args.uniqueId)
    
    recruitSpawner:forEachCrewMember(function(recruit)
      if ( args.uniqueId == recruit.storage.previousUuid ) then
        recruit.uniqueId = recruit.storage.previousUuid
        recruit.storage.transformIntoObject = false
        recruit.hasDied = false
        return true
      end
    end)
    
    return true
  end)
  
  -- For each recruit set the owner Uuid
  recruitSpawner:forEachCrewMember(function( recruit )
    recruit.storage.ownerUuid = entity.uniqueId()
    recruit.storage.isRecruit = true
    recruit.storage.transformIntoObject = false
    recruit.hasDied = false
  end)
end

recruitSpawner.oldRespawnRecruit = recruitSpawner.respawnRecruit
function recruitSpawner:respawnRecruit(uuid, recruit)
  if not recruit.storage.transformIntoObject then
    recruitSpawner:oldRespawnRecruit(uuid, recruit)
  else
    --sb.logInfo("Cannot respawn while the NPC is an object!")
  end
end

recruitSpawner.oldUninit = recruitSpawner.uninit
function recruitSpawner.uninit()
  recruitSpawner:oldUninit()

  recruitSpawner:forEachCrewMember(function( recruit )
    recruit.storage.transformIntoObject = false
  end)
end

function recruitSpawner:shipUpdate(dt)
  self:_updateRecruits(self.shipCrew, true, dt)

  local toRespawn = {}
  self:forEachCrewMember(function (recruit)
      --if (recruit:dead()) then sb.logInfo("Recruit is dead!") end
  
      if recruit:dead() or (recruit.persistent and not recruit.uniqueId) then
        toRespawn[recruit.podUuid] = recruit
      else
        recruit.benefits:shipUpdate(recruit, dt)
      end
    end)

  for uuid, recruit in pairs(toRespawn) do
    self:respawnRecruit(uuid, recruit)
  end
end