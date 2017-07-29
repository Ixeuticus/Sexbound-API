--- Emote Module.
-- @module emote
emote = {}

require "/scripts/util.lua"

--- Initializes the emote module.
emote.init = function()
  local emoteConfig = config.getParameter("sexboundConfig").emote
  
  -- Try to load in emote settings
  util.each(emoteConfig, function(k,v)
    self.sexboundConfig.emote[k] = v
  end)
end

--- Returns the enabled status of the emote module.
-- @return boolean enabled
emote.isEnabled = function()
  return self.sexboundConfig.emote.enabled
end

--- Calls on the animator to emit a random emote.
emote.playRandom = function()
  if not (emote.isEnabled()) then return false end

  animator.burstParticleEmitter(util.randomChoice(self.sexboundConfig.emote.sequence))
end