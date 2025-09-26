/**
 * InventoryTriggerController
 * ---------------------------
 * This class contains trigger-related logic for Inventory__c records.
 *
 * Current Functionality:
 * - Restricts multiple Inventory__c records from being created for the same Product__c.
 * - If an attempt is made to insert/update more than one Inventory__c record per Product,
 *   an error will be thrown on the Inventory record.
 */
public class InventoryTriggerController {

    /**
     * Validates that each Product__c can only have one related Inventory__c record.
     *
     * @param inventoryMap A map of Inventory__c records (from trigger.newMap or trigger.new).
     *
     * Behavior:
     *  - Collects all Product__c Ids from the given Inventory records.
     *  - Queries related Product2 records and their child Inventories__r.
     *  - Builds a map of ProductId -> list of Inventory__c records.
     *  - If any Product has more than one related Inventory, adds an error to the record.
     */
    public static void multipleInventoryRestriction(Map<Id, Inventory__c> inventoryMap) {
        // Collect all Product Ids from the given Inventory records
        List<Id> productIds = new List<Id>();
        for (Inventory__c ivt : inventoryMap.values()) {
            if (ivt.Product__c != null) {
                productIds.add(ivt.Product__c);
            }
        }

        if (productIds.isEmpty()) {
            return; // Nothing to validate
        }

        // Query Products and their related Inventories
        List<Product2> prodList = [
            SELECT Id, (SELECT Id FROM Inventories__r)
            FROM Product2
            WHERE Id IN :productIds
        ];

        // Build map: ProductId -> related Inventories
        Map<Id, List<Inventory__c>> proInvMap = new Map<Id, List<Inventory__c>>();
        for (Product2 prd : prodList) {
            if (prd.Inventories__r != null && !prd.Inventories__r.isEmpty()) {
                proInvMap.put(prd.Id, prd.Inventories__r);
            }
        }

        // Validate each Inventory record
        for (Inventory__c ivt : inventoryMap.values()) {
            if (ivt.Product__c != null && proInvMap.containsKey(ivt.Product__c)) {
                // If more than one Inventory exists for the Product, block the operation
                if (proInvMap.get(ivt.Product__c).size() > 1) {
                    ivt.addError(
                        'You cannot add more than one Inventory for a product. ' +
                        'Please use the "Add Quantity" button instead.'
                    );
                }
            }
        }
    }
}