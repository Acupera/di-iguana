local combinedPatient = require "acupera.combinedPatient"

local customMappings = {
	
}

function customMappings.MapA28_USMM(hl7Message, patient)
	local tag = combinedPatient.tag()
   
   tag.Name = "Patient.CustomTags.ETOC"
   tag.Value = "TRUE"
   tag.Type = "Bool"
   patient.Tags[1] = tag
   
   return
end

return customMappings