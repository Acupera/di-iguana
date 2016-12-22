local function run(main, Data)
   local statusCode, errorMessage = pcall(main, Data)

   if not statusCode then
      iguana.logError("This message failed and will not be processed. Error Message: "..errorMessage, iguana.messageId())
   end
end

return {
   run = run
}