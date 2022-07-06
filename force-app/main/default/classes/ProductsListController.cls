public class ProductsListController {
    @AuraEnabled
    public static List<Quote> getAccountRecord(Id quoteId) {
        return [SELECT Id, Name, Account.Id, Account.Price_Book__c, Account.CurrencyIsoCode FROM Quote WHERE Id =: quoteId];
    }
    @AuraEnabled
    public static List<PriceBookEntry> getRecords(Integer offSetCount, String accountPB, String accountCurrency) {
        return [SELECT Id, Name, Product2Id, Product_List_Price__c, UnitPrice, ProductCode, Product_SAP_Id__c
                FROM PriceBookEntry 
                WHERE CurrencyIsoCode =: accountCurrency AND PriceBookName__c =: accountPB
                LIMIT 20 OFFSET :offSetCount];
    }
}
