---Helper Module.
-- @module helper
helper = {}

require "/scripts/util.lua"

---Wrapper function for util.clamp
-- @param value Numerical value to operate on
-- @param min Minimum value to return
-- @param max Maximum value to return
helper.clamp = function(value, min, max)
  return util.clamp(value, min, max)
end

--- Counts elements in table and returns the value.
-- @param t List of elements.
helper.count = function(t)
  if not t then return nil end
  
  local count = 0
  
  helper.each(t, function(k, v)
    count = count + 1
  end)
  
  return count
end

---Wrapper function for util.each
-- @param t Data as table
-- @param callback Callback function. Takes arguments k = key and v = value.
helper.each = function(t, callback)
  return util.each(t, callback)
end

---Wrapper function for util.find
-- @param t Data as table
-- @param predicate
-- @param index
helper.find = function(t, predicate, index)
  return util.find(t, predicate, index)
end

---Wrapper function for util.mergeTable
-- @param t1 Data for table 1
-- @param t2 Data for table 2
helper.mergeTable = function(t1, t2)
  return util.mergeTable(t1, t2)
end

---Wrapper function for util.randomChoice
-- @param options table
helper.randomChoice = function(options)
  return util.randomChoice(options)
end

---Wrapper function for util.randomDirection
helper.randomDirection = function()
  return util.randomDirection()
end

---Wrapper function for util.randomInRange
-- @param numberRange Range of numbers
helper.randomInRange = function(numberRange)
  return util.randomInRange(numberRange)
end

---Wrapper function for util.randomIntInRange
-- @param numberRange Range of numbers
helper.randomIntInRange = function(numberRange)
  return util.randomIntInRange(numberRange)
end

---Wrapper function for util.replaceTag
-- @param data Data to scan for tags
-- @param tagName String The name of the tagName
-- @param tagValue String value to assign to the tag
helper.replaceTag = function(data, tagName, tagValue)
  return util.replaceTag(data, tagName, tagValue)
end

---Creates and stores a new message.
-- @param message reference name of the message.
helper.resetMessenger = function(message)
  self.messenger[message] = {promise = nil, busy = false}
end

---Handles sending a message to a specified entity.
-- @param entityId String: A remote entity id or unique id.
-- @param message String: The message to send the remote entity.
-- @param args Table: Arguments to send to th remote entity.
-- @param wait Boolean: true = wait for response before sending again. false = send without waiting
helper.sendMessage = function(entityId, message, args, wait)
  if (self.messenger == nil) then self.messenger = {} end

  if (wait == nil) then wait = false end

  -- Prepare new message to store data
  if (self.messenger[message] == nil) then
    helper.resetMessenger(message)
  end
  
  -- If not already busy then send message
  if not (self.messenger[message].busy) then
    self.messenger[message].promise = world.sendEntityMessage(entityId, message, args)
    
    self.messenger[message].busy = wait
  end
end

---Handles response from the source entity.
-- @param message String: The message to send the remote entity.
-- @param callback
helper.updateMessage = function(message, callback)
  if (self.messenger == nil) then self.messenger = {} end

  if (self.messenger[message] == nil) then return end

  local promise = self.messenger[message].promise

  if (promise and promise:finished()) then
    local result = promise:result()
    
    helper.resetMessenger(message)
    
    callback(result)
  end
end

helper.parsePortraitData = function(species, gender, data)
  local result = nil

  -- Check if species is supported
  helper.each({"apex", "avian", "floran", "glitch", "human", "hylotl", "novakid"}, function(k, v)
    if (species == v) then result = true end
  end)

  local identity = {
    bodyDirectives = "",
    emoteDirectives = "",
    facialHairDirectives = "",
    facialHairFolder = "",
    facialHairGroup = "",
    facialHairType = "",
    facialMaskDirectives = "",
    facialMaskFolder = "",
    facialMaskGroup = "",
    facialMaskType = "",
    hairFolder = "hair",
    hairGroup = "hair",
    hairType = "1",
    hairDirectives = "",
    gender = "female",
    species = "human"
  }

  if not result then return identity end
  
  identity.gender = gender
  
  identity.species = species
  
  helper.each(data, function(k, v)
    -- Try to find beaks identity
    if (string.find(v.image, "/beaks") ~= nil) then
      identity.facialMaskGroup = "beaks"
      identity.facialMaskFolder, identity.facialMaskType  = string.match(v.image, '^.*/(beaks.*)/(.*)%.png')
      identity.facialMaskDirectives = helper.filterReplace(v.image)
    end
    
    -- Try to find beard identity
    if (string.find(v.image, "/beard") ~= nil) then
      identity.facialHairGroup = "beard"
      identity.facialHairFolder, identity.facialHairType  = string.match(v.image, '^.*/(beard.*)/(.*)%.png')
      identity.facialHairDirectives = helper.filterReplace(v.image)
    end
  
    -- Try to find body identity
    if (string.find(v.image, "body.png") ~= nil) then
      identity.bodyDirectives = string.match(v.image, '%?replace.*')
    end
  
    -- Try to find brand identity
    if (string.find(v.image, "/brand") ~= nil) then
      identity.facialHairGroup = "brand"
      identity.facialHairFolder, identity.facialHairType = string.match(v.image, '^.*/(brand.*)/(.*)%.png')
      identity.facialHairDirectives = helper.filterReplace(v.image)
    end
    
    -- Try to find fluff identity
    if (string.find(v.image, "/fluff") ~= nil) then
      identity.facialHairGroup = "fluff"
      identity.facialHairFolder, identity.facialHairType  = string.match(v.image, '^.*/(fluff.*)/(.*)%.png')
      identity.facialHairDirectives = helper.filterReplace(v.image)
    end
    
    -- Try to find emote identity
    if (string.find(v.image, "emote.png") ~= nil) then
      identity.emoteDirectives = helper.filterReplace(v.image)
    end
    
    -- Try to find hair identity
    if (string.find(v.image, "/hair") ~= nil) then
      identity.hairFolder, identity.hairType = string.match(v.image, '^.*/(hair.*)/(.*)%.png')
      
      identity.hairDirectives = helper.filterReplace(v.image)
    end
  end)
  
  return identity
end

helper.filterReplace = function(image)
  if (string.find(image, "?addmask")) then
    if (string.match(image, '^.*(%?replace.*%?replace.*)%?addmask.-$')) then
      return string.match(image, '^.*(%?replace.*%?replace.*)%?addmask.-$')
    else
      return string.match(image, '^.*(%?replace.*)%?addmask.-$')
    end
  else
    if (string.match(image, '^.*(%?replace.*%?replace.*)')) then
      return string.match(image, '^.*(%?replace.*%?replace.*)')
    else
      return string.match(image, '^.*(%?replace.*)')
    end
  end
  
  return ""
end
