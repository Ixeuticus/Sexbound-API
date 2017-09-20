--- POV Module.
-- @module pov
pov = {}

--- Initializes the pov module.
pov.init = function()
  -- Handle request for the portrait
  message.setHandler("retrievePOV", function()
    return self.sexboundConfig.pov
  end)
end

--- Returns the enabled status of the pov module.
-- @return boolean enabled
pov.isEnabled = function()
  return self.sexboundConfig.pov.enabled
end