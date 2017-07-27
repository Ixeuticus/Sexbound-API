require "/scripts/util.lua"

pregnant = {}

function pregnant.init()
  local pregnantConfig = config.getParameter("sexboundConfig").pregnant
  
  util.each(pregnantConfig, function(k,v)
    self.sexboundConfig.pregnant[k] = v
  end)
end

function pregnant.isEnabled()
  return self.sexboundConfig.pregnant.enabled
end

-- Output debug information about the pregnancy
function pregnant.debugPregnancy()
  if (storage.birthDate ~= nil and storage.birthTime ~= nil) then
    local entityId = entity.id()
  
    sb.logInfo("Entity Id (" .. entityId .. ") is going to give birth on day (" .. storage.birthDate .. ") at time (" .. storage.birthTime .. ")")
  end
end

function pregnant.clear()
  if not pregnant.isEnabled() then return end

  cleanupPregnancy()
end

function pregnant.tryBecomePregnant(callback)
  if not pregnant.isEnabled() then return end

  -- Generate random chance of becoming pregnant
  local chance = util.randomInRange({0.0, 1.0})
  
  -- Compare random chance with fertility. Success on chance is less than or equal to fertility
  if (chance <= self.sexboundConfig.pregnant.fertility) then 
    if (becomePregnant()) then
      callback()
    end
  end
end

function pregnant.tryGiveBirth()
  if not pregnant.isEnabled() then return end

  -- Check that a birth date has been set
  if (storage.birthDate ~= nil and storage.birthTime ~= nil) then
    local birthTime = storage.birthDate + storage.birthTime
    local worldTime = world.day() + world.timeOfDay()

    -- If the birth date is today or later then give birth
    if (worldTime >= birthTime) then
      return pregnant.giveBirth()
    end
  end
  
  return false
end

function becomePregnant()
  if not pregnant.isEnabled() then return end

  local entityId = entity.id()

  -- Entity should not get pregnant while already pregnant
  if (storage.isPregnant ~= nil) then
    if (storage.isPregnant) then return false end
  end

  -- Store that the entity is pregnant
  storage.isPregnant = true
  
  -- Create a day for the entity to give birth
  createBirthday()
  
  -- Create a time to give birth on the birth day
  createBirthTime()
  
  sb.logInfo("(" .. entityId .. ") is now pregnate and will give birth on " .. storage.birthDate .. " at time " .. storage.birthTime )
  
  return true
end

function createBirthday(species)
  local dateToday = world.day()
  local trimesterCount = 3
  local trimesterLength = {5, 8}
  local birthDate = dateToday
  
  -- Set trimesterCount if it was specified in the config
  if (self.sexboundConfig.pregnant.trimesterCount ~= nil) then
    trimesterCount = self.sexboundConfig.pregnant.trimesterCount
  end
  
  -- Set trimesterLength if it was specified in the config
  if (self.sexboundConfig.pregnant.trimesterLength ~= nil) then
    trimesterLength = self.sexboundConfig.pregnant.trimesterLength
  end
  
  for i=1,self.sexboundConfig.pregnant.trimesterCount do
    birthDate = birthDate + util.randomIntInRange(self.sexboundConfig.pregnant.trimesterLength)
  end

  storage.birthDate = birthDate
end

function createBirthTime()
  -- Generate random time to give birth
  storage.birthTime = util.randomInRange({0.0, 1.0})
end

function cleanupPregnancy()
  if not pregnant.isEnabled() then return end

  storage.isPregnant = false
  storage.birthDate  = nil
  storage.birthTime  = nil
end

function pregnant.giveBirth()
  if not pregnant.isEnabled() then return end

  -- Clean up pregnancy after entity gives birth
  cleanupPregnancy()
  
  return true
end
