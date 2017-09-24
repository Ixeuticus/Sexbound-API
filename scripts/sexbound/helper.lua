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