/**
 * Class Name: ClasstoBulkTest
 * 
 * Description:
 * ---------------
 * This utility class is used to generate bulk test data for Orders and OrderItems.
 * It:
 *   1. Fetches a product from the org.
 *   2. Creates a test Account.
 *   3. Fetches the Standard Pricebook.
 *   4. Creates two Orders for the Account.
 *   5. Creates and inserts related OrderItems linked to each Order.
 *
 * Use Case:
 * ---------------
 * - Can be called from a Test Class to prepare consistent test data for bulk scenarios.
 * - Helps in validating triggers, workflows, or business logic on Orders and OrderItems.
 *
 * Note:
 * ---------------
 * - Ensure that the Product with `ProductCode = '00IP14'` exists in your org before running this.
 * - Modify the ProductCode as needed if it doesn’t exist.
 */
public class ClasstoBulkTest {

    /**
     * Method Name: testData
     * 
     * Description:
     * ---------------
     * Creates:
     *   - One Account
     *   - Two Orders under that Account
     *   - Two OrderItems (one for each order)
     * 
     * Steps:
     *   1. Query a sample product (with ProductCode '00IP14').
     *   2. Create and insert an Account.
     *   3. Fetch the Standard Pricebook.
     *   4. Fetch a PricebookEntry for the product from the Standard Pricebook.
     *   5. Create two Orders linked to the Account.
     *   6. Insert both Orders in a single DML.
     *   7. Create and insert two OrderItems linked to the Orders.
     */
    public static void testData() {
        
        // Step 1: Query a product (Assumes a product with ProductCode '00IP14' exists)
        Product2 prod = [
            SELECT Id 
            FROM Product2 
            WHERE ProductCode = '00IP14'
            LIMIT 1
        ];

        // Step 2: Create a test Account
        Account ac = new Account();
        ac.Name = 'Test Account';
        insert ac;

        // Step 3: Fetch Standard Pricebook
        Pricebook2 stdPriceBook = [
            SELECT Id, Name 
            FROM Pricebook2 
            WHERE IsStandard = true 
            LIMIT 1
        ];

        // Step 4: Fetch PricebookEntry for the product in Standard Pricebook
        PricebookEntry stdPriceBookEntry = [
            SELECT Id, Product2Id, Product2.Name 
            FROM PricebookEntry 
            WHERE Pricebook2Id = :stdPriceBook.Id 
            LIMIT 1
        ];

        // Step 5: Create two Orders under the Account
        List<Order> orderList = new List<Order>();
        
        Order ord1 = new Order();
        ord1.AccountId = ac.Id;
        ord1.Status = 'Draft';
        ord1.Pricebook2Id = stdPriceBook.Id;
        ord1.EffectiveDate = System.today();
        orderList.add(ord1);

        Order ord2 = new Order();
        ord2.AccountId = ac.Id;
        ord2.Status = 'Draft';
        ord2.Pricebook2Id = stdPriceBook.Id;
        ord2.EffectiveDate = System.today();
        orderList.add(ord2);

        // Step 6: Insert both Orders at once
        insert orderList;

        // Step 7: Create two OrderItems (one for each order)
        List<OrderItem> orderItemList = new List<OrderItem>();

        OrderItem oItem1 = new OrderItem();
        oItem1.Status__c = 'Activated';
        oItem1.Quantity = 1;
        oItem1.PricebookEntryId = stdPriceBookEntry.Id;
        oItem1.Product2Id = prod.Id;
        oItem1.UnitPrice = 233;
        oItem1.OrderId = orderList[0].Id;
        orderItemList.add(oItem1);

        OrderItem oItem2 = new OrderItem();
        oItem2.Status__c = 'Activated';
        oItem2.Quantity = 2;
        oItem2.PricebookEntryId = stdPriceBookEntry.Id;
        oItem2.Product2Id = prod.Id;
        oItem2.UnitPrice = 233;
        oItem2.OrderId = orderList[1].Id;
        orderItemList.add(oItem2);

        // Step 8: Insert all OrderItems at once
        insert orderItemList;
    }
}