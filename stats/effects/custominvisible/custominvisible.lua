function init()
  -- Hide this entity
  effect.setParentDirectives("?multiply=ffffff00")
  
  -- Set 'havingSex' status property for NPCs
  if (entity.entityType() == "npc") then
    status.setStatusProperty("havingSex", true)
  end
end
