--- Sextoy Module.
-- @module sextoy
sextoy = {}

require "/scripts/util.lua"

sextoy.init = function()
  -- Handle request for the sextoys
  message.setHandler("retrieveSextoys", function()
    local slot1Table = nil
  
    if (self.slot1Count > 0) then
      slot1Table = self.sexboundConfig.sextoy.slot1[self.slot1Current]
    end
  
    return {
      slot1 = slot1Table
    }
  end)

  message.setHandler("prevSlot1Sextoy", function()
    self.slot1Current = self.slot1Current - 1
    
    if (self.slot1Current <= 0) then
      self.slot1Current = self.slot1Count
    end
    
    local image = self.sexboundConfig.sextoy.slot1[self.slot1Current].image
    
    animator.setGlobalTag("sextoy", image)
    
    return {
      slot1 = self.sexboundConfig.sextoy.slot1[self.slot1Current]
    }
  end)
  
  message.setHandler("nextSlot1Sextoy", function()
    self.slot1Current = self.slot1Current + 1
    
    if (self.slot1Current > self.slot1Count) then
      self.slot1Current = 1
    end
    
    local image = self.sexboundConfig.sextoy.slot1[self.slot1Current].image
    
    animator.setGlobalTag("sextoy", image)
    
    return {
      slot1 = self.sexboundConfig.sextoy.slot1[self.slot1Current]
    }
  end)
  
  local sextoyConfig = config.getParameter("sexboundConfig").sextoy
  
  -- Try to load in sextoy settings
  if (sextoyConfig ~= nil) then
    util.each(sextoyConfig, function(k,v)
      self.sexboundConfig.sextoy[k] = v
    end)
  end
  
  local slot1 = self.sexboundConfig.sextoy.slot1
  
  self.slot1Count = 0
  
  -- Count slots in slot 1
  if (slot1 ~= nil) then
    util.each(slot1, function(k, v)
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
