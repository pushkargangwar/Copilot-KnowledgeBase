public with sharing class EmailService {

    /**
     * Bulk send validation emails for multiple leads
     * @param leadIds List of Lead Ids
     */
    public static void sendValidationEmail(List<Id> leadIds) {
        if (leadIds == null || leadIds.isEmpty()) return;

        // Query lead details in bulk
        List<Lead> leads = [SELECT Id, FirstName, LastName, Email FROM Lead WHERE Id IN :leadIds];

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        Map<Id, String> leadEmailMap = new Map<Id, String>();

        for (Lead leadRecord : leads) {
            if (!String.isBlank(leadRecord.Email)) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{ leadRecord.Email });
                mail.setSubject('Lead Validation Notification');
                mail.setPlainTextBody('Hello ' + (leadRecord.FirstName != null ? leadRecord.FirstName : '') +
                                      ',\n\nYour lead record has been validated successfully.\n\nThanks,\nSalesforce Team');
                emailsToSend.add(mail);
                leadEmailMap.put(leadRecord.Id, leadRecord.Email);
            }
        }

        if (!emailsToSend.isEmpty()) {
            try {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend);
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        String email = emailsToSend[i].getToAddresses()[0];
                        System.debug('Failed to send email to ' + email + ': ' + results[i].getErrors()[0].getMessage());
                    }
                }
            } catch (Exception ex) {
                System.debug('Exception sending bulk emails: ' + ex.getMessage());
            }
        }
    }
}