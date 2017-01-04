require 'log.annotate'
local azureStorageGateway = require "acupera.azureStorageGateway"
local translator = require "acupera.translator"

local function RunTranslator(patient)
   azureStorageGateway.queue.put(azureStorageGateway.azureConstants.queues.combinedPatient, patient, patient.Metadata.SourceId)
end

function main(Data)
   local patient = json.parse{data=Data}
   
   translator.run(function() RunTranslator(patient) end, patient.Metadata.SourceId)
end