--- Sextoy Module.
-- @module sextoy
sextoy = {}

require "/scripts/sexbound/helper.lua"

sextoy.init = function()
  message.setHandler("changeSlot1Sextoy", function(_, _, change)
    self.slot1Current = self.slot1Current + change
    
    if (self.slot1Current <= 0) then
      self.slot1Current = self.slot1Count
    end
    
    if (self.slot1Current > self.slot1Count) then
      self.slot1Current = 1
    end
    
    local image = self.sexboundConfig.sextoy.slot1[self.slot1Current].image
    
    animator.setGlobalTag("sextoy", image)
  end)

  local slot1 = self.sexboundConfig.sextoy.slot1
  
  self.slot1Count = 0
  
  -- Count slots in slot 1
  if (slot1 ~= nil) then
    helper.each(slot1, function(k, v)
      self.slot1Count = self.slot1Count + 1
    end)
  end
  
  self.slot1Current = 1
end

--- Returns the enabled status of the sextoy module.
-- @return boolean enabled
sextoy.isEnabled = function()
  return self.sexboundConfig.sextoy.enabled
end
