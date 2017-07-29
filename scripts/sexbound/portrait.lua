--- Portrait Module.
-- @module portrait
portrait = {}

require "/scripts/util.lua"

--- Initializes the portrait module.
portrait.init = function()
  -- Handle request for the portrait
  message.setHandler("retrievePortrait", function()
    return self.sexboundConfig.portrait
  end)
  
  local portraitConfig = config.getParameter("sexboundConfig").portrait
  
  -- Try to load in portrait settings
  if (portraitConfig ~= nil) then
    util.each(portraitConfig, function(k,v)
      self.sexboundConfig.portrait[k] = v
    end)
  end
end

--- Returns the currently set default portrait image.
--@return string: the image path
portrait.getCurrentPortrait = function()
  return config.getParameter("sexboundConfig").portrait.default.image
end