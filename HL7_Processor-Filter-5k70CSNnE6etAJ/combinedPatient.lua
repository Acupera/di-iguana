local combinedPatient = {}

function combinedPatient.combinedPatient()
   local combinedPatient = {
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
   
   return combinedPatient
end

function combinedPatient.address()
   return {
      AddressLine1 = '',
      City = '',
      State = '',
      Postal = '',
      LastVerifiedDate = ''
   }
end

function combinedPatient.contact()
	return {
      Value = '',
      ContactMethodType = '',
      LastVerifiedDate = ''
   }
end

function combinedPatient.identifier()
   return {
      AssigningAuthority = '',
      IdentifierValue = '',
      IdentifierType = '',
      IdentifierName = ''
   }
end

function combinedPatient.language()
   return {
      Language = ''
   }
end

function combinedPatient.tag()
   return {
      Name = '',
      Value = '',
      Type = ''
   }
end

return combinedPatient