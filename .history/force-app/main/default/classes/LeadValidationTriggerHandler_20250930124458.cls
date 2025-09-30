/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-30-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class LeadValidationTriggerHandler {

    // ==========================
    // Public Methods
    // ==========================

  
      /**
     *  Validate Lead emails they should contain @telus.com and should be unique
     * @param leadList List of Lead records
     */
    public static void validateLeadEmail(List<Lead> leadList) {
        for (Lead l : leadList) {
            if (l.Email == null || !l.Email.contains('@telus.com')) {
                throw new ValidationException('INVALID_EMAIL', 'Lead email is invalid: ' + l.Email);
            }
        }
    }

    /**
     * Bulk apply scoring rules to leads
     * @param leadList List of Lead records
     */
    public static void applyBusinessRule(List<Lead> leadList) {
        List<Id> leadsForEmail = new List<Id>();

        for (Lead l : leadList) {
            Integer score = 0;

            // Industry-based scoring
            if (l.Industry != null && l.Industry.contains('Technology')) {
                score += 5;
            }

            // Company size
            if (l.NumberOfEmployees != null && l.NumberOfEmployees > 500) {
                score += 10;
            }

            // Enterprise email domain
            if (l.Email != null && l.Email.endsWith('telus.com')) {
                score += 10;
            }

            l.Score__c = score;

            if (score > 30) {
                leadsForEmail.add(l.Id);
            }
        }

        // Send emails outside the loop (bulk-safe)
        if (!leadsForEmail.isEmpty()) {
            try {
                EmailService.sendValidationEmail(leadsForEmail);
            } catch (Exception ex) {
                System.debug('EmailService callout failed: ' + ex.getMessage());
            }
        }
    }

    // ==========================
    // Custom Exception
    // ==========================
    public class ValidationException extends Exception {
        public String errorCode;
        public ValidationException(String code, String message) {
            //super(message);
            this.errorCode = code;
        }
    }

    //Write a method to get an account id as parameter and then utilize the docs/Domain knowledge.md to validate email as per the documetation
    public static void validateLeadsFromAccount(Id accountId) {
        List<Lead> leads = [SELECT Id, Email FROM Lead WHERE AccountId = :accountId];
        validateLeadEmail(leads);
    }

    //write validateLeadEmail as per the docs/domainknowledge.md requirements are given in the doc.
    public static void validateLeadEmail(List<Lead> leadList) {
        for (Lead l : leadList) {
            if (l.Email == null || !l.Email.contains('@') || !l.Email.contains('.')) {
                throw new ValidationException('INVALID_EMAIL', 'Lead email is invalid: ' + l.Email);
            }
        }
    }

}