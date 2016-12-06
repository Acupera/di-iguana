local function patient()
   local patient = {
      PatientSearch = {
         PatientIdentifiers = {},
         FirstName = '',
         LastName = '',
         MiddleName = '',
         DateOfBirth = '',
         Gender = '',
         Client = '',
         HealthPlan = '',
         SubscriberId = '',
         SocialSecurityNumber = '',
      },
	   PatientRecord = {
         FirstName = '',
         LastName = '',
         MiddleName = '',
         DateOfBirth = '',
         Gender = '',
         SSN = '',
         Race = '',
         Ethnicity = '',
         MaritalStatus = '',
         Facility = ''
      },
      Addresses = {},
      Contacts = {},
      Languages = {},
      Tags = {}
   }
   
   return patient
end

local function address()
   return {
      AddressLine1 = '',
      City = '',
      State = '',
      Postal = '',
      LastVerifiedDate = ''
   }
end

local function contact()
	return {
      Value = '',
      ContactMethodType = '',
      LastVerifiedDate = ''
   }
end

local function identifier()
   return {
      AssigningAuthority = '',
      IdentifierValue = '',
      IdentifierType = '',
      IdentifierName = ''
   }
end

local function language()
   return {
      Language = ''
   }
end

local function tag()
   return {
      Name = '',
      Value = '',
      Type = ''
   }
end

return {
   address = address,
   patient = patient,
   contact = contact,
   identifier = identifier,
   language = language,
   tag = tag
}