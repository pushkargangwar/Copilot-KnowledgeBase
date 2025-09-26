public with sharing class LeadValidationTriggerHandler {

    // ==========================
    // Public Methods
    // ==========================

    /**
     * Bulk validate Lead emails
     * @param leadList List of Lead records
     */
    public static void validateLeadEmail(List<Lead> leadList) {
        Set<String> emailSet = new Set<String>();
        for (Lead l : leadList) {
            if (l.Email != null) emailSet.add(l.Email);
        }

        Map<String, Lead> existingLeadsMap = new Map<String, Lead>();
        if (!emailSet.isEmpty()) {
            for (Lead dbLead : [SELECT Id, Email FROM Lead WHERE Email IN :emailSet]) {
                existingLeadsMap.put(dbLead.Email, dbLead);
            }
        }

        for (Lead l : leadList) {
            if (l.Email == null || !Pattern.matches('^[\\w._%+-]+@[\\w.-]+\\.[a-zA-Z]{2,6}$', l.Email)) {
                l.addError('Email format is invalid.');
            } else if (existingLeadsMap.containsKey(l.Email)) {
                l.addError('This email is already in use.');
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
}