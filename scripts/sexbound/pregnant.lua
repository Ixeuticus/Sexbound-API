--- Pregnant Module.
-- @module pregnant
pregnant = {}

require "/scripts/util.lua"

--- Returns the enabled status of the pregnant module.
-- @return boolean enabled
function pregnant.isEnabled()
  return self.sexboundConfig.pregnant.enabled
end

--- Outputs debug information about the pregnancy with sb.logInfo.
function pregnant.debugPregnancy()
  if (storage.birthDate ~= nil and storage.birthTime ~= nil) then
    local entityId = entity.id()
  
    sb.logInfo("Entity Id (" .. entityId .. ") is going to give birth on day (" .. storage.birthDate .. ") at time (" .. storage.birthTime .. ")")
  end
end

--- Removes the pregnancy status of this entity.
function pregnant.clear()
  if not pregnant.isEnabled() then return end

  cleanupPregnancy()
end

--- Private: Creates and stores the birth date for this entity.
local function createBirthday()
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

--- Private: Creates and stores the birth time for this entity.
local function createBirthTime()
  -- Generate random time to give birth
  storage.birthTime = util.randomInRange({0.0, 1.0})
end

--- Private: Makes the entity become pregnant when it is not already pregnant.
--@return Success: returns true
--@return Failute: returns false
local function becomePregnant()
  if not pregnant.isEnabled() then return false end

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
  
  return true
end

--- Attempt to make the entity become pregnant.
-- @param[opt] callback executes inputted function if the entity becomes pregnant.
-- @return Success: returns the callback function's return value or true
-- @return Failure: returns false
function pregnant.tryBecomePregnant(callback)
  if not pregnant.isEnabled() then return end

  -- Generate random chance of becoming pregnant
  local chance = util.randomInRange({0.0, 1.0})
  
  -- Compare random chance with fertility. Success on chance is less than or equal to fertility
  if (chance <= self.sexboundConfig.pregnant.fertility and becomePregnant()) then 
    local output = callback()
    
    if (output ~= nil) then
      return output
    end
    
    return true
  end
  
  return false
end

--- Private: Removes the pregnancy data from this entities storage.
local function cleanupPregnancy()
  if not pregnant.isEnabled() then return end

  storage.isPregnant = false
  storage.birthDate  = nil
  storage.birthTime  = nil
end

-- Private: Automatically cleanup the pregnancy.
local function giveBirth()
  if not pregnant.isEnabled() then return end

  -- Clean up pregnancy after entity gives birth
  cleanupPregnancy()
  
  return true
end

--- Attempt to make the entity give birth.
-- @param[opt] callback executes inputted function if the entity gives birth.
-- @return Success: returns the callback function's return value or true
-- @return Failure: returns false
function pregnant.tryGiveBirth(callback)
  if not pregnant.isEnabled() then return end

  -- Check that a birth date has been set
  if (storage.birthDate ~= nil and storage.birthTime ~= nil) then
    local birthTime = storage.birthDate + storage.birthTime
    local worldTime = world.day() + world.timeOfDay()

    -- If the birth date is today or later then give birth
    if (worldTime >= birthTime and giveBirth()) then
      local output = callback()
    
      if (output ~= nil) then
        return output
      end
    
      return true
    end
  end
  
  return false
end


