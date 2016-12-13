local combinedPatient = require "acupera.combinedPatient"

local customMappings = {
   USMM = require "acupera.clients.USMM.hl7Mapper"
}

local function getMapperName(hl7Message)
   local messageCode = hl7Message.MSH[9][1]:nodeValue()
   local messageEvent = hl7Message.MSH[9][2]:nodeValue()
   
   return "map"..messageCode..messageEvent
end

local function getCustomMapper(hl7Message)
   local sendingApplication = hl7Message.MSH[3][1]:nodeValue()
   local sendingFacility = hl7Message.MSH[4][1]:nodeValue()
   
   for clientName, clientMapping in pairs(customMappings) do
      for i, keyMapping in pairs(clientMapping.keys) do
         if keyMapping.sendingApplication ~= sendingApplication then break end
         
         for j, facility in pairs(keyMapping.sendingFacilities) do
            if facility == sendingFacility then
               return customMappings[clientName]
            end
         end
      end
   end
   
   return nil
end

local function isSupported(hl7Message)
   local customMapper = getCustomMapper(hl7Message)
   
   if customMapper == nil then return false end
   
   return customMapper[getMapperName(hl7Message)] ~= nil
end

local function map(hl7Message, patient)
   local customMapper = getCustomMapper(hl7Message)
   
   if customMapper == nil then return end
   
   customMapper[getMapperName(hl7Message)](hl7Message, patient)
end

return {
   isSupported = isSupported,
   map = map
}