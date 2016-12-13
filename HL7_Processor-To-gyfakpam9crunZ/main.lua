require 'log.annotate'
local azureStorageGateway = require "acupera.azureStorageGateway"

function main(Data)
   azureStorageGateway.queue.put(Data)
end