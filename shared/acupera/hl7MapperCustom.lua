local combinedPatient = require "acupera.combinedPatient"

local customMappings = {
   USMM = {
      keys = {
         {
            sendingApplication = "GPMS",
            sendingFacilities = { "VPA" }
         }
      }
   }
}

function customMappings.USMM.mapAll(hl7Message, patient)
   local timeZone = "Eastern Standard Time"
   
   for i, identifier in pairs(patient.PatientSearch.PatientIdentifiers) do
      identifier.IdentifierType = "MRN"
      identifier.AssigningAuthority = "CENTRICITY"
   end
   
   for i, coverage in pairs(patient.PatientSearch.PatientCoverages) do
      coverage.LineOfBusiness = "NONE"
      coverage.TimeZone = timeZone
   end
   
   patient.PatientRecord.TimeZone = timeZone
   
   for i, address in pairs(patient.Addresses) do
      address.AddressType = "HOME"
      patient.Addresses[1].IsPreferred = TRUE
      address.TimeZone = timeZone
   end
   
   for i, contact in pairs(patient.Contacts) do
      contact.ContactMethodType = "HOME" -- how to map this to our ListItem values?
      contact.TimeZone = timeZone
   end
   
   for i, identifier in pairs(patient.Identifiers) do
      identifier.IdentifierName = "Account Number"
      identifier.AssigningAuthority = "Centricity"
      identifier = "MRN"
   end
end

function customMappings.USMM.mapADTA28(hl7Message, patient)
   if hl7Message.PV1[8][1][1]:nodeValue() == "ETOC" then
      local tag = combinedPatient.tag()

      tag.Name = "Patient.CustomTags.ETOC"
      tag.Value = "TRUE"
      tag.Type = "Bool"
      table.insert(patient.Tags, tag)
   end
   customMappings.USMM.mapAll(hl7Message, patient)
   
   return
end

function customMappings.USMM.mapADTA31(hl7Message, patient)
   customMappings.USMM.mapADTA28(hl7Message, patient)
   
   return
end

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