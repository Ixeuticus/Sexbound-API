--- Music Module.
-- @module music
music = {}

require "/scripts/util.lua"

music.init = function()
  local musicConfig = config.getParameter("sexboundConfig").music

  -- Try to load in music settings
  if (musicConfig ~= nil) then
    util.each(musicConfig, function(k,v)
      self.sexboundConfig.music[k] = v
    end)
  end
end

--- Returns the enabled status of the sex talk module.
-- @return boolean enabled
music.isEnabled = function()
  return self.sexboundConfig.music.enabled
end