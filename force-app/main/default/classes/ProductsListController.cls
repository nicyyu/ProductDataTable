public class ProductsListController {
    @AuraEnabled
    public static List<Account> getRecords(Integer offSetCount) {
        return [SELECT Id, Name, AccountNumber, Phone, CreatedDate FROM Account LIMIT 2 OFFSET :offSetCount];
    }
}
