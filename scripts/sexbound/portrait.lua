--- Portrait Module.
-- @module portrait
portrait = {}

--- Initializes the portrait module.
portrait.init = function()
  -- Handle request for the portrait
  message.setHandler("retrievePortrait", function()
    return self.sexboundConfig.portrait
  end)
end

--- Returns the currently set default portrait image.
--@return string: the image path
portrait.getCurrentPortrait = function()
  return config.getParameter("sexboundConfig").portrait.default.image
end