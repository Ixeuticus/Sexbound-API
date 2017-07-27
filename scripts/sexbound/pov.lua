pov = {}

pov.init = function() 
  -- Handle request for the portrait
  message.setHandler("retrievePOV", function()
    return self.sexboundConfig.pov
  end)
  
  local povConfig = config.getParameter("sexboundConfig").pov
  
  if (povConfig ~= nil) then
    util.each(povConfig, function(k,v)
      self.sexboundConfig.pov[k] = v
    end)
  end
end

pov.isEnabled = function()
  return self.sexboundConfig.pov.enabled
end