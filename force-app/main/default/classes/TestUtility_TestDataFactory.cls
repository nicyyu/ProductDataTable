@isTest(SeeAllData = true)
private class TestUtility_TestDataFactory {
    @isTest static void test_method_one() {
        Plant__c testPlant = utility_TestDataFactory.setupPlant();
        insert testPlant;
        
        String accName = 'Test Account - ' + String.valueOf(System.now());
        List<Account> accounts = new List<Account>();
        Account a1 = utility_TestDataFactory.setupAccount(testPlant);
        a1.Name = accName;
        accounts.add(a1);
        insert accounts;
        
        List<Contact> contacts = new List<Contact>();
        Contact c1 = utility_TestDataFactory.setupContact(a1);
        c1.AccountId = a1.Id;
        c1.Active__c = true;
        c1.Email = 'testContact1@abc.com';
        contacts.add(c1);
        insert contacts;
        
      /*  MC4SF__MC_Campaign__c mc1 = utility_TestDataFactory.setupMCCampaign();
        insert mc1;
        
        MC4SF__MC_Campaign_Hourly_Stats__c mchs1 = utility_TestDataFactory.setupMCHourlyStats(mc1);
        insert mchs1;*/
        
        Product2 p2 = utility_TestDataFactory.setupProduct();
        insert p2;
        
        SVMXC__Installed_Product__c installedProduct = utility_TestDataFactory.setupInstalledProduct(a1, c1, p2);
        insert installedProduct;
        
        List<SVMXC__Installed_Product__c> installedProduct_Result = [SELECT Id, Name FROM SVMXC__Installed_Product__c WHERE Id = :installedProduct.Id];
        System.assert(installedProduct_Result.size() > 0);
        
        SVMXC__Warranty__c productWarranty = utility_TestDataFactory.setupProductWarranty(installedProduct);
        insert productWarranty;
    }
}