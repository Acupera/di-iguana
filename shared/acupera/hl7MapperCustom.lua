local combinedPatient = require "acupera.combinedPatient"

local customMappings = {
   USMM = {
      keys = {
         {
            sendingApplication = "GPMS",
            sendingFacilities = { "VPA" }
         }
      }
   }
}

function customMappings.USMM.lookupRelationshipDescription(relationshipCode)
	local codeToDescriptionMappings = {
	   ["1"] = "Self",
      ["2"] = "Spouse",
      ["3"] = "Child",
      ["4"] = "Dependent Child",
      ["5"] = "Step Child",
      ["6"] = "Foster Child",
      ["7"] = "Word of the Court",
      ["8"] = "Employee",
      ["9"] = "Unknown",
      ["10"] = "Handicapped Dependent",
      ["11"] = "Organ Donor",
      ["12"] = "Cadaver Donor",
      ["13"] = "Grandchild",
      ["14"] = "Niece/Nephew",
      ["15"] = "Injured Plaintiff",
      ["16"] = "Sponsored Dependent",
      ["17"] = "Minor Dependent of a Minor Dependent",
      ["18"] = "Parent",
      ["19"] = "Grandparent",
      ["20"] = "Adopted Child",
      ["29"] = "Significant Other",
      ["32"] = "Mother",
      ["33"] = "Father",
      ["34"] = "Other Adult",
      ["36"] = "Emancipated Minor",
      ["53"] = "Life Partner"
   }
   
   if codeToDescriptionMappings[relationshipCode] ~= nil then
      return codeToDescriptionMappings[relationshipCode]
   else
      return codeToDescriptionMappings["9"]
   end
end

function customMappings.USMM.lookupRace(raceCode)
	local codeToDescriptionMappings = {
      ["0"] = "Unknown",
	   ["1"] = "Black or African",
      ["2"] = "Asian",
      ["3"] = "White",
      ["4"] = "Asian",
      ["5"] = "Native Hawaiian or Other Pacific Islander",
      ["6"] = "Hispanic",
      ["7"] = "Asian",
      ["8"] = "American Indian or Alaskan Native",
      ["9"] = "Native Hawaiian or Other Pacific Islander",
      ["10"] = "Native Hawaiian or Other Pacific Islander",
      ["11"] = "Other"
   }
   
   if codeToDescriptionMappings[raceCode] ~= nil then
      return codeToDescriptionMappings[raceCode]
   else
      return codeToDescriptionMappings["0"]
   end
end

function customMappings.USMM.lookupGender(genderCode)
	local codeToDescriptionMappings = {
      ["M"] = "Male",
	   ["F"] = "Female",
      ["U"] = "Unknown"
   }
   
   if codeToDescriptionMappings[genderCode] ~= nil then
      return codeToDescriptionMappings[genderCode]
   else
      return codeToDescriptionMappings["U"]
   end
end

function customMappings.USMM.lookupMaritalStatus(maritalStatusCode)
	local codeToDescriptionMappings = {
      ["M"] = "Married",
	   ["S"] = "Single",
      ["D"] = "Divorced",
      ["W"] = "Widowed",
      ["U"] = "Unknown"
   }
   
   if codeToDescriptionMappings[maritalStatusCode] ~= nil then
      return codeToDescriptionMappings[maritalStatusCode]
   else
      return codeToDescriptionMappings["U"]
   end
end

function customMappings.USMM.lookupEthnicity(ethnicityCode)
	local codeToDescriptionMappings = {
      ["H"] = "Hispanic/Latino",
	   ["N"] = "Not Hispanic or Latino",
      ["U"] = "Decline to answer"
   }
   
   if codeToDescriptionMappings[ethnicityCode] ~= nil then
      return codeToDescriptionMappings[ethnicityCode]
   else
      return codeToDescriptionMappings["U"]
   end
end

function customMappings.USMM.lookupClient(targetHealthPlan)
   local clientToHealthPlanMappings = {
      ["MANAGED MEDICARE"] = { "BUCKEYE MCR ADVANTAGE", "SUPERIOR HEALTH PLAN(MCR)", "MANAGED HEALTH WI MCR" },
      ["MEDICARE"] = { "SENIORSHIELD MEDICARE BEN", "AZ MEDICARE NORIDIAN", "HPSA - 9299364  CINN", "HPSA - 9299367 CLEVELAND", "HPSA - 9299362 - COLUMBUS", "COLORADO MEDICARE", "HPSA - 9299363 - DAYTON", "FLORIDA MEDICARE", "FLORIDA MEDICARE", "FLORIDA MEDICARE", "GA MEDICARE", "HPSA MEDICARE", "IA MEDICARE WPS", "IL MEDICARE", "IL MEDICARE", "IL MEDICARE", "IL MEDICARE", "INDIANA MEDICARE", "KANSAS MEDICARE", "KENTUCKY MEDICARE", "HPSA MI LOCAL 99", "MI MEDICARE", "MI MEDICARE", "MO MEDICARE", "MO MEDICARE", "MO MEDICARE", "MEDICARE NV NORIDIAN JE", "OH MEDICARE CGS", "PENNSYLVANIA MEDICARE", "PENNSYLVANIA MEDICARE", "RR MEDICARE", "RR MEDICARE", "TEXAS MEDICARE (REST)", "TEXAS MEDICARE (AUSTIN)", "TEXAS MEDICARE (BEAUMONT)", "TEXAS MEDICARE(BRAZORIA)", "TEXAS MEDICARE", "TEXAS MEDICARE (FT.WORTH)", "TEXAS MEDICARE (GALVESTN)", "TEXAS MEDICARE (HOUSTON)", "TEXAS MEDICARE (SAN ANT)", "VIRGINIA MEDICARE PART B", "WASHINGTON MEDICARE 99", "WASHINGTON MEDICARE", "WI MEDICARE" },
      ["BLUE SHIELD"] = { "BLUE CARE NETWORK" },
      ["BLUE SHIELD - COMMERCIAL"] = { "BLUE CARE NETWORK" }
   }
   
   for i, client in pairs(clientToHealthPlanMappings) do
	   for j, healthPlan in pairs(client) do
         if healthPlan == targetHealthPlan then
            return i
         end
      end
   end
   
   return nil
end

function customMappings.USMM.mapAll(hl7Message, patient)
   local timeZone = "Eastern Standard Time"
   local gender = customMappings.USMM.lookupGender(hl7Message.PID[8]:nodeValue())
   local assigningAuthority = "Centricity"
   local identifierType = "MRN"
   
   patient.PatientSearch.Gender = gender
   
   for i, identifier in pairs(patient.PatientSearch.PatientIdentifiers) do
      identifier.IdentifierType = identifierType
      identifier.AssigningAuthority = assigningAuthority
   end
   
   for i, coverage in pairs(patient.PatientSearch.PatientCoverages) do
      coverage.LineOfBusiness = "NONE"
      coverage.TimeZone = timeZone
      coverage.Client = customMappings.USMM.lookupClient(coverage.HealthPlan)
   end
   
   patient.PatientRecord.Race = customMappings.USMM.lookupRace(hl7Message.PID[10][1][1]:nodeValue())
   patient.PatientRecord.TimeZone = timeZone
   patient.PatientRecord.Gender = gender
   patient.PatientRecord.MaritalStatus = customMappings.USMM.lookupMaritalStatus(hl7Message.PID[16][1]:nodeValue())
   patient.PatientRecord.Ethnicity = customMappings.USMM.lookupEthnicity(hl7Message.PID[22][1][1]:nodeValue())
   
   for i, address in pairs(patient.Addresses) do
      address.AddressType = "HOME"
      patient.Addresses[1].IsPreferred = "TRUE"
      address.TimeZone = timeZone
   end
   
   for i, contact in pairs(patient.Contacts) do
      contact.ContactMethodType = "HOME"
      contact.Value = hl7Message.PID[13][1][1]:nodeValue()
      contact.TimeZone = timeZone
   end
   
   for i, coverage in pairs(patient.Coverages) do
      coverage.RelationshipToSubscriber = customMappings.USMM.lookupRelationshipDescription(hl7Message.INSURANCE[1].IN1[17][1]:nodeValue())
      
      if hl7Message.INSURANCE[1].IN1[22]:nodeValue() == "1" then
         coverage.IsPrimary = "TRUE"
      else
         coverage.IsPrimary = "FALSE"
      end
   end
   
   for i, identifier in pairs(patient.Identifiers) do
      identifier.IdentifierName = "Account Number"
      identifier.AssigningAuthority = assigningAuthority
      identifier.IdentifierType = identifierType
   end
end

function customMappings.USMM.mapADTA28(hl7Message, patient)
   if hl7Message.PV1[8][1][1]:nodeValue() == "ETOC" then
      local tag = combinedPatient.tag()

      tag.Name = "Patient.CustomTags.ETOC"
      tag.Value = "TRUE"
      tag.Type = "Bool"
      table.insert(patient.Tags, tag)
   end
   customMappings.USMM.mapAll(hl7Message, patient)
   
   return
end

function customMappings.USMM.mapADTA31(hl7Message, patient)
   customMappings.USMM.mapADTA28(hl7Message, patient)
   
   return
end

local function getCustomMapper(hl7Message)
   local messageCode = hl7Message.MSH[9][1]:nodeValue()
   local messageEvent = hl7Message.MSH[9][2]:nodeValue()
   local sendingApplication = hl7Message.MSH[3][1]:nodeValue()
   local sendingFacility = hl7Message.MSH[4][1]:nodeValue()
   
   for clientName, clientMapping in pairs(customMappings) do
      for i, keyMapping in pairs(clientMapping.keys) do
         if keyMapping.sendingApplication ~= sendingApplication then break end
         
         for j, facility in pairs(keyMapping.sendingFacilities) do
            if facility == sendingFacility then
               return customMappings[clientName]["map"..messageCode..messageEvent]
            end
         end
      end
   end
   
   return nil
end

local function map(hl7Message, patient)
   local customMapper = getCustomMapper(hl7Message)
   
   if customMapper ~= nil then customMapper(hl7Message, patient) end
end

return {
   map = map
}