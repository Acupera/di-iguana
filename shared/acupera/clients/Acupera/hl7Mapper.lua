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

help.set{input_function = mappers.mapADTA28, help_data = {
      Title = "acupera.clients.Acupera.mappers.mapADTA28",
      Usage = "customMapper.mapADTA28(hl7Message, patient)",
      Desc = "Performs custom mapping of an HL7 message to a CombinedPatient. "..
      "Also executes custom Acupera test logic to faciliate more complex integration test scenarios."..
      "To enlist in this behavior, override the HL7 message's SendingFacility field to one of the supported testCommands i.e. FORCEERROR."..
      "Furthermore, extended behavior can be achieved by the use of defining custom Z segments in the acupera.vmd to store parameter to pass to test commands.",
      Parameters = {
         { hl7Message = { Desc = "HL7 message table being mapped from." }},
         { patient = { Desc = "CombinedPatient being mapped to." }}
      },
      Returns = Nil,
      Examples = { "customMapper[getMapperName(hl7Message)](hl7Message, patient)" }
}}

return mappers