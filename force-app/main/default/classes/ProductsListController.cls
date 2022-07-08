public class ProductsListController {

    @AuraEnabled
    public static List<Quote> getAccountRecord(Id quoteId) {
        return [SELECT Id, Name, Account.Id, Account.Price_Book__c, Account.CurrencyIsoCode FROM Quote WHERE Id =: quoteId];
    }

    @AuraEnabled
    public static List<PriceBookEntry> getRecords(Integer offSetCount, String accountPB, String accountCurrency, String searchMethod, String queryTerm) {
        List<PriceBookEntry> resultPBE = new List<PriceBookEntry>();
        if(searchMethod == 'Loading') {
            resultPBE = [SELECT Id, Name, Product2Id, Product2.Name, Product_List_Price__c, UnitPrice, ProductCode, Product_SAP_Id__c, IsActive
                    FROM PriceBookEntry 
                    WHERE CurrencyIsoCode =: accountCurrency AND PriceBookName__c =: accountPB
                    LIMIT 20 OFFSET :offSetCount];
        }
        if(searchMethod == 'Searching') {
            resultPBE = [SELECT Id, Name, Product2Id, Product2.Name, Product_List_Price__c, UnitPrice, ProductCode, Product_SAP_Id__c, IsActive
                    FROM PriceBookEntry 
                    WHERE CurrencyIsoCode =: accountCurrency AND PriceBookName__c =: accountPB
                    LIMIT 20 OFFSET :offSetCount];
        }
        return resultPBE;
    }

    @AuraEnabled
    public static String createQuoteLines(String quoteLines) {

        List<QuoteLineItem> QLIList = new List<QuoteLineItem>();

        List<quoteLine> quoteLineList = (List<quoteLine>) JSON.deserialize(quoteLines, List<quoteLine>.class);

        for(quoteLine qli : quoteLineList) {
            QuoteLineItem QLI_Temp = new QuoteLineItem();
            QLI_Temp.QuoteId = qli.QuoteId;
            QLI_Temp.Product2Id = qli.Product2Id;
            QLI_Temp.PricebookEntryId = qli.PBEId;
            QLI_Temp.UnitPrice = qli.UnitPrice;
            QLI_Temp.Discount = qli.Discount;
            QLI_Temp.Quantity = qli.Quantity;
            QLI_Temp.Comment__c = qli.Comment;
            QLIList.add(QLI_Temp);
        }

        if(QLIList.size() > 0) {
            try {
                insert QLIList;
                return 'Inserted all QLIList';
            } catch(DMLException e) {
                throw new DMLException('Unable to Perform the DML Operation on QLIList : ' + e.getMessage());
            }
        } else {
            return 'QLIList is empty';
        }

    }

    private class quoteLine{
        Id PBEId {get; set;}
        String linkName {get; set;}
        String Product2Name {get; set;}
        Id QuoteId {get; set;}
        Id Product2Id {get; set;}
        Boolean IsActive {get; set;}
        Double UnitPrice {get; set;}
        Double Discount {get; set;}
        Integer Quantity {get; set;}
        String Comment {get; set;}
    }

}
