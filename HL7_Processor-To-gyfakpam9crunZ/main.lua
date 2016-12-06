local azureStorageGateway = require "acupera.azureStorageGateway"

function main(Data)
   azureStorageGateway.queue.send(json.parse{data=Data})
end