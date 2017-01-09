local combinedPatient = require "acupera.combinedPatient"

local customMappings = {
   Acupera = require "acupera.clients.Acupera.hl7Mapper",
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

help.set{input_function = isSupported, help_data = {
      Title = "acupera.hl7MapperCustom.isSupported",
      Usage = "mapper.isSupported(hl7Message)",
      Desc = "Determines if the message is supported by the client.",
      Parameters = {
         { hl7Message = { Desc = "An HL7 node tree of the message coming into the channel." }}
      },
      Returns = { { Desc = "bool" }},
      Examples = { "mapper.isSupported(hl7Message)" }
}}

help.set{input_function = map, help_data = {
      Title = "acupera.hl7MapperCustom.map",
      Usage = "mapper.map(hl7Message)",
      Desc = "Performs client-specific mapping of the HL7 message to the CombinedPatient.",
      Parameters = {
         { hl7Message = { Desc = "An HL7 node tree of the message coming into the channel." }}
      },
      Returns = nil,
      Examples = { "mapper.map(hl7Message)" }
}}

return {
   isSupported = isSupported,
   map = map
}