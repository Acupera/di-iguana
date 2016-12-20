local combinedPatient = require "acupera.combinedPatient"
local mappers = {
   keys = {
      {
         sendingApplication = "ACUPERA",
         sendingFacilities = { "ACUPERA" }
      }
   }
}

function mappers.mapADTA28(hl7Message, patient)
   return
end

function mappers.mapADTA31(hl7Message, patient)
   return
end

return mappers