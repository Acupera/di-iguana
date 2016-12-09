local combinedPatient = require "acupera.combinedPatient"

local customMappings = {
   USMM = require "acupera.clients.USMM.hl7Mapper"
}

local function getCustomMapper(hl7Message)
   local messageCode = hl7Message.MSH[9][1]:nodeValue()
   local messageEvent = hl7Message.MSH[9][2]:nodeValue()
   local sendingApplication = hl7Message.MSH[3][1]:nodeValue()
   local sendingFacility = hl7Message.MSH[4][1]:nodeValue()
   
   for clientName, clientMapping in pairs(customMappings) do
      for i, keyMapping in pairs(clientMapping.keys) do
         if keyMapping.sendingApplication ~= sendingApplication then break end
         
         for j, facility in pairs(keyMapping.sendingFacilities) do
            if facility == sendingFacility then
               return customMappings[clientName]["map"..messageCode..messageEvent]
            end
         end
      end
   end
   
   return nil
end

local function map(hl7Message, patient)
   local customMapper = getCustomMapper(hl7Message)
   
   if customMapper ~= nil then customMapper(hl7Message, patient) end
end

return {
   map = map
}