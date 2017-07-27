moan = {}

moan.init = function()
  local moanConfig = config.getParameter("sexboundConfig").moan

  util.each(moanConfig, function(k,v)
    self.sexboundConfig.moan[k] = v
  end)

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

moan.isEnabled = function()
  return self.sexboundConfig.moan.enabled
end

moan.playRandom = function(gender)
  if not (moan.isEnabled()) then return false end

  local pitch = util.randomInRange(self.sexboundConfig.moan.pitch)
  
  -- Check if animator has sound
  if (animator.hasSound(gender .. "moan")) then
    animator.setSoundPitch(gender .. "moan", pitch, 0)
    animator.playSound(gender .. "moan")
  end
end