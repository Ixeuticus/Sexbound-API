--- Pregnant Module.
-- @module pregnant
pregnant = {}

require "/scripts/sexbound/helper.lua"

function pregnant.init()
  if (storage.pregnant == nil) then
    storage.pregnant = {
      isPregnant = false
    }
  end
end

--- Returns the enabled status of the pregnant module.
-- @return boolean enabled
function pregnant.isEnabled()
  return self.sexboundConfig.pregnant.enabled
end

pregnant.isPregnant = function()
  return storage.pregnant.isPregnant
end

--- Outputs debug information about the pregnancy with sb.logInfo.
function pregnant.debugPregnancy()
  if (storage.pregnant.birthDate ~= nil and storage.pregnant.birthTime ~= nil) then
    local entityId = entity.id()
  
    sb.logInfo("Entity Id (" .. entityId .. ") is going to give birth on day (" .. storage.pregnant.birthDate .. ") at time (" .. storage.pregnant.birthTime .. ")")
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
  
  local dayCount = 0
  
  for i=1,self.sexboundConfig.pregnant.trimesterCount do
    dayCount = dayCount + helper.randomIntInRange(self.sexboundConfig.pregnant.trimesterLength)
  
    birthDate = birthDate + dayCount
  end
  
  storage.pregnant.birthDate = birthDate
  storage.pregnant.dayCount = dayCount
end

--- Private: Creates and stores the birth time for this entity.
local function createBirthTime()
  -- Generate random time to give birth
  storage.pregnant.birthTime = helper.randomInRange({0.0, 1.0})
end

--- Private: Makes the entity become pregnant when it is not already pregnant.
--@return Success: returns true
--@return Failute: returns false
local function becomePregnant(other)
  if not pregnant.isEnabled() then return false end

  -- Entity should not get pregnant while already pregnant
  if (storage.pregnant.isPregnant ~= nil) then
    if (storage.pregnant.isPregnant) then return false end
  end
  
  -- Store that the entity is pregnant
  storage.pregnant.isPregnant = true
  
  -- Create a day for the entity to give birth
  createBirthday()
  
  -- Create a time to give birth on the birth day
  createBirthTime()
  
  local partnerName = "Unknown NPC"
  
  if not actor.hasPlayer() and actor.data.count == 2 then
    helper.each(actor.data.list, function(k, v)
      if (v.id ~= other.id) then
        partnerName = v.identity.name
        return true
      end
    end)
  end

  local txtMessage = ""
  local endMessage = ", and she will give birth in ^red;" .. storage.pregnant.dayCount .. "^reset;"
  if (storage.pregnant.dayCount <= 1) then
    endMessage = endMessage .. " day!"
  else
    endMessage = endMessage .. " days!"
  end
  
  local npcName = "^green;" .. other.identity.name .. "^reset;"
  
  if (actor.hasPlayer()) then
    partnerName = "Unknown Player"
  
    if (sex.data.player.identity.name ~= nil) then
      partnerName = sex.data.player.identity.name
    end
    
    txtMessage = "Oopsy! You just impregnanted " .. npcName
    txtMessage = txtMessage .. endMessage
    
    world.sendEntityMessage(sex.data.player.uuid, "queueRadioMessage", {
      messageId = "entitybecamepregnant",
      unique = false,
      text = txtMessage
    })
  end
  
  -- Broadcast message to all players
  if (partnerName ~= nil) then
    txtMessage = "^green;" .. partnerName .. "^reset; just impregnanted " .. npcName
  else
    txtMessage = npcName .. " was impregnated "
  end
  
  storage.pregnant.partnerName = partnerName
  
  txtMessage = txtMessage .. endMessage
  
  local players = world.players()

  if (actor.hasPlayer()) then
    helper.each(players, function(k, v)
      if (v == sex.data.player.id) then
        table.remove(players, k)
      end
    end)
  end
  
  helper.each(players, function(k, v)
    world.sendEntityMessage(v, "queueRadioMessage", {
      messageId = "entitybecamepregnant",
      unique = false,
      text = txtMessage
    })
  end)
  
  return true
end

--- Attempt to make the entity become pregnant.
-- @param[opt] callback executes inputted function if the entity becomes pregnant.
-- @return Success: returns the callback function's return value or true
-- @return Failure: returns false
function pregnant.tryBecomePregnant(callback)
  -- Check the pregnancy chance while in current position
  local possiblePregnancy = position.selectedSexPosition().possiblePregnancy

  if (possiblePregnancy ~= nil) then
    helper.each(actor.data.list, function(k, v)
      if (possiblePregnancy[k] and v.gender == "female" and v.type ~= "player") then
        -- Generate random chance of becoming pregnant
        local chance = helper.randomInRange({0.0, 1.0})
        
        -- Compare random chance with fertility. Success on chance is less than or equal to fertility
        if (chance <= self.sexboundConfig.pregnant.fertility and becomePregnant(v)) then 
          if (callback ~= nil) then
            return callback()
          end

          return true
        end
      end
    end)
  end

  return false
end

--- Private: Removes the pregnancy data from this entities storage.
local function cleanupPregnancy()
  if not pregnant.isEnabled() then return end

  storage.pregnant = { isPregnant = false }
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
  if (storage.pregnant.birthDate ~= nil and storage.pregnant.birthTime ~= nil) then
    local birthTime = storage.pregnant.birthDate + storage.pregnant.birthTime
    local worldTime = world.day() + world.timeOfDay()

    -- If the birth date is today or later then give birth
    if (worldTime >= birthTime and giveBirth()) then
      if (callback ~= nil) then
        return callback()
      end

      return true
    end
  end
  
  return false
end


