function init()
  -- Set 'havingSex' status property for NPCs
  if (entity.entityType() == "npc") then
    status.setStatusProperty("havingSex", true)
  end
end
