require 'log.annotate'

local retry = require "retry"

local azureConstants = {
   azureDateFormat = "%a, %d %b %Y %H:%M:%S GMT",
   azureAPIVersion = "2015-12-11",
   headers = {
      date = "x-ms-date",
      version = "x-ms-version"
   },
   queues = {
      combinedPatient = "dataintegration-combinedpatient"
   },
   retryDefaults = {
      times = 5,
      pause = 10
   }
}

local function getCanonicalizedResource()
   if os.getenv("azureStorageAccount.url"):match("127.0.0.1") ~= nil or os.getenv("azureStorageAccount.url"):match("localhost") ~= nil then
      return "/"..os.getenv("azureStorageAccount.name").."/"..os.getenv("azureStorageAccount.name").."/"..azureConstants.queues.combinedPatient.."/messages"
   end
   
   return "/"..os.getenv("azureStorageAccount.name").."/"..azureConstants.queues.combinedPatient.."/messages"
end

local function getSignature(httpVerb, time, message)
   local key = filter.base64.dec(os.getenv("azureStorageAccount.primaryAccessKey"))
   local canonicalizedHeaders = azureConstants.headers.date..":".. time ..
      "\n"..azureConstants.headers.version..":"..azureConstants.azureAPIVersion.."\n"
   local signature = httpVerb .. "\n" ..
      "\n" ..  --Content-Encoding
      "\n" ..  --Content-Language
      string.len(message).."\n" ..  --Content-Length
      "\n" ..  --Content-MD5
      "application/x-www-form-urlencoded\n" ..  --Content-Type
      "\n" ..  --Date
      "\n" ..  --If-Modified-Since
      "\n" ..  --If-Match
      "\n" ..  --If-None-Match
      "\n" ..  --If-Unmodified-Since
      "\n" ..  --Range
      canonicalizedHeaders ..   
      getCanonicalizedResource()
   
   return filter.base64.enc(crypto.hmac{data=signature, key=key, algorithm=crypto.algorithms()[11]})
end

local function retryRestErrorHandler(success, errMsgOrReturnCode, response)
   if not success then error(errMsgOrReturnCode) end
   
   local isSuccessful = true
   
   if response.code == 500 or response.code == 503 then
      iguana.logWarning("Retrying for response code: "..response.code)
	   isSuccessful = false
   elseif not response.successCodes[response.code] then
      iguana.logError("Azure REST API respone code:"..response.code..", data: "..response.data..".")
   end
   
   return isSuccessful
end

local function put(combinedPatient)
   if type(combinedPatient) == table then combinedPatient = json.parse{data=combinedPatient} end
   
   local time = os.ts.gmdate(azureConstants.azureDateFormat)
   local payload = '{ "iguanaMessageId":"'..iguana.messageId()..'", "combinedPatient:'..combinedPatient..'}'
   local message = '<QueueMessage><MessageText>'..filter.base64.enc(((payload):gsub('\r', ''):compactWS()))..'</MessageText></QueueMessage>'
   
   local restCall = function()
      local result, httpStatus, headers = net.http.post{
         method="POST",
         url=os.getenv("azureStorageAccount.url")..azureConstants.queues.combinedPatient.."/messages",
         headers={
            Authorization = "SharedKey "..os.getenv("azureStorageAccount.name")..":".. getSignature("POST", time, message),
            [azureConstants.headers.date] = time,
            [azureConstants.headers.version] = azureConstants.azureAPIVersion
         },
         body=message
         ,debug=true
         ,live=true
      }
      
      return true, { data = result, code = httpStatus, headers = headers, successCodes = { [201]=true } }
   end
   
   return retry.call{func=restCall, retry=azureConstants.retryDefaults.times, pause=azureConstants.retryDefaults.pause, errorfunc=retryRestErrorHandler}
end

return {
   queue = {
      put = put
   }
}