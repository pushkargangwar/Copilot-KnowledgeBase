/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-30-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class LeadConverstionController {
    public static void convertLead(List<Lead> leadList) {
        lead leadObj = new Lead();
        leadObj.Name = 'Test Lead';
        leadObj.Company = 'Test Company';
        leadObj.Status = 'Open - Not Contacted';
        leadObj.Email  = 'test';
        insert leadObj;
        validateLeadEmail(leadList);
        
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(leadObj.Id);
        lc.setConvertedStatus('Qualified');
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.Assert.areEqual(true, lcr.isSuccess());
    }

    //Write a method to validate Lead
    public static void validateLeadEmail(List<Lead> leadList) {
        for (Lead l : leadList) {
            if (l.Email == null || !l.Email.contains('@telus.com')) {
                throw new ValidationException('INVALID_EMAIL', 'Lead email is invalid: ' + l.Email);
            }
        }   
             LeadValidationTriggerHandler.applyBusinessRule(leadList);
    }

}