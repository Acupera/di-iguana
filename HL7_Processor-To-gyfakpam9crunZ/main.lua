local azureStorageGateway = require "acupera.azureStorageGateway"

function main(Data)
   azureStorageGateway.queue.send(Data)
end