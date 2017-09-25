--- Emote Module.
-- @module emote
emote = {}

require "/scripts/sexbound/helper.lua"

emote.data = {
  list = {}
}

--- Returns the enabled status of the emote module.
-- @return boolean enabled
emote.isEnabled = function()
  return self.sexboundConfig.emote.enabled
end

emote.getAvailableEmotes = function(stateName)
  return self.sexboundConfig.emote[stateName]
end

--- Calls on the animator to emit a random emote for moaning.
emote.playMoan = function()
  if (actor.isEnabled()) then
    local availableEmotes = self.sexboundConfig.moan.emote
    
    helper.each(actor.data.list, function(k, v) -- Store a random emote for each actor
      if (v.type ~= "player" and availableEmotes) then
        local choice = helper.randomChoice(availableEmotes)
        
        local emoteDirectives = ""
        
        if (v.identity.emoteDirectives) then
          emoteDirectives = v.identity.emoteDirectives
        end
        
        local partEmote = "/humanoid/" .. v.species .. "/emote.png:" .. choice .. emoteDirectives
        
        animator.setGlobalTag("part-actor" .. k .. "-emote", partEmote)
      end
    end)
  end
end

--- Calls on the animator to emit a random emote.
emote.playRandom = function(stateName)
  if (actor.isEnabled()) then
    local availableEmotes = emote.getAvailableEmotes(stateName)
  
    helper.each(actor.data.list, function(k, v) -- Store a random emote for each actor
      if (v.type ~= "player" and availableEmotes) then
        local choice = helper.randomChoice(availableEmotes)
        
        local emoteDirectives = ""
        
        if (v.identity.emoteDirectives) then
          emoteDirectives = v.identity.emoteDirectives
        end
        
        local partEmote = "/humanoid/" .. v.species .. "/emote.png:" .. choice .. emoteDirectives
        
        animator.setGlobalTag("part-actor" .. k .. "-emote", partEmote)
      end
    end)
  else
    animator.burstParticleEmitter( helper.randomChoice(self.sexboundConfig.emote.sequence) )
  end
end
