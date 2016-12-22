require 'log.annotate'
local azureStorageGateway = require "acupera.azureStorageGateway"
local translator = require "acupera.translator"

local function RunTranslator(Data)
   azureStorageGateway.queue.put(azureStorageGateway.azureConstants.queues.combinedPatient, json.parse{data=Data})
end

function main(Data)
   translator.run(RunTranslator, Data)
end