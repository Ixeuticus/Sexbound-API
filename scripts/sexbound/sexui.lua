--- Sex UI Module.
-- @module sexui
sexui = {}

--- Returns the enabled status of the sexui module.
-- @return boolean enabled
sexui.isEnabled = function()
  if self.sexboundConfig ~= nil and self.sexboundConfig.sexui ~= nil and not isEmpty(self.sexboundConfig.sexui) then
    if (self.sexboundConfig.sexui.enabled ~= nil) then
      return self.sexboundConfig.sexui.enabled
    else
      -- Assumed to be enabled
      return true
    end
  end
  
  -- Assumed to be disabled
  return false
end