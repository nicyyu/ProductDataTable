public class ProductsListController {

    @AuraEnabled
    public static List<Quote> getAccountRecord(Id quoteId) {
        return [SELECT Id, Name, Account.Id, Account.Price_Book__c, Account.CurrencyIsoCode FROM Quote WHERE Id =: quoteId];
    }

    @AuraEnabled
    public static List<PriceBookEntry> getRecords(Integer offSetCount, String accountPB, String accountCurrency, String searchMethod, String queryTerm, String queryTermMultiSearch) {
        List<PriceBookEntry> resultPBE = new List<PriceBookEntry>();
        //Default loading Price Book Entries
        if(searchMethod == 'Loading') {
            resultPBE = [SELECT Id, Name, Product2Id, Product2.Name, Product_List_Price__c, UnitPrice, ProductCode, Product_SAP_Id__c, IsActive, Product2.Description
                    FROM PriceBookEntry 
                    WHERE CurrencyIsoCode =: accountCurrency AND PriceBookName__c =: accountPB AND IsActive = true
                    LIMIT 20 OFFSET :offSetCount];
        }
        //Single text searching
        if(searchMethod == 'Searching') {
            List<Product2> productSearch = ((List<Product2>)[FIND :queryTerm IN ALL FIELDS RETURNING Product2(Id WHERE IsActive = true LIMIT 20 OFFSET :offSetCount)][0]);
            System.debug('productSearch: ' + productSearch);
            resultPBE = [
                SELECT Id, Name, Product2Id, Product2.Name, Product_List_Price__c, UnitPrice, ProductCode, Product_SAP_Id__c, IsActive, Product2.Description
                FROM PriceBookEntry 
                WHERE CurrencyIsoCode = :accountCurrency AND PriceBookName__c = :accountPB AND IsActive = true AND Product2Id IN :productSearch];
        }
        //Multi-fields Searching
        if(searchMethod == 'SearchingMultiRows') {
            String returnStr = SearchingMultiRowsParse(queryTermMultiSearch);
            String SOQLStr = 'SELECT Id, Name, Product2Id, Product2.Name, Product_List_Price__c, UnitPrice, ProductCode, Product_SAP_Id__c, IsActive, Product2.Description FROM PriceBookEntry WHERE CurrencyIsoCode = :accountCurrency' + ' AND ' + 'PriceBookName__c = :accountPB' + ' AND IsActive = true';
            SOQLStr = SOQLStr + returnStr + 'LIMIT 20 OFFSET :offSetCount';
            resultPBE = Database.query(SOQLStr);
        }
        return resultPBE;
    }

    public static String SearchingMultiRowsParse(String queryTermMultiSearch) {
        String query = '';
        Map<String, rowSearchData> searchTermList = (Map<String, rowSearchData>) JSON.deserialize(queryTermMultiSearch, Map<String, rowSearchData>.class);
        //System.debug('searchTermList Size: ' + searchTermList.size());
        //System.debug('searchTermList Values: ' + searchTermList.values());
        for(rowSearchData SRD : searchTermList.values()){
            String operator;
            String keyWords;
            if(SRD.elementSROperator == 'equal'){
                operator = ' = ';
                keyWords = '\'' + SRD.elementSRInput + '\'';
            }
            if(SRD.elementSROperator == 'contain'){
                operator = ' LIKE ';
                keyWords = '\'%' + SRD.elementSRInput + '%\'';
            }
            if(query == ''){
                query = ' AND ' + SRD.elementSRField + operator + keyWords;
            }
            if(query != ''){
                query = query + ' AND ' + SRD.elementSRField + operator + keyWords;
            }
        }
        return query;
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
                return 'Successfully Inserted QLI';
            } catch(DMLException e) {
                throw new DMLException('Unable to Perform the DML Operation on QLIList : ' + e.getMessage());
            }
        } else {
            return 'Nothing Inserted';
        }

    }
    //Wrapper class for multi-field searching
    private class rowSearchData{
        String elementSRField {get; set;}
        String elementSROperator {get; set;}
        String elementSRInput {get; set;}
    }
    //Wrapper class for creating quote line items
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
