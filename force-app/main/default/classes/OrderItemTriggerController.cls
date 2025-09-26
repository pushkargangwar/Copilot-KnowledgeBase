/**
 * OrderItemTriggerController
 * ---------------------------
 * This class contains trigger logic related to OrderItem records.
 * It ensures inventory quantities are updated correctly based on
 * order actions (insert, update, delete, status change).
 *
 * Responsibilities:
 *  - Deduct inventory when order items are created or activated.
 *  - Prevent manual changes to order item quantity.
 *  - Restore inventory when order items are cancelled, returned, or deleted.
 */
public class OrderItemTriggerController {

    /**
     * Deducts inventory when new OrderItems are inserted.
     *
     * @param newOrderItemMap Map of newly inserted OrderItem records.
     *
     * Behavior:
     *  - Queries the OrderItems (ordered by CreatedDate).
     *  - Checks available inventory for each Product2Id.
     *  - Deducts the ordered quantity from inventory if available.
     *  - If not enough stock exists, blocks the operation with an error.
     */
    public static void checkInventory(Map<Id, OrderItem> newOrderItemMap) {
        // Fetch related OrderItems from DB to ensure accurate values
        List<OrderItem> orderItems = [
            SELECT Id, OrderId, Quantity, Product2Id
            FROM OrderItem
            WHERE Id IN :newOrderItemMap.keySet()
            ORDER BY CreatedDate ASC
        ];

        // Build Product -> Inventory map
        Map<Id, Inventory__c> prodInventoryMap = getProductIdInventoryMap(orderItems);

        List<Inventory__c> invtListToBeUpdated = new List<Inventory__c>();

        for (OrderItem oItem : orderItems) {
            Inventory__c invt = prodInventoryMap.get(oItem.Product2Id);

            if (invt != null && invt.Total_Quantity__c >= oItem.Quantity) {
                // Deduct inventory
                invt.Total_Quantity__c -= oItem.Quantity;
                invtListToBeUpdated.add(invt);
            } else {
                // Block order if not enough stock
                newOrderItemMap.get(oItem.Id)
                    .addError('No inventory available or item out of stock.');
            }
        }

        if (!invtListToBeUpdated.isEmpty()) {
            update invtListToBeUpdated;
        }
    }

    /**
     * Prevents manual quantity updates for existing OrderItems.
     *
     * @param newOItemMap Map of new OrderItem records (trigger.newMap).
     * @param oldOItemMap Map of old OrderItem records (trigger.oldMap).
     */
    public static void noQuantityUpdateAllowed(Map<Id, OrderItem> newOItemMap, Map<Id, OrderItem> oldOItemMap) {
        for (OrderItem oitem : newOItemMap.values()) {
            if (oitem.Quantity != oldOItemMap.get(oitem.Id).Quantity) {
                oitem.Quantity.addError('You cannot update the quantity of an ordered item manually.');
            }
        }
    }

    /**
     * Handles inventory updates when an OrderItem status changes.
     *
     * @param orderItemsNew Map of new OrderItem records (trigger.newMap).
     * @param orderItemsOld Map of old OrderItem records (trigger.oldMap).
     *
     * Behavior:
     *  - If status changes from Activated → Cancelled/Returned, restore inventory.
     *  - If status changes to Activated, deduct inventory.
     */
    public static void handleCancelledItem(Map<Id, OrderItem> orderItemsNew, Map<Id, OrderItem> orderItemsOld) {
        Map<Id, Inventory__c> prodInventoryMap = getProductIdInventoryMap(orderItemsNew.values());
        List<Inventory__c> toBeUpdated = new List<Inventory__c>();

        for (OrderItem oItem : orderItemsNew.values()) {
            Inventory__c invty = prodInventoryMap.get(oItem.Product2Id);

            // Cancelled/Returned → restore inventory
            if (oItem.Status__c != orderItemsOld.get(oItem.Id).Status__c
                && orderItemsOld.get(oItem.Id).Status__c == 'Activated'
                && (oItem.Status__c == 'Cancelled' || oItem.Status__c == 'Returned')) {

                invty.Total_Quantity__c += oItem.Quantity;
                toBeUpdated.add(invty);
            }

            // Newly Activated → deduct inventory
            if (oItem.Status__c != orderItemsOld.get(oItem.Id).Status__c
                && oItem.Status__c == 'Activated') {

                invty.Total_Quantity__c -= oItem.Quantity;
                toBeUpdated.add(invty);
            }

            System.debug('Updating inventory for status change: ' + oItem.Status__c);
        }

        if (!toBeUpdated.isEmpty()) {
            update toBeUpdated;
        }
    }

    /**
     * Restores inventory when OrderItems are deleted.
     *
     * @param orderItemsOld Map of old OrderItem records (trigger.oldMap).
     */
    public static void handleDeletedItem(Map<Id, OrderItem> orderItemsOld) {
        Map<Id, Inventory__c> prodInventoryMap = getProductIdInventoryMap(orderItemsOld.values());
        List<Inventory__c> toBeUpdated = new List<Inventory__c>();

        for (OrderItem oItem : orderItemsOld.values()) {
            Inventory__c invty = prodInventoryMap.get(oItem.Product2Id);
            invty.Total_Quantity__c += oItem.Quantity; // Restore stock
            toBeUpdated.add(invty);
        }

        if (!toBeUpdated.isEmpty()) {
            update toBeUpdated;
        }
    }

    /**
     * Utility method: Builds a ProductId → Inventory__c map.
     *
     * @param orderItems List of OrderItem records.
     * @return Map of Product2Id → Inventory__c.
     */
    public static Map<Id, Inventory__c> getProductIdInventoryMap(List<OrderItem> orderItems) {
        // Collect Product Ids
        List<Id> productIdList = new List<Id>();
        for (OrderItem oItem : orderItems) {
            if (oItem.Product2Id != null) {
                productIdList.add(oItem.Product2Id);
            }
        }

        if (productIdList.isEmpty()) {
            return new Map<Id, Inventory__c>();
        }

        // Query inventories for those products
        List<Inventory__c> inventoryList = [
            SELECT Id, Product__c, Total_Quantity__c
            FROM Inventory__c
            WHERE Product__c IN :productIdList
        ];

        // Build map ProductId → Inventory
        Map<Id, Inventory__c> prodInventoryMap = new Map<Id, Inventory__c>();
        for (Inventory__c inv : inventoryList) {
            if (!prodInventoryMap.containsKey(inv.Product__c)) {
                prodInventoryMap.put(inv.Product__c, inv);
            }
        }

        return prodInventoryMap;
    }
}