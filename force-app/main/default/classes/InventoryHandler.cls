/**
 * InventoryHandler
 * ----------------
 * This class provides methods to manage and update Inventory records.
 * Currently, it supports updating the total quantity of a given Inventory record.
 */
public class InventoryHandler {

    /**
     * Updates the total quantity of an Inventory record by adding the specified amount.
     *
     * @param recordId The Salesforce Id of the Inventory__c record to update.
     * @param qty      The quantity to add to the existing Total_Quantity__c field.
     * @return         True if the update succeeds, false otherwise.
     *
     * Usage:
     *  - Call this method from Lightning components (Aura/LWC) to adjust inventory levels.
     */
    @AuraEnabled
    public static Boolean saveQuantity(String recordId, Integer qty) {
        System.debug('recordId: ' + recordId);
        System.debug('qty: ' + qty);

        // Validate input parameters
        if (String.isNotBlank(recordId) && qty != null && qty != 0) {
            try {
                // Fetch the Inventory record
                Inventory__c invty = [
                    SELECT Id, Total_Quantity__c 
                    FROM Inventory__c 
                    WHERE Id = :recordId
                    LIMIT 1
                ];

                // If record exists, update quantity
                if (invty != null) {
                    invty.Total_Quantity__c = invty.Total_Quantity__c + qty;
                    update invty;
                    return true;
                }
            } catch (Exception ex) {
                // Log any exception for debugging purposes
                System.debug('Error while updating inventory: ' + ex.getMessage());
            }
        }

        // Return false if input invalid or update failed
        return false;
    }
}