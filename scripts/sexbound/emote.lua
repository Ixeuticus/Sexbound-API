require "/scripts/util.lua"

emote = {}

emote.init = function()
  local emoteConfig = config.getParameter("sexboundConfig").emote
  
  util.each(emoteConfig, function(k,v)
    self.sexboundConfig.emote[k] = v
  end)
end

emote.isEnabled = function()
  return self.sexboundConfig.emote.enabled
end

emote.playRandom = function()
  if not (emote.isEnabled()) then return false end

  animator.burstParticleEmitter(util.randomChoice(self.sexboundConfig.emote.sequence))
end