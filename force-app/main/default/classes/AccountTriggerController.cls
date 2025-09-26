/**
 * AccountTriggerController
 * -------------------------
 * This class contains logic to handle custom operations related to Account triggers.
 * 
 * Current Functionality:
 * - On Account insert, splits the Account's Amount__c field equally among its related Contacts
 *   by updating the Amount_Split__c field on each Contact.
 */
public with sharing class AccountTriggerController {

    /**
     * Splits the Amount__c field of Accounts equally among their related Contacts.
     * 
     * @param triggerAccounts A map of Account Ids to Account records (from trigger.newMap or trigger.new).
     *
     * Behavior:
     *  - Runs only on Account insert.
     *  - Fetches all Contacts related to the inserted Accounts.
     *  - Divides Account.Amount__c equally among the related Contacts.
     *  - Updates the Amount_Split__c field on each Contact.
     */
    public static void setSplitAmount(Map<Id, Account> triggerAccounts) {
        // Ensure this logic runs only during Account insert trigger events
        if (Trigger.isInsert) {
            // Fetch all Contacts related to the inserted Accounts
            List<Contact> allConList = new List<Contact>();
            if (Schema.sObjectType.Contact.isAccessible()) {
                allConList = [
                    SELECT Id, Amount_Split__c, AccountId
                    FROM Contact
                    WHERE AccountId IN :triggerAccounts.keySet()
                ];
            } else {
                // Optionally, handle lack of access (e.g., throw exception or log)
                return;
            }

            // Build a map: AccountId -> List of related Contacts
            Map<Id, List<Contact>> acContactMap = new Map<Id, List<Contact>>();
            for (Contact con : allConList) {
                if (!acContactMap.containsKey(con.AccountId)) {
                    acContactMap.put(con.AccountId, new List<Contact>());
                }
                acContactMap.get(con.AccountId).add(con);
            }

            // Prepare list of Contacts to update
            List<Contact> conListToUpdate = new List<Contact>();

            for (Contact con : allConList) {
                // Get total number of contacts under the Account
                Integer totalContactsOnAccount = acContactMap.get(con.AccountId).size();

                // Divide the Account.Amount__c equally among its Contacts
                con.Amount_Split__c = 
                    triggerAccounts.get(con.AccountId).Amount__c / totalContactsOnAccount;

                conListToUpdate.add(con);
            }

            // Perform DML update (partial success allowed) only if user has update access
            if (Schema.sObjectType.Contact.isUpdateable()) {
                Database.update(conListToUpdate, false);
            } 
        }
    }
}