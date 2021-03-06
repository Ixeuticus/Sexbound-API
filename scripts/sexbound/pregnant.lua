--- Pregnant Module.
-- @module pregnant
pregnant = {}

require "/scripts/sexbound/helper.lua"

function pregnant.init()
  if not self.sexboundConfig then
    self.sexboundConfig = root.assetJson("/scripts/sexbound/default.config")
  end
end

--- Returns the enabled status of the pregnant module.
-- @return boolean enabled
function pregnant.isEnabled()
  return self.sexboundConfig.pregnant.enabled
end

--- Returns the pregnant status this entity
-- @return boolean value
pregnant.isPregnant = function()
  return storage.pregnant and storage.pregnant.isPregnant
end

--- Private: Returns a random birth date and day count
-- @return birthDate
-- @return dayCount
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
  
  return birthDate, dayCount
end

--- Private: Returns a random birth time
local function createBirthTime()
  return helper.randomInRange({0.0, 1.0})
end

--- Private: Returns a suitable NPC type for the baby
-- @return string as NPC type.
local function createNPCType(target)
  if target.type == "npc" then
    return target.identity.npcType
  end
  return "villager"
end

--- Private: Returns a suitable species for the baby
-- @return string as species name
local function createSpecies(target)
  return target.identity.species
end

--- Returns the name of the partner.
-- @param target the specified actor {data}
function pregnant.findPartnerName(target)
  local name = nil
  
  helper.each(actor.data.list, function(k,v)
    if target.id ~= v.id then name = v.identity.name end
  end)
  
  if (name) then return name end
  
  return "<Unknown Name>"
end

--- Private: Causes the specified entity to become pregnant.
-- @param target the specified actor {data}
-- @return boolean value
local function becomePregnant(target)
  local lpregnant = { isPregnant = true }

  -- Generate a birth date and day count until then
  lpregnant.birthDate, lpregnant.dayCount = createBirthday()
  
  -- Generate random time to give birth
  lpregnant.birthTime = createBirthTime()
  
  lpregnant.npcType = createNPCType(target)
  
  lpregnant.species = createSpecies(target)
  
  lpregnant.motherName = target.identity.name
  
  if not lpregnant.motherName then lpregnant.motherName = "You" end
  
  -- Find the partner name
  lpregnant.partnerName = pregnant.findPartnerName(target)
  
  -- Store the pregnancy according to whether target is a SexNode or not.
  if not target.isSexNode then
    if not target.storage then target.storage = {} end
  
    target.storage.pregnant = lpregnant
    
    world.sendEntityMessage(target.id, "become-pregnant", lpregnant)
  else
    if not target.storage then target.storage = {} end
  
    target.storage.pregnant = lpregnant
  
    storage.pregnant = lpregnant
  end
  
  local messageId = "targetbecamepregnant"
  
  local textSuffix = "days!"
  
  if (lpregnant.dayCount <= 1) then textSuffix = "day!" end
  
  local text1 = "Oopsy! You just impregnanted ^green;" .. lpregnant.motherName .. 
    "^reset;, and she will give birth in ^red;" .. lpregnant.dayCount .. "^reset; " ..
    textSuffix

  local text2 = "Oppsy! You were just impregnated by ^green;" ..  lpregnant.partnerName ..
    "^reset;, and you will give birth in ^red;" .. lpregnant.dayCount .. "^reset; " ..
    textSuffix
    
  local text3 = lpregnant.partnerName .. " just impregnanted ^green;" .. lpregnant.motherName .. 
    "^reset;, and she will give birth in ^red;" .. lpregnant.dayCount .. "^reset; " .. 
    textSuffix
  
  -- Broadcast radio message to the players
  if sex.data.player then
    -- Send radio message to the player
    if sex.data.player.identity.gender == "male" then
      helper.radioPlayer(sex.data.player.id, messageId, text1)
    end
    
    if sex.data.player.identity.gender == "female" then
      helper.radioPlayer(sex.data.player.id, messageId, text2)
    end
    
    helper.radioAllOtherPlayers(sex.data.player.id, messageId, text3)
  else
    helper.radioAllPlayers(messageId, text3)
  end
  
  return true
end

--- Attempt to make the entity become pregnant.
-- @param[opt] callback executes inputted function if the entity becomes pregnant.
-- @return Success: returns the callback function's return value or true
-- @return Failure: returns false
function pregnant.tryBecomePregnant(callback)
  -- Check the pregnancy chance while in current position
  local possiblePregnancy = position.selectedSexPosition().possiblePregnancy

  if possiblePregnancy ~= nil then
    helper.each(actor.data.list, function(k, v)
      if possiblePregnancy[k] and v.gender == "female" then
        if v.isSexNode and storage.pregnant and storage.pregnant.isPregnant then return false end
        if v.storage and v.storage.pregnant and v.storage.pregnant.isPregnant then return false end

        -- Generate random chance of becoming pregnant
        local chance = helper.randomInRange({0.0, 1.0})
        
        -- Compare random chance with fertility. Success on chance is less than or equal to fertility.
        if chance <= self.sexboundConfig.pregnant.fertility and becomePregnant(v) then 
          if callback ~= nil then
            return callback()
          end

          return true -- SUCCESS
        end
      end
    end)
  end

  return false -- FAILURE
end

function pregnant.clear()
  storage.pregnant = {isPregnant = false}
end

--- Causes the current entity to give birth.
-- @param data options
function pregnant.giveBirth(callback)
  if callback ~= nil then -- Handle giving birth in callback
    return callback()
  end

  local lpregnant = storage.pregnant

  local parameters = {
    statusControllerSettings = {
      statusProperties = {
        birthday = lpregnant
      }
    }
  }
  
  world.spawnNpc(entity.position(), lpregnant.species, lpregnant.npcType, 1, nil, parameters) -- level 1
end

--- Attempt to make the entity give birth.
-- @param[opt] callback executes inputted function if the entity gives birth.
-- @return boolean value
function pregnant.tryToGiveBirth(callback)
  local lpregnant = storage.pregnant
  
  local birthTime = lpregnant.birthDate + lpregnant.birthTime
  local worldTime = world.day() + world.timeOfDay()
  
  if (worldTime >= birthTime) then
    if (callback ~= nil) then      
      return callback()
    end
    
    return true
  end
  
  return false
end

--- Updates a current pregnancy.
-- @param[opt] callback
function pregnant.update(callback)
  if pregnant.isPregnant() then
    pregnant.tryToGiveBirth(function()      
      pregnant.giveBirth(callback)
      
      pregnant.clear()
    end)
  end
end