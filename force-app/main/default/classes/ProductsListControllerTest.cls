@isTest
public class ProductsListControllerTest {
    @testSetup static void setup() {
        // Create Plant
        Plant__c testPlant = utility_TestDataFactory.setupPlant();
        insert testPlant;

        // Create common test accounts
        List<Account> testAccts = new List<Account>();
        for(Integer i = 0; i < 2; i++) {
            Account accTemp = utility_TestDataFactory.setupAccount(testPlant);
            accTemp.Name = 'TestAcct' + i;
            accTemp.GroupPricingLevel__c = 'Bronze';
            testAccts.add(accTemp);
        }
        insert testAccts;

        // Insert Contacts
        List<Account> testAcctsQuery = [
            SELECT Id, Name 
            FROM Account 
            WHERE Name = 'TestAcct0' OR Name = 'TestAcct1'
            ];

        List<Contact> testCons = new List<Contact>();
        for(Account acct:testAcctsQuery) {
            testCons.add(utility_TestDataFactory.setupContact(acct));
        }
        insert testCons;

        // Insert Products
        List<Product2> testProducts = new List<Product2>();
        for(Integer i = 0; i < 1; i++) {
            Product2 testProductTemp = utility_TestDataFactory.setupProduct();
            testProductTemp.Name = 'TestProduct' + i;
            testProductTemp.SAP_Id__c = testProductTemp.SAP_Id__c + i;
            testProducts.add(testProductTemp);
        }
        insert testProducts;

        // Insert Price Books
        Pricebook2 testPB_STD = utility_TestDataFactory.setupPB();
        insert testPB_STD;
        Pricebook2 testPB_Bronze = utility_TestDataFactory.setupPB();
        testPB_Bronze.Name = 'Bronze';
        insert testPB_Bronze;

        List<Pricebook2> testPBs = [SELECT Id, Name FROM Pricebook2];

        System.debug('testPBs: ' + testPBs);

        // Insert Product Price Book Entries
        List<PricebookEntry> testPBEs = new List<PricebookEntry>();

        List<Product2> queryTestPrd = [SELECT Id, Name FROM Product2 WHERE Name = 'TestProduct0'];
        List<Pricebook2> queryTestPB = [SELECT Id, Name FROM Pricebook2 WHERE Name = 'Bronze'];

        System.debug('queryTestPB: ' + queryTestPB);

        PricebookEntry testPEBTemp = utility_TestDataFactory.setupPBE(queryTestPrd[0].Id, queryTestPB[0].Id);
        testPBEs.add(testPEBTemp);
        insert testPBEs;

        List<PricebookEntry> queryTestPBEs = [SELECT Id, Name, Pricebook2Id FROM PricebookEntry];

        // Insert Opp
        Opportunity testOppTemp = utility_TestDataFactory.setupOpp(testAcctsQuery[0].Id, testPlant.Id, queryTestPB[0].Id);
        insert testOppTemp;

        // Insert Quote
        String accId = testAcctsQuery[0].Id;
        List<Contact> testConsList = [SELECT Id, Name FROM Contact WHERE AccountId = :accId];
        Quote testQuoteTemp = utility_TestDataFactory.setupQuote(testConsList[0].Id, testOppTemp.Id, queryTestPB[0].Id);
        testQuoteTemp.Name = 'ProductsListControllerTestQuote';
        insert testQuoteTemp;
    }
    // Start testing
    @isTest static void testFindAccountInfo() {
        List<Quote> quoteTest = [SELECT Id, Name FROM Quote WHERE Name = 'ProductsListControllerTestQuote'];
        List<Quote> quoteAccount = ProductsListController.getAccountRecord(quoteTest[0].Id);
    }
    @isTest static void testDefaulLoading() {
        List<Quote> quoteTest = [SELECT Id, Name, Account.Id FROM Quote WHERE Name = 'ProductsListControllerTestQuote'];
        
        String accId = quoteTest[0].AccountId;

        List<Account> queryAcc = [SELECT Id, Name, Price_Book__c, CurrencyIsoCode, GroupPricingLevel__c FROM Account WHERE Id = :accId];

        Integer offSetCount = 20;
        String accountPB = queryAcc[0].Price_Book__c;
        String accountCurrency = 'CAD';
        String searchMethod = 'Loading';
        String queryTerm = '';
        String queryTermMultiSearch = '';

        List<PriceBookEntry> pbeList = ProductsListController.getRecords(offSetCount, accountPB, accountCurrency, searchMethod, queryTerm, queryTermMultiSearch);
    }
    @isTest static void testSearching() {
        List<Quote> quoteTest = [SELECT Id, Name, Account.Id FROM Quote WHERE Name = 'ProductsListControllerTestQuote'];

        String accId = quoteTest[0].AccountId;

        List<Account> queryAcc = [SELECT Id, Name, Price_Book__c, CurrencyIsoCode, GroupPricingLevel__c FROM Account WHERE Id = :accId];

        List<Pricebook2> Pricebook2List = [SELECT Id, Name, IsActive FROM Pricebook2 LIMIT 100];

        List<PriceBookEntry> resultPBE = [SELECT Id, Name, Product2Id, Product2.Name, Product_List_Price__c, UnitPrice, Pricebook2Id , IsActive, Product2.Description, Product2.Family
        FROM PriceBookEntry LIMIT 100];

        List<PriceBookEntry> updatePBE = new List<PriceBookEntry>();

        for(PriceBookEntry peb:resultPBE) {
            peb.IsActive = True;
            updatePBE.add(peb);
        }

        update updatePBE;

        List<PriceBookEntry> updatedPBE = [SELECT Id, Name, Product2Id, Product2.Name, Product_List_Price__c, UnitPrice, Pricebook2Id , IsActive, Product2.Description, Product2.Family
        FROM PriceBookEntry LIMIT 100];

        Integer offSetCount = 20;
        String accountPB = queryAcc[0].Price_Book__c;
        String accountCurrency = 'CAD';
        String searchMethod = 'Searching';
        String queryTerm = 'Test';
        String queryTermMultiSearch = '{"elementSR1":{"elementSRField":"Name","elementSROperator":"Contains","elementSRInput":"Test"}}';

        List<PriceBookEntry> pbeList = ProductsListController.getRecords(offSetCount, accountPB, accountCurrency, searchMethod, queryTerm, queryTermMultiSearch);

    }
    @isTest static void testSaveQuoteItem() {
        List<Quote> quoteTest = [SELECT Id, Name, Account.Id FROM Quote WHERE Name = 'ProductsListControllerTestQuote'];

        String accId = quoteTest[0].AccountId;

        List<Account> queryAcc = [SELECT Id, Name, Price_Book__c, CurrencyIsoCode, GroupPricingLevel__c FROM Account WHERE Id = :accId];

        List<Pricebook2> Pricebook2List = [SELECT Id, Name, IsActive FROM Pricebook2 LIMIT 100];

        List<PriceBookEntry> resultPBE = [SELECT Id, Name, Product2Id, Product2.Name, Product_List_Price__c, UnitPrice, Pricebook2Id , IsActive, Product2.Description, Product2.Family
        FROM PriceBookEntry LIMIT 100];

        List<PriceBookEntry> updatePBE = new List<PriceBookEntry>();

        String PBEIDTarget;

        for(PriceBookEntry peb:resultPBE) {
            if(peb.IsActive == true){
                PBEIDTarget = peb.Id;
                String PB_ID = peb.Pricebook2Id;
                List<Pricebook2> Pricebook2ListSelected = [SELECT Id, Name, IsActive FROM Pricebook2 WHERE Id = :PB_ID];
            }
        }

        update updatePBE;

        List<PriceBookEntry> updatedPBE = [SELECT Id, Name, Product2Id, Product2.Name, Product_List_Price__c, UnitPrice, Pricebook2Id, Pricebook2.Name , IsActive, Product2.Description, Product2.Family
        FROM PriceBookEntry LIMIT 100];

        if(updatedPBE.size() > 0) {
            String updatedPBEId = PBEIDTarget;
            String updatedProduct2Id = updatedPBE[0].Product2Id;
            String quoteTestId = quoteTest[0].Id;
            String PBEId = updatedPBEId;
            String linkName = '/Test linkName';
            String Product2Name = 'Test Product2Name';
            String QuoteId = quoteTestId;
            String Product2Id = updatedProduct2Id;
            String IsActive = 'true';
            String UnitPrice = '100';
            String Discount = '0';
            String Quantity = '1';
            String Comment = 'Test Comment';
            String quoteLines = '[{ "PBEId": "' + PBEId + '", "linkName": "' + linkName + '", "Product2Name": "' + Product2Name + '", "QuoteId": "' + QuoteId + '", "Product2Id": "' + Product2Id + '", "IsActive": ' + IsActive + ', "UnitPrice": ' + UnitPrice + ', "Discount": ' + Discount + ', "Quantity": "' + Quantity + '", "Comment": "' + Comment + '"}]';

            String result = ProductsListController.createQuoteLines(quoteLines);

        }
    }
}
