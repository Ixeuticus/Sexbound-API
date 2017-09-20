--- Emote Module.
-- @module emote
emote = {}

require "/scripts/sexbound/helper.lua"

--- Returns the enabled status of the emote module.
-- @return boolean enabled
emote.isEnabled = function()
  return self.sexboundConfig.emote.enabled
end

--- Calls on the animator to emit a random emote.
emote.playRandom = function()
  if not (emote.isEnabled()) then return false end

  animator.burstParticleEmitter(helper.randomChoice(self.sexboundConfig.emote.sequence))
end