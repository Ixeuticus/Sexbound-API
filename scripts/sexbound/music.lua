--- Music Module.
-- @module music
music = {}

require "/scripts/util.lua"

--- Returns the enabled status of the sex talk module.
-- @return boolean enabled
music.isEnabled = function()
  return self.sexboundConfig.music.enabled
end