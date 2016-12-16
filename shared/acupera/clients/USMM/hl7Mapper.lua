local combinedPatient = require "acupera.combinedPatient"
local mappers = {
   keys = {
      {
         sendingApplication = "GPMS",
         sendingFacilities = { "VPA", "IHP", "PHA" }
      }
   }
}

function lookupRelationshipDescription(relationshipCode)
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

function lookupRace(raceCode)
	local codeToDescriptionMappings = {
      ["0"] = "Unknown",
	   ["1"] = "Black",
      ["2"] = "Asian",
      ["3"] = "White",
      ["4"] = "Asian",
      ["5"] = "NativeHawaiian",
      ["6"] = "Hispanic",
      ["7"] = "Asian",
      ["8"] = "AmericanIndian",
      ["9"] = "NativeHawaiian",
      ["10"] = "NativeHawaiian",
      ["11"] = "Other"
   }
   
   if codeToDescriptionMappings[raceCode] ~= nil then
      return codeToDescriptionMappings[raceCode]
   else
      return codeToDescriptionMappings["0"]
   end
end

function lookupGender(genderCode)
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

function lookupMaritalStatus(maritalStatusCode)
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

function lookupEthnicity(ethnicityCode)
	local codeToDescriptionMappings = {
      ["H"] = "HispanicLatino",
	   ["N"] = "NotHispanicLatino",
      ["U"] = "Declined"
   }
   
   if codeToDescriptionMappings[ethnicityCode] ~= nil then
      return codeToDescriptionMappings[ethnicityCode]
   else
      return codeToDescriptionMappings["U"]
   end
end

function lookupClient(targetHealthPlan)
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

function mappers.mapAll(hl7Message, patient)
   local timeZone = "Eastern Standard Time"
   local gender = lookupGender(hl7Message.PID[8]:nodeValue())
   local assigningAuthority = "Centricity"
   local identifierType = "MRN"
   local identifierName = "Account Number"
   
   patient.PatientSearch.GenderString = gender
   
   for i, identifier in pairs(patient.PatientSearch.PatientIdentifiers) do
      identifier.IdentifierType = identifierType
      identifier.AssigningAuthority = assigningAuthority
      identifier.IdentifierName = identifierName
   end
   
   for i, coverage in pairs(patient.PatientSearch.PatientCoverages) do
      coverage.LineOfBusiness = "NONE"
      coverage.TimeZone = timeZone
      coverage.Client = lookupClient(hl7Message.INSURANCE[1].IN1[4][1][1]:nodeValue())
   end
   
   patient.PatientRecord.Race = lookupRace(hl7Message.PID[10][1][1]:nodeValue())
   patient.PatientRecord.TimeZone = timeZone
   patient.PatientRecord.GenderString = gender
   patient.PatientRecord.MaritalStatus = lookupMaritalStatus(hl7Message.PID[16][1]:nodeValue())
   patient.PatientRecord.Ethnicity = lookupEthnicity(hl7Message.PID[22][1][1]:nodeValue())
   
   for i, address in pairs(patient.Addresses) do
      address.TimeZone = timeZone
      
      if i == 1 then address.IsPreferred = "TRUE" end
   end
   
   for i, contact in pairs(patient.Contacts) do
      contact.ContactMethodType = "HOME"
      contact.TimeZone = timeZone
   end
   
   for i, coverage in pairs(patient.Coverages) do
      coverage.RelationshipToSubscriber = lookupRelationshipDescription(hl7Message.INSURANCE[1].IN1[17][1]:nodeValue())
      coverage.TimeZone = timeZone
      
      if hl7Message.INSURANCE[1].IN1[22]:nodeValue() == "1" then
         coverage.IsPrimary = "TRUE"
      else
         coverage.IsPrimary = "FALSE"
      end
   end
   
   for i, identifier in pairs(patient.Identifiers) do
      identifier.IdentifierName = identifierName
      identifier.AssigningAuthority = assigningAuthority
      identifier.IdentifierType = identifierType
      identifier.TimeZone = timeZone
   end
end

function mappers.mapADTA28(hl7Message, patient)
   if hl7Message.PV1[8][1][1]:nodeValue() == "ETOC" then
      local tag = combinedPatient.tag()

      tag.Name = "Patient.CustomTags.ETOC"
      tag.Value = "TRUE"
      tag.Type = "Bool"
      table.insert(patient.Tags, tag)
   end
   mappers.mapAll(hl7Message, patient)
   
   return
end

function mappers.mapADTA31(hl7Message, patient)
   mappers.mapADTA28(hl7Message, patient)
   
   return
end

return mappers