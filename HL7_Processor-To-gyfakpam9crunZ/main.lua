require 'log.annotate'
local azureStorageGateway = require "acupera.azureStorageGateway"

function main(Data)
   iguana.stopOnError(false)
   azureStorageGateway.queue.put(Data)
end