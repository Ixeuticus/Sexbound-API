portrait = {}

portrait.init = function()
  -- Handle request for the portrait
  message.setHandler("retrievePortrait", function()
    return self.sexboundConfig.portrait
  end)
  
  local portraitConfig = config.getParameter("sexboundConfig").portrait
  
  util.each(portraitConfig, function(k,v)
    self.sexboundConfig.portrait[k] = v
  end)
end

portrait.getCurrentPortrait = function()
  return config.getParameter("sexboundConfig").portrait.default.image
end