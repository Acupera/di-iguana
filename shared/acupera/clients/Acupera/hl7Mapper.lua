local combinedPatient = require "acupera.combinedPatient"

-- For more advanced custom testing behavior, we can add custom Z segments to the acupera.vmd in order to supply arguments to the testCommands
local testCommands = {
   ForceError = "FORCEERROR"
}
local mappers = {
   keys = {
      {
         sendingApplication = "ACUPERA",
         sendingFacilities = { "ACUPERA", testCommands.ForceError }
      }
   }
}

function mappers.mapADTA28(hl7Message, patient)
   if (hl7Message.MSH[4][1]:nodeValue() == testCommands.ForceError) then error("command FORCEERROR ran") end
   
   return
end

function mappers.mapADTA31(hl7Message, patient)
   return mappers.mapADTA28(hl7Message, patient)
end

return mappers