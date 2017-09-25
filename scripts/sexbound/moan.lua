--- Moan Module.
-- @module moan
moan = {}

require "/scripts/sexbound/helper.lua"

--- Initializes the moan module.
moan.init = function()
  if (animator.hasSound("femalemoan")) then
    self.femaleMoans = {
      "/sfx/sexbound/moans/femalemoan1.ogg",
      "/sfx/sexbound/moans/femalemoan2.ogg",
      "/sfx/sexbound/moans/femalemoan3.ogg",
      "/sfx/sexbound/moans/femalemoan4.ogg",
      "/sfx/sexbound/moans/femalemoan5.ogg"
    }
  
    animator.setSoundPool("femalemoan", self.femaleMoans)
  end
  
  if (animator.hasSound("malemoan")) then
    self.maleMoans = {
      "/sfx/sexbound/moans/malemoan1.ogg",
      "/sfx/sexbound/moans/malemoan2.ogg",
      "/sfx/sexbound/moans/malemoan3.ogg"
    }
    
    animator.setSoundPool("malemoan", self.maleMoans)
  end
end

--- Returns the enabled status of the moan module.
-- @return boolean enabled
moan.isEnabled = function()
  return self.sexboundConfig.moan.enabled
end

--- Calls on the animator to play a random moan sound effect based on the provided gender type.
--@param gender a string to specify the gender
moan.playRandom = function(gender)
  if (gender == nil) then
    gender = self.sexboundConfig.moan.gender
  end

  if not (moan.isEnabled()) then return false end

  local pitch = helper.randomInRange(self.sexboundConfig.moan.pitch)
  
  -- Check if animator has sound
  if (animator.hasSound(gender .. "moan")) then
    animator.setSoundPitch(gender .. "moan", pitch, 0)
    animator.playSound(gender .. "moan")
  end
  
  if (emote.isEnabled()) then
    emote.playMoan()
  end
end