--- POV Module.
-- @module pov
pov = {}

require "/scripts/util.lua"

--- Initializes the pov module.
pov.init = function()
  -- Handle request for the portrait
  message.setHandler("retrievePOV", function()
    return self.sexboundConfig.pov
  end)
  
  local povConfig = config.getParameter("sexboundConfig").pov
  
  -- Try to load in pov settings
  if (povConfig ~= nil) then
    util.each(povConfig, function(k,v)
      self.sexboundConfig.pov[k] = v
    end)
  end
end

--- Returns the enabled status of the pov module.
-- @return boolean enabled
pov.isEnabled = function()
  return self.sexboundConfig.pov.enabled
end