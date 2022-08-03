public class ProductsListController {

    //Query Account info
    @AuraEnabled
    public static List<Quote> getAccountRecord(Id quoteId) {
        return [SELECT Id, Name, Account.Id, Account.Price_Book__c, Account.CurrencyIsoCode FROM Quote WHERE Id =: quoteId];
    }

    //Query PriceBook Entry
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
        //Text searching
        if(searchMethod == 'Searching') {

            System.debug('queryTerm: ' + queryTerm);

            System.debug('queryTermMultiSearch: ' + queryTermMultiSearch);

            Set<Id> prdIdSet = new Set<Id>();

            String returnStr = SearchingMultiRowsParse(queryTermMultiSearch);

            if(!String.isBlank(queryTerm)){
                String queryProduct = 'FIND \'' + queryTerm + '\'IN ALL FIELDS RETURNING Product2(Id WHERE IsActive = true ' + returnStr + 'LIMIT 20 OFFSET :offSetCount)';

                List<List<SObject>> productSearch = search.query(queryProduct);
    
                for(Sobject prd : productSearch[0]){
                    prdIdSet.add(prd.Id);
                }
                
                resultPBE = [
                    SELECT Id, Name, Product2Id, Product2.Name, Product_List_Price__c, UnitPrice, ProductCode, Product_SAP_Id__c, IsActive, Product2.Description
                    FROM PriceBookEntry 
                    WHERE CurrencyIsoCode = :accountCurrency AND PriceBookName__c = :accountPB AND IsActive = true AND Product2Id IN :prdIdSet];
            }

            if(String.isBlank(queryTerm)){
                String SOQLStr = 'SELECT Id, Name, Product2Id, Product2.Name, Product_List_Price__c, UnitPrice, ProductCode, Product_SAP_Id__c, IsActive, Product2.Description FROM PriceBookEntry WHERE CurrencyIsoCode = :accountCurrency' + ' AND ' + 'PriceBookName__c = :accountPB' + ' AND IsActive = true';
                SOQLStr = SOQLStr + returnStr + 'LIMIT 20 OFFSET :offSetCount';
                resultPBE = Database.query(SOQLStr);
            }

        }
        return resultPBE;
    }

    //Create string for SOQL
    public static String SearchingMultiRowsParse(String queryTermMultiSearch) {
        String query = '';
        Map<String, rowSearchData> searchTermList = (Map<String, rowSearchData>) JSON.deserialize(queryTermMultiSearch, Map<String, rowSearchData>.class);
        //System.debug('searchTermList Size: ' + searchTermList.size());
        System.debug('searchTermList Values: ' + searchTermList.values());
        for(rowSearchData SRD : searchTermList.values()){
            String queryTemp = '';
            String field = SRD.elementSRField;
            String operator;
            String keyWords;
            if(field == 'Product2.IsActive' || field == 'Product2.Serialized__c' ||
            field == 'Product2.Rental_Item__c' || field == 'Product2.Cost__c' ||
            field == 'Product2.Cost_USD__c' || field == 'Product2.List_Price__c' ||
            field == 'Product2.List_Price_USD__c' || field == 'Product2.List_Price_CAD_Active__c' ||
            field == 'Product2.List_Price_USD_Active__c' || field == 'Product2.Pricing_Condition__c' )
            {
                keyWords = '' + SRD.elementSRInput + '';
            } else {
                keyWords = '\'' + SRD.elementSRInput + '\'';
            }
            if(SRD.elementSROperator == 'Equals'){
                operator = ' = ';
            }
            if(SRD.elementSROperator == 'Contains'){
                operator = ' LIKE ';
                keyWords = '\'%' + SRD.elementSRInput + '%\'';
            }
            if(SRD.elementSROperator == 'NotEquals'){
                operator = ' != ';
            }
            if(SRD.elementSROperator == 'StartsWith'){
                operator = ' LIKE ';
                keyWords = '\'%' + SRD.elementSRInput + '\'';
            }
            if(SRD.elementSROperator == 'DoesNotContain'){
                field = 'NOT ' + field;
                operator = ' LIKE ';
                keyWords = '\'%' + SRD.elementSRInput + '%\'';
            }
            if(SRD.elementSROperator == 'LessThan'){
                operator = ' < ';
            }
            if(SRD.elementSROperator == 'GreaterThan'){
                operator = ' > ';
            }
            if(SRD.elementSROperator == 'LessOrEqual'){
                operator = ' <= ';
            }
            if(SRD.elementSROperator == 'GreaterOrEqual'){
                operator = ' >= ';
            }
            if(SRD.elementSROperator == 'Includes'){
                operator = ' INCLUDES ';
                keyWords = '\'' + SRD.elementSRInput + '\'';
            }
            if(SRD.elementSROperator == 'Excludes'){
                operator = ' EXCLUDES ';
                keyWords = '\'' + SRD.elementSRInput + '\'';
            }
            if(SRD.elementSROperator == 'Within'){
                operator = ' IN ';
                keyWords = '\'' + SRD.elementSRInput + '\'';
            }
            queryTemp = ' AND ' + '(' + field + operator + keyWords + ')';
            query += queryTemp;
        }
        System.debug('query: ' + query);
        return query;
    }

    //Create Quote Line Items
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
