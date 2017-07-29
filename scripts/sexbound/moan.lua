--- Moan Module.
-- @module moan
moan = {}

require "/scripts/util.lua"

--- Initializes the moan module.
moan.init = function()
  local moanConfig = config.getParameter("sexboundConfig").moan

  if (moanConfig ~= nil) then
    util.each(moanConfig, function(k,v)
      self.sexboundConfig.moan[k] = v
    end)
  end

  self.femaleMoans = {
    "/sfx/sexbound/moans/femalemoan1.ogg",
    "/sfx/sexbound/moans/femalemoan2.ogg",
    "/sfx/sexbound/moans/femalemoan3.ogg",
    "/sfx/sexbound/moans/femalemoan4.ogg",
    "/sfx/sexbound/moans/femalemoan5.ogg"
  }
  
  -- Needs to be implemented
  self.maleMoans = {}

  animator.setSoundPool("femalemoan", self.femaleMoans)
end

--- Returns the enabled status of the moan module.
-- @return boolean enabled
moan.isEnabled = function()
  return self.sexboundConfig.moan.enabled
end

--- Calls on the animator to play a random moan sound effect based on the provided gender type.
--@param gender a string to specify the gender
moan.playRandom = function(gender)
  if not (moan.isEnabled()) then return false end

  local pitch = util.randomInRange(self.sexboundConfig.moan.pitch)
  
  -- Check if animator has sound
  if (animator.hasSound(gender .. "moan")) then
    animator.setSoundPitch(gender .. "moan", pitch, 0)
    animator.playSound(gender .. "moan")
  end
end