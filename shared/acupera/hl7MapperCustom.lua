local combinedPatient = require "acupera.combinedPatient"

local customMappings = {
	GPMS = {
      
   }
}

function customMappings.GPMS.mapADTA28(hl7Message, patient)
	local tag = combinedPatient.tag()
   
   tag.Name = "Patient.CustomTags.ETOC"
   tag.Value = "TRUE"
   tag.Type = "Bool"
   patient.Tags[1] = tag
   
   return
end

local function map(hl7Message, patient)
   local customMapper = customMappings[hl7Message.MSH[3][1]:nodeValue()]
   
   if customMapper ~= nil then
      local messageCode = hl7Message.MSH[9][1]:nodeValue()
      local messageEvent = hl7Message.MSH[9][2]:nodeValue()
      local customMapperFunction = customMapper["map"..messageCode..messageEvent]
      
      if customMapperFunction ~= nil then customMapperFunction(hl7Message, patient) end
   end
end

return {
   map = map
}